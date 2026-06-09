/// 텍스트 하나를 재생하고 **완료되면** 끝나는 Future를 돌려주는 함수.
typedef SpeakFn = Future<void> Function(String text);

/// 재생 진행 콜백. [itemIndex]는 0-based 항목 인덱스, [repeat]은 1-based 반복 회차.
typedef SequenceProgress = void Function(int itemIndex, int repeat);

/// 반복 듣기 + 여러 항목 연속 듣기를 오케스트레이션하는 순수 Dart 시퀀서.
///
/// TTS 엔진이나 Flutter에 의존하지 않고, 주입된 [speak] 콜백만 사용한다.
/// 따라서 어떤 앱/엔진에서도 재사용할 수 있고 단위 테스트가 쉽다.
///
/// 사용 예:
/// ```dart
/// final seq = PlaybackSequencer(speak: (t) => tts.speak(t));
/// // 한 문장을 3회 반복
/// await seq.play(['Hello'], repeatCount: 3);
/// // 여러 문장을 각각 3회 반복 후 다음 문장으로
/// await seq.play(sentences, repeatCount: 3, onProgress: (i, r) => highlight(i));
/// ```
class PlaybackSequencer {
  /// 실제 음성 재생 함수 (재생 완료 시 resolve 되어야 한다).
  final SpeakFn speak;

  /// 항목/반복 사이 기본 간격.
  final Duration gap;

  bool _cancelled = false;
  bool _running = false;

  PlaybackSequencer({required this.speak, this.gap = Duration.zero});

  /// 현재 재생 시퀀스가 진행 중인지 여부.
  bool get isRunning => _running;

  /// 진행 중인 시퀀스를 취소한다. (현재 재생 중인 음성 자체의 중단은 호출 측에서
  /// 별도로 처리해야 한다 — 시퀀서는 다음 재생 예약만 멈춘다.)
  void stop() {
    _cancelled = true;
  }

  /// [items]의 각 항목을 [repeatCount]회 반복 재생한다.
  ///
  /// 한 항목을 repeatCount회 모두 재생한 뒤 다음 항목으로 넘어간다.
  /// [onProgress]는 각 회차 재생 시작 직전에 호출된다.
  /// 이미 실행 중이면 아무 것도 하지 않는다.
  Future<void> play(
    List<String> items, {
    int repeatCount = 1,
    SequenceProgress? onProgress,
    Duration? gap,
  }) async {
    if (_running) return;
    final reps = repeatCount < 1 ? 1 : repeatCount;
    final g = gap ?? this.gap;

    _cancelled = false;
    _running = true;
    try {
      for (var i = 0; i < items.length; i++) {
        if (_cancelled) break;
        for (var r = 1; r <= reps; r++) {
          if (_cancelled) break;
          onProgress?.call(i, r);
          await speak(items[i]);
          if (_cancelled) break;
          final isLast = i == items.length - 1 && r == reps;
          if (!isLast && g > Duration.zero) {
            await Future.delayed(g);
          }
        }
      }
    } finally {
      _running = false;
    }
  }
}
