import 'dart:math';
import 'package:string_similarity/string_similarity.dart';
import '../models/practice_sentence.dart';
import 'translation_service.dart';


class AlignmentService {
  /// Cleans punctuation from a word and converts it to lowercase.
  static String cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()??"“”]'), '')
        .trim()
        .toLowerCase();
  }

  /// Calculates the overall score (0 to 100) using string_similarity
  static double calculateOverallScore(String target, String spoken) {
    if (target.isEmpty && spoken.isEmpty) return 100.0;
    if (target.isEmpty || spoken.isEmpty) return 0.0;

    // Direct similarity comparison of cleaned lowercase strings
    final cleanTarget = cleanWord(target);
    final cleanSpoken = cleanWord(spoken);

    return StringSimilarity.compareTwoStrings(cleanTarget, cleanSpoken) * 100.0;
  }

  /// Aligns the target sentence and spoken sentence word-by-word.
  /// Returns a list of aligned words indicating matches, mismatches, missing, or extras.
  static List<AlignmentWord> alignSentences(String target, String spoken) {
    // 1. Tokenize original sentences (retaining capitalization for visual reference,
    // but cleaning them for the DP comparison matrix).
    final List<String> targetTokens = target.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final List<String> spokenTokens = spoken.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    final int n = targetTokens.length;
    final int m = spokenTokens.length;

    if (n == 0 && m == 0) return [];
    if (n == 0) {
      return spokenTokens.map((w) => AlignmentWord(
        targetWord: '',
        spokenWord: w,
        status: WordStatus.extra,
      )).toList();
    }
    if (m == 0) {
      return targetTokens.map((w) => AlignmentWord(
        targetWord: w,
        spokenWord: '',
        status: WordStatus.missing,
      )).toList();
    }

    // Prepare clean tokens for comparison
    final List<String> cleanTarget = targetTokens.map(cleanWord).toList();
    final List<String> cleanSpoken = spokenTokens.map(cleanWord).toList();

    // 2. Perform Dynamic Programming Alignment using String Similarity as a substitution cost.
    // dp[i][j] stores the edit cost to align cleanTarget[0..i-1] with cleanSpoken[0..j-1].
    final List<List<double>> dp = List.generate(n + 1, (_) => List.filled(m + 1, 0.0));

    // Initialize boundary conditions
    for (int i = 0; i <= n; i++) dp[i][0] = i * 1.0;
    for (int j = 0; j <= m; j++) dp[0][j] = j * 1.0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final double deleteCost = dp[i - 1][j] + 1.0;
        final double insertCost = dp[i][j - 1] + 1.0;

        // Custom substitution cost based on word similarity.
        // A similarity of 1.0 means 0 substitution cost.
        // A similarity of 0.0 means 1.0 substitution cost.
        final double wordSim = StringSimilarity.compareTwoStrings(cleanTarget[i - 1], cleanSpoken[j - 1]);
        final double subCost = dp[i - 1][j - 1] + (1.0 - wordSim);

        dp[i][j] = min(deleteCost, min(insertCost, subCost));
      }
    }

    // 3. Backtrack to find the alignment path
    final List<AlignmentWord> aligned = [];
    int i = n;
    int j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final double wordSim = StringSimilarity.compareTwoStrings(cleanTarget[i - 1], cleanSpoken[j - 1]);
        final double current = dp[i][j];
        final double subCost = dp[i - 1][j - 1] + (1.0 - wordSim);
        final double deleteCost = dp[i - 1][j] + 1.0;

        // Check if we came from diagonal (substitution / match)
        if ((current - subCost).abs() < 1e-4) {
          // If the word matches exactly or similarity is very high, mark it as match.
          // Otherwise, it is a mismatch.
          final WordStatus status = (cleanTarget[i - 1] == cleanSpoken[j - 1] || wordSim > 0.8)
              ? WordStatus.match
              : WordStatus.mismatch;

          aligned.add(AlignmentWord(
            targetWord: targetTokens[i - 1],
            spokenWord: spokenTokens[j - 1],
            status: status,
          ));
          i--;
          j--;
          continue;
        }

        // Check if we came from deletion (missing word)
        if ((current - deleteCost).abs() < 1e-4) {
          aligned.add(AlignmentWord(
            targetWord: targetTokens[i - 1],
            spokenWord: '',
            status: WordStatus.missing,
          ));
          i--;
          continue;
        }

        // Otherwise we came from insertion (extra word)
        aligned.add(AlignmentWord(
          targetWord: '',
          spokenWord: spokenTokens[j - 1],
          status: WordStatus.extra,
        ));
        j--;
      } else if (i > 0) {
        // Backtrack along the top boundary (deletions)
        aligned.add(AlignmentWord(
          targetWord: targetTokens[i - 1],
          spokenWord: '',
          status: WordStatus.missing,
        ));
        i--;
      } else {
        // Backtrack along the left boundary (insertions)
        aligned.add(AlignmentWord(
          targetWord: '',
          spokenWord: spokenTokens[j - 1],
          status: WordStatus.extra,
        ));
        j--;
      }
    }

    // Reconstruct path in forward order
    return aligned.reversed.toList();
  }

  /// Generates helpful feedback explaining specifically what was incorrect.
  static String generateFeedbackText(List<AlignmentWord> aligned) {
    final bool isKo = TranslationService.isKorean;
    final List<String> tips = [];
    int matchCount = 0;
    int totalTargetWords = 0;

    for (var alignedWord in aligned) {
      if (alignedWord.status != WordStatus.extra) {
        totalTargetWords++;
      }
      if (alignedWord.status == WordStatus.match) {
        matchCount++;
      } else if (alignedWord.status == WordStatus.mismatch) {
        if (isKo) {
          tips.add('"${alignedWord.targetWord}" 대신 "${alignedWord.spokenWord}"(으)로 발음했습니다.');
        } else {
          tips.add('Said "${alignedWord.spokenWord}" instead of "${alignedWord.targetWord}"');
        }
      } else if (alignedWord.status == WordStatus.missing) {
        if (isKo) {
          tips.add('"${alignedWord.targetWord}" 단어를 빠뜨리고 읽었습니다.');
        } else {
          tips.add('Missed the word "${alignedWord.targetWord}"');
        }
      } else if (alignedWord.status == WordStatus.extra) {
        if (isKo) {
          tips.add('원문에 없는 불필요한 단어 "${alignedWord.spokenWord}"(을)를 추가로 말했습니다.');
        } else {
          tips.add('Added extra word "${alignedWord.spokenWord}"');
        }
      }
    }

    if (totalTargetWords == 0) {
      return isKo ? '문장을 말씀해 주세요.' : 'Please try speaking.';
    }

    final double matchRatio = matchCount / totalTargetWords;
    if (matchRatio == 1.0) {
      return isKo ? '훌륭합니다! 완벽한 발음입니다!' : 'Excellent! Perfect pronunciation!';
    } else if (matchRatio > 0.8) {
      final title = isKo ? '훌륭한 발음입니다! 미세 교정 제안:\n' : 'Great pronunciation! Minor corrections:\n';
      final buffer = StringBuffer(title);
      buffer.write(tips.take(3).map((t) => '• $t').join('\n'));
      return buffer.toString();
    } else if (matchRatio > 0.5) {
      final title = isKo ? '잘 시도하셨습니다. 개선해야 할 부분들:\n' : 'Good try. Here are a few corrections to work on:\n';
      final buffer = StringBuffer(title);
      buffer.write(tips.take(3).map((t) => '• $t').join('\n'));
      return buffer.toString();
    } else {
      if (tips.isEmpty) {
        return isKo 
            ? '음성을 명확하게 인식하지 못했습니다. 조금 더 마이크에 가까이 대고 큰 소리로 말씀해 보세요.' 
            : 'We couldn\'t recognize the words clearly. Try speaking a bit louder or closer to the microphone.';
      }
      final title = isKo ? '함께 더 연습해 봅시다! 집중 개선 영역:\n' : 'Let\'s practice more! Key focus areas:\n';
      final buffer = StringBuffer(title);
      buffer.write(tips.take(3).map((t) => '• $t').join('\n'));
      return buffer.toString();
    }
  }
}
