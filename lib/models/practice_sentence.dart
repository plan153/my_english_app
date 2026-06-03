enum WordStatus {
  match,       // Exact or high similarity match
  mismatch,    // Substituted / mispronounced word
  extra,       // Spoken word that wasn't in the target sentence (inserted)
  missing,     // Target word that was omitted (deleted)
}

class AlignmentWord {
  final String targetWord;
  final String spokenWord;
  final WordStatus status;

  AlignmentWord({
    required this.targetWord,
    required this.spokenWord,
    required this.status,
  });

  @override
  String toString() {
    return 'AlignmentWord(target: "$targetWord", spoken: "$spokenWord", status: $status)';
  }
}

class PracticeSentence {
  final String id;
  final String text;
  final String category;
  final List<String> chunks;
  final String translation;

  PracticeSentence({
    required this.id,
    required this.text,
    required this.category,
    required this.chunks,
    required this.translation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'chunks': chunks,
      'translation': translation,
    };
  }

  factory PracticeSentence.fromJson(Map<String, dynamic> json, String fallbackId) {
    return PracticeSentence(
      id: json['id']?.toString() ?? fallbackId,
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      chunks: (json['chunks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [json['text']?.toString() ?? ''],
      translation: json['translation']?.toString() ?? '',
    );
  }
}

class PracticeResult {
  final String rawSpokenText;
  final double overallScore; // 0.0 to 100.0
  final List<AlignmentWord> alignedWords;

  PracticeResult({
    required this.rawSpokenText,
    required this.overallScore,
    required this.alignedWords,
  });
}
