/// 연습 단위(granularity).
///
/// 초보자가 긴 문장을 한 번에 소화하기 어려우므로,
/// 문장 → 청크(의미 덩어리) → 단어 순서로 쉽게 쪼개 연습할 수 있다.
enum PracticeLevel {
  /// 문장 전체.
  sentence,

  /// 의미 단위 청크 (구/절).
  chunk,

  /// 단어 하나.
  word,
}

extension PracticeLevelLabel on PracticeLevel {
  /// 한국어 라벨.
  String get labelKo {
    switch (this) {
      case PracticeLevel.sentence:
        return '문장';
      case PracticeLevel.chunk:
        return '청크';
      case PracticeLevel.word:
        return '단어';
    }
  }

  /// 영어 라벨.
  String get labelEn {
    switch (this) {
      case PracticeLevel.sentence:
        return 'Sentence';
      case PracticeLevel.chunk:
        return 'Chunk';
      case PracticeLevel.word:
        return 'Word';
    }
  }
}
