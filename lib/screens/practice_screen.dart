import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pronunciation_engine/pronunciation_engine.dart';

import '../app/theme.dart';
import '../services/alignment_service.dart';
import '../services/progress_service.dart';
import '../services/sentence_storage_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import 'widgets/comparison_text.dart';
import 'widgets/mic_button.dart';

/// 듣기 + 발음 연습 화면.
///
/// 상단의 문장/청크/단어 세그먼트로 연습 단위를 고르고, 듣기(TTS)로 원어민
/// 발음을 들은 뒤 마이크로 따라 말하면 단어 단위 채점 결과를 보여준다.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final SpeechService _speechService = SpeechService();

  List<PracticeSentence> _sentences = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  PracticeLevel _level = PracticeLevel.sentence;
  int _chunkIndex = 0;
  int _wordIndex = 0;

  bool _isListening = false;
  String _recognizedText = '';
  bool _showTranslation = true;

  // 결과
  bool _hasResult = false;
  double _score = 0.0;
  List<AlignmentWord> _alignedWords = [];
  String _feedback = '';
  String _statusMessage = '';

  // 데모(시뮬레이션) 모드
  bool _useDemoMode = false;
  double _simAccuracy = 0.8;

  String _t(String key) => TranslationService.get(key);

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSentences();
    _loadTtsSettings();
  }

  Future<void> _loadTtsSettings() async {
    await TtsService.loadSettings();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize();
    if (!mounted) return;
    setState(() => _useDemoMode = _speechService.useDemoMode);
  }

  Future<void> _loadSentences() async {
    final loaded = await SentenceStorageService.loadSentences();
    if (!mounted) return;
    setState(() {
      _sentences = loaded;
      if (_currentIndex >= _sentences.length) {
        _currentIndex = _sentences.isEmpty ? 0 : _sentences.length - 1;
      }
      _isLoading = false;
      _resetSession();
    });
  }

  PracticeSentence? get _current =>
      _sentences.isEmpty ? null : _sentences[_currentIndex];

  /// 현재 연습 단위에 해당하는 목표 텍스트.
  String get _target {
    final s = _current;
    if (s == null) return '';
    switch (_level) {
      case PracticeLevel.sentence:
        return s.text;
      case PracticeLevel.chunk:
        if (s.chunks.isNotEmpty && _chunkIndex < s.chunks.length) {
          return s.chunks[_chunkIndex];
        }
        return s.text;
      case PracticeLevel.word:
        final words = s.words;
        if (words.isNotEmpty && _wordIndex < words.length) {
          return words[_wordIndex];
        }
        return s.text;
    }
  }

  /// 결과 표시에 사용할 청크 그룹.
  List<String> get _comparisonChunks {
    final s = _current;
    if (s == null) return const [];
    switch (_level) {
      case PracticeLevel.sentence:
        return s.chunks.isNotEmpty ? s.chunks : [s.text];
      case PracticeLevel.chunk:
      case PracticeLevel.word:
        return [_target];
    }
  }

  void _resetSession() {
    _recognizedText = '';
    _score = 0.0;
    _alignedWords = [];
    _feedback = '';
    _hasResult = false;
    _isListening = false;
    _statusMessage =
        _useDemoMode ? _t('instruction_demo') : _t('instruction_default');
  }

  void _changeLevel(PracticeLevel level) {
    setState(() {
      _level = level;
      _chunkIndex = 0;
      _wordIndex = 0;
      _resetSession();
    });
  }

  void _onPrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _chunkIndex = 0;
        _wordIndex = 0;
        _resetSession();
      });
    }
  }

  void _onNext() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _chunkIndex = 0;
        _wordIndex = 0;
        _resetSession();
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _statusMessage = _t('instruction_analyzing');
      });
      if (_useDemoMode) {
        _runDemo();
      } else {
        await _speechService.stopListening();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_hasResult) {
            if (_recognizedText.isNotEmpty) {
              _processResult(_recognizedText);
            } else {
              setState(() => _statusMessage = _t('instruction_no_speech'));
            }
          }
        });
      }
      return;
    }

    _resetSession();
    setState(() {
      _isListening = true;
      _statusMessage = _t('instruction_listening');
    });

    if (_useDemoMode) return; // 데모는 정지 시 시뮬레이션

    await _speechService.startListening(
      onResult: (text, isFinal) {
        setState(() {
          _recognizedText = text;
          if (isFinal) _processResult(text);
        });
      },
      onStatus: (status) {
        if ((status == 'notListening' || status == 'done') && _isListening) {
          setState(() {
            _isListening = false;
            _statusMessage = _t('instruction_analyzing');
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_hasResult) {
              if (_recognizedText.isNotEmpty) {
                _processResult(_recognizedText);
              } else {
                setState(() => _statusMessage = _t('instruction_no_speech'));
              }
            }
          });
        }
      },
    );
  }

  void _runDemo() {
    _speechService.simulateSpeechInput(
      targetSentence: _target,
      accuracy: _simAccuracy,
      onResult: (text, isFinal) {
        setState(() {
          _recognizedText = text;
          _processResult(text);
        });
      },
    );
  }

  void _processResult(String recognized) {
    final target = _target;
    final aligned = AlignmentService.alignSentences(target, recognized);
    final score = AlignmentService.calculateOverallScore(target, recognized);
    final feedback = AlignmentService.generateFeedbackText(aligned);

    setState(() {
      _alignedWords = aligned;
      _score = score;
      _feedback = feedback;
      _hasResult = true;
      _isListening = false;
      _statusMessage = _t('instruction_complete');
    });

    final s = _current;
    if (s != null) {
      ProgressService.recordAttempt(PracticeAttempt(
        sentenceId: s.id,
        level: _level,
        score: score,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgTop,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: _current == null
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLevelSelector(),
                            const SizedBox(height: 16),
                            _buildTargetCard(_current!),
                            const SizedBox(height: 20),
                            if (_hasResult) ...[
                              _buildScore(),
                              const SizedBox(height: 16),
                              _buildAlignment(),
                              const SizedBox(height: 16),
                              _buildFeedback(),
                            ] else
                              _buildInstructions(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                    _buildControlPanel(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _t('no_sentences'),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('admin_guide'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: Text(_t('go_admin')),
                    onPressed: () =>
                        context.push('/admin').then((_) => _loadSentences()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          Text(
            _useDemoMode ? _t('demo_active') : _t('live_mic'),
            style: TextStyle(
              color: _useDemoMode ? Colors.purpleAccent : AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() => TranslationService.isKorean =
                  !TranslationService.isKorean);
              _resetSession();
            },
            icon: const Icon(Icons.translate, color: AppColors.textSecondary),
            tooltip: TranslationService.isKorean ? '한글/ENG' : 'KOR/ENG',
          ),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final level in PracticeLevel.values)
            Expanded(child: _levelTab(level)),
        ],
      ),
    );
  }

  Widget _levelTab(PracticeLevel level) {
    final selected = _level == level;
    final label =
        TranslationService.isKorean ? level.labelKo : level.labelEn;
    return GestureDetector(
      onTap: () => _changeLevel(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard(PracticeSentence s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_t('sentence_label')} ${_currentIndex + 1}/${_sentences.length}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _showTranslation = !_showTranslation),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTranslation
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTranslation
                          ? _t('hide_translation')
                          : _t('show_translation'),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHighlightedText(s),
          if (_showTranslation && _level == PracticeLevel.sentence) ...[
            const SizedBox(height: 10),
            Text(
              s.translation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_level == PracticeLevel.chunk) _buildChunkChips(s),
          if (_level == PracticeLevel.word) _buildWordChips(s),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _listenButton(),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _onPrev : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    color: AppColors.textPrimary,
                    disabledColor: Colors.white10,
                  ),
                  IconButton(
                    onPressed: _currentIndex < _sentences.length - 1
                        ? _onNext
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    color: AppColors.textPrimary,
                    disabledColor: Colors.white10,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(PracticeSentence s) {
    if (_level == PracticeLevel.sentence) {
      return Text(
        s.text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }
    final highlight = _target;
    final full = s.text;
    final idx = full.toLowerCase().indexOf(highlight.toLowerCase());
    if (idx == -1) {
      return Text(
        highlight,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontFamily: 'Outfit',
        ),
        children: [
          TextSpan(
              text: full.substring(0, idx),
              style: const TextStyle(color: Colors.white30)),
          TextSpan(
            text: full.substring(idx, idx + highlight.length),
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accent,
            ),
          ),
          TextSpan(
              text: full.substring(idx + highlight.length),
              style: const TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  Widget _buildChunkChips(PracticeSentence s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('pick_chunk'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < s.chunks.length; i++)
              _chip(s.chunks[i], i == _chunkIndex, () {
                setState(() {
                  _chunkIndex = i;
                  _resetSession();
                });
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildWordChips(PracticeSentence s) {
    final words = s.words;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('pick_word'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < words.length; i++)
              _chip(words[i], i == _wordIndex, () {
                setState(() {
                  _wordIndex = i;
                  _resetSession();
                });
              }),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _listenButton() {
    return GestureDetector(
      onTap: () {
        TtsService.unlockAudioEngine();
        TtsService.speak(_target);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: AppColors.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              _t('listen'),
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.panelDecoration(),
      child: Column(
        children: [
          Icon(Icons.record_voice_over,
              size: 44, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
          if (_useDemoMode) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('sim_accuracy'),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                Text('${(_simAccuracy * 100).toInt()}%',
                    style: TextStyle(
                        color: _simAccuracy > 0.8
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _simAccuracy,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              activeColor: Colors.purpleAccent,
              inactiveColor: Colors.white10,
              onChanged: (v) => setState(() => _simAccuracy = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScore() {
    final color = AppColors.forScore(_score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.panelDecoration(),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: _score / 100.0,
                  backgroundColor: Colors.white10,
                  color: color,
                  strokeWidth: 8,
                ),
              ),
              Text('${_score.toInt()}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('score_title'),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  _score >= 85
                      ? _t('feedback_excellent')
                      : _score >= 60
                          ? _t('feedback_decent')
                          : _t('feedback_poor'),
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t('detail_title'),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ComparisonText(
            alignedWords: _alignedWords,
            chunks: _comparisonChunks,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('tips_title'),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_feedback,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgTop,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _recognizedText.isEmpty
                    ? _t('say_words')
                    : '"$_recognizedText"',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontStyle: FontStyle.italic),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed:
                    _hasResult ? () => setState(() => _resetSession()) : null,
                icon: const Icon(Icons.refresh),
                color: AppColors.textSecondary,
                disabledColor: Colors.white10,
                iconSize: 26,
              ),
              MicButton(
                isListening: _isListening,
                useDemoMode: _useDemoMode,
                onTap: _toggleListening,
              ),
              IconButton(
                onPressed: _showHelp,
                icon: const Icon(Icons.help_outline),
                color: AppColors.textSecondary,
                iconSize: 26,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_t('help_title'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(_t('help_content'),
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('help_gotit')),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    var localDemo = _useDemoMode;
    var selectedVoice = TtsService.azureVoice;
    var localSpeechRate = TtsService.speechRate;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(_t('settings_title'),
              style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RadioListTile<bool>(
                  title: Text(_t('settings_mode_real'),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  value: false,
                  groupValue: localDemo,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setDialog(() => localDemo = v!),
                ),
                RadioListTile<bool>(
                  title: Text(_t('settings_mode_demo'),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  value: true,
                  groupValue: localDemo,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setDialog(() => localDemo = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedVoice,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: _t('settings_voice_label'),
                    labelStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    border: const OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  items: [
                    DropdownMenuItem(
                        value: 'en-US-JennyNeural',
                        child: Text(_t('voice_jenny'))),
                    DropdownMenuItem(
                        value: 'en-US-GuyNeural',
                        child: Text(_t('voice_guy'))),
                    DropdownMenuItem(
                        value: 'en-US-AriaNeural',
                        child: Text(_t('voice_aria'))),
                    DropdownMenuItem(
                        value: 'en-GB-SoniaNeural',
                        child: Text(_t('voice_sonia'))),
                    DropdownMenuItem(
                        value: 'en-GB-RyanNeural',
                        child: Text(_t('voice_ryan'))),
                  ],
                  onChanged: (v) {
                    if (v != null) selectedVoice = v;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  TranslationService.isKorean ? '원어민 음성 속도' : 'TTS Speech Rate',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TranslationService.isKorean ? '속도 배율' : 'Speed Multiplier',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      '${(localSpeechRate / 0.5).toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: localSpeechRate,
                  min: 0.25,
                  max: 0.75,
                  divisions: 10,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.textMuted.withOpacity(0.2),
                  onChanged: (val) {
                    setDialog(() {
                      localSpeechRate = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('settings_cancel'),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                TtsService.speechRate = localSpeechRate;
                TtsService.azureVoice = selectedVoice;
                await TtsService.saveSettings();
                setState(() {
                  _useDemoMode = localDemo;
                  _speechService.useDemoMode = localDemo;
                  _resetSession();
                });
                Navigator.pop(context);
              },
              child: Text(_t('settings_save'),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
