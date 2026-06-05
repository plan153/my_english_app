import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_english_app/models/practice_sentence.dart';
import 'package:my_english_app/services/sentence_storage_service.dart';

void main() {
  group('SentenceStorageService and PracticeSentence Tests', () {
    setUp(() {
      // Mock SharedPreferences for unit testing
      SharedPreferences.setMockInitialValues({});
    });

    test('Serialization and Deserialization', () {
      final original = PracticeSentence(
        id: 'test_123',
        text: 'This is a test sentence.',
        category: 'Test Category',
        chunks: ['This is', 'a test sentence'],
        translation: '이것은 테스트 문장입니다.',
      );

      final json = original.toJson();
      final reconstructed = PracticeSentence.fromJson(json, 'fallback');

      expect(reconstructed.id, original.id);
      expect(reconstructed.text, original.text);
      expect(reconstructed.category, original.category);
      expect(reconstructed.chunks, original.chunks);
      expect(reconstructed.translation, original.translation);
    });

    test('Load Default Sentences on First Run', () async {
      final sentences = await SentenceStorageService.loadSentences();
      expect(sentences, isNotEmpty);
      expect(sentences.length, 116);
      expect(sentences[0].text, "I'm so excited.");
    });

    test('Add and Delete Sentence', () async {
      // Load defaults first
      var sentences = await SentenceStorageService.loadSentences();
      final initialCount = sentences.length;

      final newSentence = PracticeSentence(
        id: 'new_id_999',
        text: 'Adding another sentence to database.',
        category: 'Medium 🟡',
        chunks: ['Adding another sentence', 'to database'],
        translation: '데이터베이스에 또 다른 문장을 추가합니다.',
      );

      sentences = await SentenceStorageService.addSentence(newSentence);
      expect(sentences.length, initialCount + 1);
      expect(sentences.last.id, 'new_id_999');

      sentences = await SentenceStorageService.deleteSentence('new_id_999');
      expect(sentences.length, initialCount);
      expect(sentences.any((s) => s.id == 'new_id_999'), isFalse);
    });

    test('Import JSON Array Overwrites Database', () async {
      const String rawJson = '''
      [
        {
          "id": "imported_1",
          "text": "Imported English text.",
          "category": "Easy 🟢",
          "chunks": ["Imported English text"],
          "translation": "가져온 영어 텍스트."
        },
        {
          "id": "imported_2",
          "text": "Another sentence here.",
          "category": "Hard 🔴",
          "chunks": ["Another sentence", "here"],
          "translation": "여기에 또 다른 문장."
        }
      ]
      ''';

      final updated = await SentenceStorageService.importFromJson(rawJson);
      expect(updated.length, 2);
      expect(updated[0].id, 'imported_1');
      expect(updated[0].text, 'Imported English text.');
      expect(updated[1].translation, '여기에 또 다른 문장.');

      // Load from storage to verify it persists
      final reloaded = await SentenceStorageService.loadSentences();
      expect(reloaded.length, 2);
      expect(reloaded[0].text, 'Imported English text.');
    });

    test('Import Invalid JSON Throws Exception', () async {
      // Invalid JSON syntax
      expect(
        () => SentenceStorageService.importFromJson('{invalid json}'),
        throwsA(isA<FormatException>()),
      );

      // Root is not an array
      expect(
        () => SentenceStorageService.importFromJson('{"text": "not an array"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Export to JSON string', () async {
      final sentences = await SentenceStorageService.loadSentences();
      final exportedJson = SentenceStorageService.exportToJson(sentences);

      expect(exportedJson, contains("I'm so excited."));
      expect(exportedJson, contains("정말 신나요."));
    });
  });
}
