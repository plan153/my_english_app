import '../scoring/text_normalizer.dart';

/// 한 개의 연습 문장과 그 메타데이터.
///
/// 문장은 의미 단위 [chunks]로 나뉘며, [words]는 본문에서 자동으로 파생된다.
/// 따라서 하나의 문장으로 문장/청크/단어 세 가지 단위의 연습이 모두 가능하다.
class PracticeSentence {
  final String id;
  final String text;
  final String category;
  final List<String> chunks;
  final String translation;

  const PracticeSentence({
    required this.id,
    required this.text,
    required this.category,
    required this.chunks,
    required this.translation,
  });

  /// 본문을 공백 기준으로 나눈 개별 단어 목록 (구두점 보존, 빈 토큰 제거).
  List<String> get words => TextNormalizer.tokenize(text);

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'chunks': chunks,
        'translation': translation,
      };

  factory PracticeSentence.fromJson(
    Map<String, dynamic> json,
    String fallbackId,
  ) {
    return PracticeSentence(
      id: json['id']?.toString() ?? fallbackId,
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      chunks: (json['chunks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [json['text']?.toString() ?? ''],
      translation: json['translation']?.toString() ?? '',
    );
  }
}
