import 'package:flutter_test/flutter_test.dart';
import 'package:pronunciation_engine/pronunciation_engine.dart';
import 'package:my_english_app/services/alignment_service.dart';

void main() {
  group('AlignmentService Tests', () {
    test('Perfect Match Alignment', () {
      const target = 'Hello world';
      const spoken = 'Hello world';

      final score = AlignmentService.calculateOverallScore(target, spoken);
      final aligned = AlignmentService.alignSentences(target, spoken);

      expect(score, closeTo(100.0, 0.01));
      expect(aligned.length, 2);
      expect(aligned[0].status, WordStatus.match);
      expect(aligned[0].targetWord, 'Hello');
      expect(aligned[0].spokenWord, 'Hello');
      expect(aligned[1].status, WordStatus.match);
      expect(aligned[1].targetWord, 'world');
      expect(aligned[1].spokenWord, 'world');
    });

    test('Case and Punctuation Insensitivity', () {
      const target = 'Hello, World!';
      const spoken = 'hello world';

      final score = AlignmentService.calculateOverallScore(target, spoken);
      final aligned = AlignmentService.alignSentences(target, spoken);

      expect(score, closeTo(100.0, 0.01));
      expect(aligned.length, 2);
      expect(aligned[0].status, WordStatus.match);
      expect(aligned[1].status, WordStatus.match);
    });

    test('Single Word Deletion (Missing Word)', () {
      const target = 'The quick brown fox';
      const spoken = 'The quick fox';

      final score = AlignmentService.calculateOverallScore(target, spoken);
      final aligned = AlignmentService.alignSentences(target, spoken);

      expect(score, lessThan(100.0));
      // Expected aligned: [The, quick, brown (missing), fox]
      expect(aligned.length, 4);
      expect(aligned[0].targetWord, 'The');
      expect(aligned[0].status, WordStatus.match);

      expect(aligned[1].targetWord, 'quick');
      expect(aligned[1].status, WordStatus.match);

      expect(aligned[2].targetWord, 'brown');
      expect(aligned[2].spokenWord, '');
      expect(aligned[2].status, WordStatus.missing);

      expect(aligned[3].targetWord, 'fox');
      expect(aligned[3].status, WordStatus.match);
    });

    test('Single Word Insertion (Extra Word)', () {
      const target = 'The quick fox';
      const spoken = 'The quick super fox';

      final score = AlignmentService.calculateOverallScore(target, spoken);
      final aligned = AlignmentService.alignSentences(target, spoken);

      expect(score, lessThan(100.0));
      // Expected aligned: [The, quick, super (extra), fox]
      expect(aligned.length, 4);
      expect(aligned[0].targetWord, 'The');
      expect(aligned[0].status, WordStatus.match);

      expect(aligned[1].targetWord, 'quick');
      expect(aligned[1].status, WordStatus.match);

      expect(aligned[2].targetWord, '');
      expect(aligned[2].spokenWord, 'super');
      expect(aligned[2].status, WordStatus.extra);

      expect(aligned[3].targetWord, 'fox');
      expect(aligned[3].status, WordStatus.match);
    });

    test('Word Substitution (Mismatch Word)', () {
      const target = 'I love flutter';
      const spoken = 'I live flutter';

      final score = AlignmentService.calculateOverallScore(target, spoken);
      final aligned = AlignmentService.alignSentences(target, spoken);

      expect(score, lessThan(100.0));
      // Expected aligned: [I, love (mismatch with live), flutter]
      expect(aligned.length, 3);
      expect(aligned[0].targetWord, 'I');
      expect(aligned[0].status, WordStatus.match);

      expect(aligned[1].targetWord, 'love');
      expect(aligned[1].spokenWord, 'live');
      expect(aligned[1].status, WordStatus.mismatch);

      expect(aligned[2].targetWord, 'flutter');
      expect(aligned[2].status, WordStatus.match);
    });

    test('Empty Inputs Handling', () {
      final score = AlignmentService.calculateOverallScore('', '');
      final aligned = AlignmentService.alignSentences('', '');

      expect(score, 100.0);
      expect(aligned, isEmpty);
    });
  });
}
