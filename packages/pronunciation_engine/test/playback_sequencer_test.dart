import 'package:pronunciation_engine/pronunciation_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PlaybackSequencer', () {
    test('단일 항목을 repeatCount회 반복한다', () async {
      final spoken = <String>[];
      final seq = PlaybackSequencer(speak: (t) async => spoken.add(t));
      await seq.play(['Hello'], repeatCount: 3);
      expect(spoken, ['Hello', 'Hello', 'Hello']);
    });

    test('여러 항목을 각각 repeatCount회 반복 후 다음으로 (순서 보존)', () async {
      final spoken = <String>[];
      final seq = PlaybackSequencer(speak: (t) async => spoken.add(t));
      await seq.play(['A', 'B', 'C'], repeatCount: 2);
      // A를 2회 모두 재생한 뒤 B로 넘어가야 한다
      expect(spoken, ['A', 'A', 'B', 'B', 'C', 'C']);
    });

    test('진행 콜백은 itemIndex/회차(1-based)를 보고한다', () async {
      final progress = <List<int>>[];
      final seq = PlaybackSequencer(speak: (t) async {});
      await seq.play(['A', 'B'],
          repeatCount: 2, onProgress: (i, r) => progress.add([i, r]));
      expect(progress, [
        [0, 1],
        [0, 2],
        [1, 1],
        [1, 2],
      ]);
    });

    test('repeatCount<1은 1로 클램프된다', () async {
      final spoken = <String>[];
      final seq = PlaybackSequencer(speak: (t) async => spoken.add(t));
      await seq.play(['A'], repeatCount: 0);
      expect(spoken, ['A']);
    });

    test('stop() 호출 시 이후 재생을 멈춘다', () async {
      final spoken = <String>[];
      late PlaybackSequencer seq;
      seq = PlaybackSequencer(speak: (t) async {
        spoken.add(t);
        if (t == 'B') seq.stop(); // B 재생 후 취소
      });
      await seq.play(['A', 'B', 'C', 'D'], repeatCount: 1);
      expect(spoken, ['A', 'B']); // C, D는 재생되지 않음
    });

    test('실행 중에는 isRunning이 true, 끝나면 false', () async {
      final seq = PlaybackSequencer(speak: (t) async {});
      expect(seq.isRunning, isFalse);
      final f = seq.play(['A'], repeatCount: 1);
      expect(seq.isRunning, isTrue);
      await f;
      expect(seq.isRunning, isFalse);
    });

    test('빈 목록은 아무 것도 재생하지 않는다', () async {
      final spoken = <String>[];
      final seq = PlaybackSequencer(speak: (t) async => spoken.add(t));
      await seq.play([], repeatCount: 3);
      expect(spoken, isEmpty);
    });
  });
}
