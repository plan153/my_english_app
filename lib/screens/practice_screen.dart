import 'package:flutter/material.dart';
import '../models/practice_sentence.dart';
import '../services/speech_service.dart';
import '../services/alignment_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';
import '../services/sentence_storage_service.dart';
import 'admin_screen.dart';
import 'widgets/mic_button.dart';
import 'widgets/comparison_text.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final SpeechService _speechService = SpeechService();

  List<PracticeSentence> _sentences = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  bool _isListening = false;
  String _statusMessage = 'Tap the microphone and read the sentence aloud';
  String _recognizedText = '';
  
  // Results
  double _score = 0.0;
  List<AlignmentWord> _alignedWords = [];
  String _feedbackText = '';
  bool _hasResult = false;
  bool _showTranslation = true; // Meaning translation toggle state (Default: ON)

  // Simulator controls
  bool _useDemoMode = false;
  double _simulatedAccuracy = 0.8; // default 80% accuracy for mock speech
  String? _focusedWord; // Null if practicing the full sentence
  String? _focusedChunk; // Null if practicing a specific chunk

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadStoredSentences();
  }

  Future<void> _loadStoredSentences() async {
    setState(() => _isLoading = true);
    final loaded = await SentenceStorageService.loadSentences();
    setState(() {
      _sentences = loaded;
      if (_currentIndex >= _sentences.length) {
        _currentIndex = _sentences.isEmpty ? 0 : _sentences.length - 1;
      }
      _isLoading = false;
      _resetSession();
    });
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
    setState(() {
      _useDemoMode = _speechService.useDemoMode;
      if (_useDemoMode) {
        _statusMessage = TranslationService.get('instruction_demo');
      }
    });
  }

  void _onPrevSentence() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _focusedWord = null;
        _focusedChunk = null;
        _resetSession();
      });
    }
  }

  void _onNextSentence() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _focusedWord = null;
        _focusedChunk = null;
        _resetSession();
      });
    }
  }

  void _resetSession() {
    _recognizedText = '';
    _score = 0.0;
    _alignedWords = [];
    _feedbackText = '';
    _hasResult = false;
    _isListening = false;
    
    if (_useDemoMode) {
      _statusMessage = TranslationService.get('instruction_demo');
    } else if (_focusedWord != null) {
      _statusMessage = TranslationService.get('instruction_focus_word')
          .replaceAll('%word', _focusedWord!);
    } else if (_focusedChunk != null) {
      _statusMessage = TranslationService.get('instruction_focus_chunk')
          .replaceAll('%chunk', _focusedChunk!);
    } else {
      _statusMessage = TranslationService.get('instruction_default');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Stop listening
      setState(() {
        _isListening = false;
        _statusMessage = TranslationService.get('instruction_analyzing');
      });
      
      if (_useDemoMode) {
        _processDemoInput();
      } else {
        await _speechService.stopListening();
        // Fallback: If no result was processed within 500ms after manually stopping, process current transcribed text
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_hasResult) {
            if (_recognizedText.isNotEmpty) {
              _processRecognitionResult(_recognizedText);
            } else {
              setState(() {
                _statusMessage = TranslationService.get('instruction_no_speech');
              });
            }
          }
        });
      }
    } else {
      // Start listening
      _resetSession();
      setState(() {
        _isListening = true;
        _statusMessage = TranslationService.get('instruction_listening');
      });

      if (_useDemoMode) {
        // Just keep listening state, simulation is triggered on stop
      } else {
        await _speechService.startListening(
          onResult: (text, isFinal) {
            setState(() {
              _recognizedText = text;
              if (isFinal) {
                _processRecognitionResult(text);
              }
            });
          },
          onStatus: (status) {
            debugPrint('Listening status callback: $status');
            if ((status == 'notListening' || status == 'done') && _isListening) {
              setState(() {
                _isListening = false;
                _statusMessage = TranslationService.get('instruction_analyzing');
              });
              // Fallback: If we haven't processed a result yet but recognition has stopped,
              // run the analysis with whatever words were transcribed.
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && !_hasResult) {
                  if (_recognizedText.isNotEmpty) {
                    _processRecognitionResult(_recognizedText);
                  } else {
                    setState(() {
                      _statusMessage = TranslationService.get('instruction_no_speech');
                    });
                  }
                }
              });
            }
          },
        );
      }
    }
  }

  void _processDemoInput() {
    _speechService.simulateSpeechInput(
      targetSentence: _focusedWord ?? _focusedChunk ?? _sentences[_currentIndex].text,
      accuracy: _simulatedAccuracy,
      onResult: (text, isFinal) {
        setState(() {
          _recognizedText = text;
          _processRecognitionResult(text);
        });
      },
    );
  }

  void _processRecognitionResult(String recognized) {
    final target = _focusedWord ?? _focusedChunk ?? _sentences[_currentIndex].text;
    final aligned = AlignmentService.alignSentences(target, recognized);
    final score = AlignmentService.calculateOverallScore(target, recognized);
    final feedback = AlignmentService.generateFeedbackText(aligned);

    setState(() {
      _alignedWords = aligned;
      _score = score;
      _feedbackText = feedback;
      _hasResult = true;
      _isListening = false;
      _statusMessage = TranslationService.get('instruction_complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (_sentences.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No practice sentences found.',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please go to the Admin Panel to add or upload sentences.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Go to Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminScreen()),
                            );
                            if (changed == true) {
                              _loadStoredSentences();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentSentence = _sentences[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Dark slate gradients
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Sentence Card
                      _buildTargetCard(currentSentence),
                      
                      const SizedBox(height: 24),
                      
                      // Results Display
                      if (_hasResult) ...[
                        _buildScoreDisplay(),
                        const SizedBox(height: 24),
                        _buildAlignmentDisplay(),
                        const SizedBox(height: 20),
                        _buildFeedbackCard(),
                      ] else ...[
                        _buildInstructionsCard(),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom control area
              _buildControlPanel(),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    String selectedVoice = TtsService.azureVoice;
    bool localUseDemo = _useDemoMode;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.cyanAccent),
                  const SizedBox(width: 10),
                  Text(TranslationService.get('settings_title'), style: const TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Speech Engine Mode
                    Text(
                      TranslationService.get('settings_mode'),
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: Text(TranslationService.get('settings_mode_real'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(TranslationService.get('settings_mode_real_sub'), style: const TextStyle(fontSize: 11)),
                            value: false,
                            groupValue: localUseDemo,
                            activeColor: Colors.cyanAccent,
                            onChanged: (val) {
                              setDialogState(() => localUseDemo = val!);
                            },
                          ),
                          RadioListTile<bool>(
                            title: Text(TranslationService.get('settings_mode_demo'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(TranslationService.get('settings_mode_demo_sub'), style: const TextStyle(fontSize: 11)),
                            value: true,
                            groupValue: localUseDemo,
                            activeColor: Colors.cyanAccent,
                            onChanged: (val) {
                              setDialogState(() => localUseDemo = val!);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Azure Neural TTS Voice Actor Config
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationService.get('settings_voice'),
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            TranslationService.get('settings_active'),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedVoice,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: TranslationService.get('settings_voice_label'),
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'en-US-JennyNeural', child: Text('Jenny (Female - Default)')),
                        DropdownMenuItem(value: 'en-US-GuyNeural', child: Text('Guy (Male)')),
                        DropdownMenuItem(value: 'en-US-AriaNeural', child: Text('Aria (Female - Educational)')),
                        DropdownMenuItem(value: 'en-GB-SoniaNeural', child: Text('Sonia (Female - UK)')),
                        DropdownMenuItem(value: 'en-GB-RyanNeural', child: Text('Ryan (Male - UK)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          selectedVoice = val;
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(TranslationService.get('settings_cancel'), style: const TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                  onPressed: () {
                    setState(() {
                      _useDemoMode = localUseDemo;
                      _speechService.useDemoMode = localUseDemo;
                      TtsService.azureVoice = selectedVoice;
                      _resetSession();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(TranslationService.get('settings_save'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PronouncePro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _useDemoMode 
                    ? TranslationService.get('demo_active') 
                    : TranslationService.get('live_mic'),
                style: TextStyle(
                  color: _useDemoMode ? Colors.purpleAccent : const Color(0xFF00E5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Toggle Button (Korean / English Flags)
              GestureDetector(
                onTap: () {
                  setState(() {
                    TranslationService.isKorean = !TranslationService.isKorean;
                    _resetSession(); // Re-localize active status messages
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        TranslationService.isKorean ? '🇰🇷 한글' : '🇺🇸 ENG',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.translate, color: Colors.cyanAccent, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
                tooltip: TranslationService.isKorean ? '관리자 모드' : 'Admin Panel',
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminScreen()),
                  );
                  if (changed == true) {
                    _loadStoredSentences();
                  }
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: _showSettingsDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRichTargetText(String fullText, String? focusedWord, String? focusedChunk) {
    if (focusedWord == null && focusedChunk == null) {
      return Text(
        fullText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    final String highlightText = focusedWord ?? focusedChunk!;
    final int index = fullText.toLowerCase().indexOf(highlightText.toLowerCase());
    
    if (index == -1) {
      return Text(
        fullText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    final String prefix = fullText.substring(0, index);
    final String match = fullText.substring(index, index + highlightText.length);
    final String suffix = fullText.substring(index + highlightText.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontFamily: 'Outfit',
        ),
        children: [
          TextSpan(text: prefix, style: const TextStyle(color: Colors.white30)),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.cyanAccent,
            ),
          ),
          TextSpan(text: suffix, style: const TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  String _getCategoryText(String rawCategory) {
    if (rawCategory.contains('Easy')) {
      return TranslationService.get('easy');
    } else if (rawCategory.contains('Medium')) {
      return TranslationService.get('medium');
    } else if (rawCategory.contains('Hard')) {
      return TranslationService.get('hard');
    }
    return rawCategory;
  }

  Widget _buildTargetCard(PracticeSentence sentence) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getCategoryText(sentence.category),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${TranslationService.get('sentence_label')} ${_currentIndex + 1}/${_sentences.length}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.get('target_phrase'),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => TtsService.speak(sentence.text),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            TranslationService.get('listen_full'),
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showTranslation = !_showTranslation;
                      });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showTranslation ? Icons.visibility_off : Icons.visibility,
                            color: Colors.cyanAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showTranslation
                                ? TranslationService.get('hide_translation')
                                : TranslationService.get('show_translation'),
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRichTargetText(sentence.text, _focusedWord, _focusedChunk),
          if (_showTranslation) ...[
            const SizedBox(height: 10),
            Text(
              sentence.translation,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
          if (_focusedWord != null || _focusedChunk != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.cyanAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        _focusedWord != null
                            ? '${TranslationService.get('focus_word')}: "${_focusedWord}"'
                            : '${TranslationService.get('focus_chunk')}: "${_focusedChunk}"',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Speak active focus target
                      GestureDetector(
                        onTap: () {
                          final textToSpeak = _focusedWord ?? _focusedChunk;
                          if (textToSpeak != null) {
                            TtsService.speak(textToSpeak);
                          }
                        },
                        child: const Icon(Icons.volume_up, color: Colors.cyanAccent, size: 16),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedWord = null;
                            _focusedChunk = null;
                            _resetSession();
                          });
                        },
                        child: const Icon(Icons.cancel, color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentIndex > 0 ? _onPrevSentence : null,
                icon: const Icon(Icons.arrow_back_ios),
                color: Colors.white,
                disabledColor: Colors.white10,
              ),
              IconButton(
                onPressed: _currentIndex < _sentences.length - 1 ? _onNextSentence : null,
                icon: const Icon(Icons.arrow_forward_ios),
                color: Colors.white,
                disabledColor: Colors.white10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.record_voice_over,
            size: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (_useDemoMode) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationService.get('sim_accuracy'),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  '${(_simulatedAccuracy * 100).toInt()}%',
                  style: TextStyle(
                    color: _simulatedAccuracy > 0.8 ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Slider(
              value: _simulatedAccuracy,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              activeColor: Colors.purpleAccent,
              inactiveColor: Colors.white10,
              onChanged: (val) {
                setState(() {
                  _simulatedAccuracy = val;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    Color scoreColor;
    if (_score >= 85.0) {
      scoreColor = const Color(0xFF00E676); // Green
    } else if (_score >= 60.0) {
      scoreColor = Colors.orangeAccent;
    } else {
      scoreColor = const Color(0xFFFF5252); // Red
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _score / 100.0,
                  backgroundColor: Colors.white10,
                  color: scoreColor,
                  strokeWidth: 8,
                ),
              ),
              Text(
                '${_score.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationService.get('score_title'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _score >= 85.0
                      ? TranslationService.get('feedback_excellent')
                      : _score >= 60.0
                          ? TranslationService.get('feedback_decent')
                          : TranslationService.get('feedback_poor'),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentDisplay() {
    final currentSentence = _sentences[_currentIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TranslationService.get('detail_title'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ComparisonText(
            alignedWords: _alignedWords,
            chunks: _focusedWord != null
                ? [_focusedWord!]
                : (_focusedChunk != null ? [_focusedChunk!] : currentSentence.chunks),
            onWordTap: (tappedWord) {
              setState(() {
                _focusedWord = tappedWord;
                _focusedChunk = null; // Clear chunk focus
                _resetSession();
              });
              // Show notification snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.get('toast_focus_word').replaceAll('%word', tappedWord)),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1E293B),
                  action: SnackBarAction(
                    label: TranslationService.isKorean ? '닫기' : 'Dismiss',
                    textColor: Colors.cyanAccent,
                    onPressed: () {},
                  ),
                ),
              );
            },
            onChunkTap: (tappedChunk) {
              setState(() {
                _focusedChunk = tappedChunk;
                _focusedWord = null; // Clear word focus
                _resetSession();
              });
              // Show notification snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.get('toast_focus_chunk').replaceAll('%chunk', tappedChunk)),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1E293B),
                  action: SnackBarAction(
                    label: TranslationService.isKorean ? '닫기' : 'Dismiss',
                    textColor: Colors.cyanAccent,
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.get('tips_title'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _feedbackText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _recognizedText.isEmpty ? TranslationService.get('say_words') : '"$_recognizedText"',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _hasResult ? _resetSession : null,
                icon: const Icon(Icons.refresh),
                color: Colors.white70,
                disabledColor: Colors.white10,
                iconSize: 28,
              ),
              MicButton(
                isListening: _isListening,
                useDemoMode: _useDemoMode,
                onTap: _toggleListening,
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: Text(TranslationService.get('help_title'), style: const TextStyle(color: Colors.white)),
                      content: Text(
                        TranslationService.get('help_content'),
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TranslationService.get('help_gotit')),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                color: Colors.white70,
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
