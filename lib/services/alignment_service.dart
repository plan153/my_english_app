import 'package:pronunciation_engine/pronunciation_engine.dart';

import 'translation_service.dart';

/// 앱 ↔ 재사용 엔진(`pronunciation_engine`) 어댑터.
///
/// 채점·정렬·피드백 로직은 모두 엔진 패키지의 [PronunciationScorer] /
/// [FeedbackGenerator]에 위임한다. 이 클래스는 기존 화면 코드와의 호환을 위한
/// 얇은 래퍼이며, 앱의 현재 언어 설정([TranslationService])을 피드백에 주입한다.
class AlignmentService {
  /// 구두점 제거 + 소문자 정규화.
  static String cleanWord(String word) => TextNormalizer.clean(word);

  /// 전체 점수 (0~100).
  static double calculateOverallScore(String target, String spoken) =>
      PronunciationScorer.overallScore(target, spoken);

  /// 단어 단위 정렬.
  static List<AlignmentWord> alignSentences(String target, String spoken) =>
      PronunciationScorer.align(target, spoken);

  /// 현재 언어 설정에 맞춘 피드백 문구.
  static String generateFeedbackText(List<AlignmentWord> aligned) =>
      FeedbackGenerator.generate(aligned, isKorean: TranslationService.isKorean);
}
