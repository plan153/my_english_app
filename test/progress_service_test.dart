import 'package:flutter_test/flutter_test.dart';
import 'package:my_english_app/services/progress_service.dart';
import 'package:pronunciation_engine/pronunciation_engine.dart';

PracticeAttempt mk(String id, double score, DateTime ts,
        [PracticeLevel level = PracticeLevel.sentence]) =>
    PracticeAttempt(sentenceId: id, level: level, score: score, timestamp: ts);

void main() {
  group('ProgressStats 집계', () {
    test('빈 기록의 기본값', () {
      const stats = ProgressStats([]);
      expect(stats.totalAttempts, 0);
      expect(stats.averageScore, 0.0);
      expect(stats.bestScore, 0.0);
      expect(stats.uniqueSentencesPracticed, 0);
      expect(stats.bestScoreFor('x'), isNull);
    });

    test('평균/최고/합격 수', () {
      final now = DateTime(2026, 1, 1, 12);
      final stats = ProgressStats([
        mk('a', 90, now),
        mk('a', 60, now),
        mk('b', 30, now),
      ]);
      expect(stats.totalAttempts, 3);
      expect(stats.averageScore, closeTo(60.0, 0.001));
      expect(stats.bestScore, 90.0);
      expect(stats.passedCount(), 1); // 90만 합격
      expect(stats.uniqueSentencesPracticed, 2);
    });

    test('문장별 최고 점수', () {
      final now = DateTime(2026, 1, 1);
      final stats = ProgressStats([mk('a', 70, now), mk('a', 95, now)]);
      expect(stats.bestScoreFor('a'), 95.0);
      expect(stats.bestScoreFor('zzz'), isNull);
    });

    test('단위별 시도 수', () {
      final now = DateTime(2026, 1, 1);
      final stats = ProgressStats([
        mk('a', 80, now, PracticeLevel.sentence),
        mk('a', 80, now, PracticeLevel.word),
        mk('a', 80, now, PracticeLevel.word),
      ]);
      final byLevel = stats.attemptsByLevel;
      expect(byLevel[PracticeLevel.sentence], 1);
      expect(byLevel[PracticeLevel.word], 2);
      expect(byLevel[PracticeLevel.chunk], 0);
    });

    test('recent는 최신순으로 n개', () {
      final stats = ProgressStats([
        mk('a', 1, DateTime(2026, 1, 1)),
        mk('b', 2, DateTime(2026, 1, 3)),
        mk('c', 3, DateTime(2026, 1, 2)),
      ]);
      final recent = stats.recent(2);
      expect(recent.length, 2);
      expect(recent[0].sentenceId, 'b'); // 가장 최신
      expect(recent[1].sentenceId, 'c');
    });
  });

  group('streakDays', () {
    test('오늘 포함 연속 3일', () {
      final now = DateTime(2026, 6, 6, 10);
      final stats = ProgressStats([
        mk('a', 80, DateTime(2026, 6, 6)),
        mk('a', 80, DateTime(2026, 6, 5)),
        mk('a', 80, DateTime(2026, 6, 4)),
      ]);
      expect(stats.streakDays(now), 3);
    });

    test('오늘 기록이 없어도 어제부터 인정', () {
      final now = DateTime(2026, 6, 6, 10);
      final stats = ProgressStats([
        mk('a', 80, DateTime(2026, 6, 5)),
        mk('a', 80, DateTime(2026, 6, 4)),
      ]);
      expect(stats.streakDays(now), 2);
    });

    test('이틀 전 마지막 기록이면 streak 0', () {
      final now = DateTime(2026, 6, 6, 10);
      final stats = ProgressStats([mk('a', 80, DateTime(2026, 6, 4))]);
      expect(stats.streakDays(now), 0);
    });

    test('중간에 빠진 날이 있으면 끊긴다', () {
      final now = DateTime(2026, 6, 6, 10);
      final stats = ProgressStats([
        mk('a', 80, DateTime(2026, 6, 6)),
        mk('a', 80, DateTime(2026, 6, 4)), // 6/5 빠짐
      ]);
      expect(stats.streakDays(now), 1);
    });
  });

  group('PracticeAttempt 직렬화', () {
    test('round-trip', () {
      final a = mk('s1', 88.5, DateTime(2026, 6, 6, 9, 30), PracticeLevel.chunk);
      final b = PracticeAttempt.fromJson(a.toJson());
      expect(b.sentenceId, 's1');
      expect(b.score, 88.5);
      expect(b.level, PracticeLevel.chunk);
      expect(b.timestamp, a.timestamp);
    });
  });
}
