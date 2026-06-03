import 'dart:convert';
import 'dart:io' show File;
import 'dart:js' as js; // Safe import, runs only on Web using kIsWeb check
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/practice_sentence.dart';
import '../services/sentence_storage_service.dart';
import '../services/translation_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<PracticeSentence> _sentences = [];
  bool _isLoading = true;

  // Add form controllers
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _translationController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Easy 🟢');
  final _chunksController = TextEditingController();

  // Paste JSON controller
  final _pasteJsonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _translationController.dispose();
    _categoryController.dispose();
    _chunksController.dispose();
    _pasteJsonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SentenceStorageService.loadSentences();
    setState(() {
      _sentences = data;
      _isLoading = false;
    });
  }

  Future<void> _onAddSentence() async {
    if (_formKey.currentState!.validate()) {
      final String text = _textController.text.trim();
      final String translation = _translationController.text.trim();
      final String category = _categoryController.text.trim();
      
      // Parse chunks. If empty, default to full text.
      List<String> chunks = [];
      if (_chunksController.text.trim().isNotEmpty) {
        chunks = _chunksController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (chunks.isEmpty) {
        chunks = [text];
      }

      final newSentence = PracticeSentence(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        category: category,
        chunks: chunks,
        translation: translation,
      );

      final updated = await SentenceStorageService.addSentence(newSentence);
      setState(() {
        _sentences = updated;
        _textController.clear();
        _translationController.clear();
        _categoryController.text = 'Easy 🟢';
        _chunksController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.get('admin_sentence_added')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _onDeleteSentence(String id) async {
    final updated = await SentenceStorageService.deleteSentence(id);
    setState(() {
      _sentences = updated;
    });
  }

  Future<void> _onResetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(TranslationService.get('admin_btn_reset'), style: const TextStyle(color: Colors.white)),
        content: Text(
          TranslationService.isKorean
              ? '정말로 데이터베이스를 기본 문장 5개로 초기화하시겠습니까?\n추가하신 모든 문장이 삭제됩니다.'
              : 'Are you sure you want to reset the database to the 5 default sentences?\nAll added sentences will be deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationService.get('settings_cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              TranslationService.isKorean ? '초기화 실행' : 'Reset Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = await SentenceStorageService.resetToDefaults();
      setState(() {
        _sentences = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database reset successful.'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _onUploadJsonFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String? jsonContent;
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          if (bytes != null) {
            jsonContent = utf8.decode(bytes);
          }
        } else {
          final path = result.files.first.path;
          if (path != null) {
            final file = File(path);
            jsonContent = await file.readAsString();
          }
        }

        if (jsonContent != null) {
          final updated = await SentenceStorageService.importFromJson(jsonContent);
          setState(() {
            _sentences = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationService.get('admin_success_import')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationService.get('admin_err_invalid_json')}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onImportPastedJson() async {
    final String pasted = _pasteJsonController.text.trim();
    if (pasted.isEmpty) return;

    try {
      final updated = await SentenceStorageService.importFromJson(pasted);
      setState(() {
        _sentences = updated;
        _pasteJsonController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.get('admin_success_import')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationService.get('admin_err_invalid_json')}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onExportJsonFile() {
    try {
      final String jsonStr = SentenceStorageService.exportToJson(_sentences);
      
      if (kIsWeb) {
        // Trigger a clean browser file download via evaluation of standard JS.
        // This is safe to compile on macOS/iOS/Android because we do not import dart:html.
        final encodedJson = Uri.encodeComponent(jsonStr);
        final jsCode = """
          (function() {
            var element = document.createElement('a');
            element.setAttribute('href', 'data:text/json;charset=utf-8,' + '$encodedJson');
            element.setAttribute('download', 'sentences.json');
            element.style.display = 'none';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
          })();
        """;
        js.context.callMethod('eval', [jsCode]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File download triggered.'), backgroundColor: Colors.green),
        );
      } else {
        // For non-web platform, print/copy to clipboard as export fallback,
        // or we could show path save options.
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Export JSON (Desktop/Mobile)', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.cyanAccent, fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white70)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = TranslationService.isKorean;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              // Side-by-side view for wider screens
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        _buildDatabaseControlsCard(),
                                        const SizedBox(height: 20),
                                        _buildAddFormCard(),
                                        const SizedBox(height: 20),
                                        _buildPasteJsonCard(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: _buildSentenceListCard(),
                                  ),
                                ],
                              );
                            } else {
                              // Stacked view for smaller screens
                              return Column(
                                children: [
                                  _buildDatabaseControlsCard(),
                                  const SizedBox(height: 20),
                                  _buildAddFormCard(),
                                  const SizedBox(height: 20),
                                  _buildPasteJsonCard(),
                                  const SizedBox(height: 20),
                                  _buildSentenceListCard(),
                                  const SizedBox(height: 40),
                                ],
                              );
                            }
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, true), // Signal that database might have changed
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.get('admin_panel'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TranslationService.get('admin_desc'),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.restore, size: 16),
            label: Text(TranslationService.get('admin_btn_reset'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _onResetToDefaults,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseControlsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TranslationService.get('admin_upload_json'),
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_upload),
                  label: Text(
                    TranslationService.isKorean ? 'JSON 파일 업로드하기' : 'Upload JSON File',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _onUploadJsonFile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_download),
                  label: Text(
                    TranslationService.get('admin_export_json'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: _onExportJsonFile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              TranslationService.get('admin_add_sentence'),
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Sentence input
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: TranslationService.get('admin_input_text'),
                labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                hintText: 'e.g. The quick brown fox jumps over the lazy dog.',
                hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Translation input
            TextFormField(
              controller: _translationController,
              decoration: InputDecoration(
                labelText: TranslationService.get('admin_input_translation'),
                labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                hintText: 'e.g. 빠른 갈색 여우가 게으른 개를 뛰어넘습니다.',
                hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Category input
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: TranslationService.get('admin_input_category'),
                labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Chunks input
            TextFormField(
              controller: _chunksController,
              decoration: InputDecoration(
                labelText: TranslationService.get('admin_input_chunks'),
                labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                hintText: 'e.g. Chunk one, Chunk two (Optional)',
                hintStyle: const TextStyle(color: Colors.white10, fontSize: 12),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _onAddSentence,
              child: Text(
                TranslationService.get('admin_btn_add'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteJsonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TranslationService.get('admin_paste_json'),
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pasteJsonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '[\n  {\n    "text": "Hello world",\n    "category": "Easy 🟢",\n    "chunks": ["Hello world"],\n    "translation": "안녕 세상아"\n  }\n]',
              hintStyle: const TextStyle(color: Colors.white10, fontSize: 11, fontFamily: 'monospace'),
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _onImportPastedJson,
            child: Text(
              TranslationService.get('admin_btn_import'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceListCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationService.get('admin_sentence_list'),
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_sentences.length}',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sentences.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No sentences registered in database.',
                      style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sentences.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final item = _sentences[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.translation,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chunks: ${item.chunks.join(" | ")}',
                                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => _onDeleteSentence(item.id),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
