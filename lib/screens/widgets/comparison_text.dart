import 'package:flutter/material.dart';
import '../../models/practice_sentence.dart';
import '../../services/alignment_service.dart';
import '../../services/translation_service.dart';


class ComparisonText extends StatelessWidget {
  final List<AlignmentWord> alignedWords;
  final List<String> chunks;
  final Function(String targetWord)? onWordTap;
  final Function(String chunk)? onChunkTap;

  const ComparisonText({
    Key? key,
    required this.alignedWords,
    required this.chunks,
    this.onWordTap,
    this.onChunkTap,
  }) : super(key: key);

  /// Helper to group alignment results into their respective semantic chunks
  List<List<AlignmentWord>> _groupAlignedWordsByChunks() {
    List<List<AlignmentWord>> groups = [];
    int alignedIdx = 0;

    for (var chunk in chunks) {
      final chunkCleanWords = chunk
          .split(RegExp(r'\s+'))
          .map(AlignmentService.cleanWord)
          .where((w) => w.isNotEmpty)
          .toList();
      
      List<AlignmentWord> currentGroup = [];
      int wordsMatched = 0;

      // Pull alignment words that correspond to this chunk
      while (alignedIdx < alignedWords.length && wordsMatched < chunkCleanWords.length) {
        final alignedWord = alignedWords[alignedIdx];
        currentGroup.add(alignedWord);

        // Extra words inserted by the speaker don't count toward matching target chunk words
        if (alignedWord.status != WordStatus.extra) {
          wordsMatched++;
        }
        alignedIdx++;
      }

      // Add any leftover words (e.g. trailing extra words) to the final chunk
      if (chunk == chunks.last) {
        while (alignedIdx < alignedWords.length) {
          currentGroup.add(alignedWords[alignedIdx]);
          alignedIdx++;
        }
      }

      groups.add(currentGroup);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (alignedWords.isEmpty) {
      return const Center(
        child: Text(
          'Your pronunciation analysis will appear here.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final groupedChunks = _groupAlignedWordsByChunks();

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: List.generate(groupedChunks.length, (index) {
        final chunkText = chunks[index];
        final alignedGroup = groupedChunks[index];

        return _buildChunkBlock(chunkText, alignedGroup);
      }),
    );
  }

  Widget _buildChunkBlock(String chunkText, List<AlignmentWord> alignedGroup) {
    return GestureDetector(
      onTap: () => onChunkTap?.call(chunkText),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 320),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: alignedGroup.map((word) {
              switch (word.status) {
                case WordStatus.match:
                  return _buildClickableWord(word.targetWord, _buildMatchWord(word.targetWord));
                case WordStatus.mismatch:
                  return _buildClickableWord(word.targetWord, _buildMismatchWord(word.targetWord, word.spokenWord));
                case WordStatus.missing:
                  return _buildClickableWord(word.targetWord, _buildMissingWord(word.targetWord));
                case WordStatus.extra:
                  return _buildClickableWord(word.spokenWord, _buildExtraWord(word.spokenWord));
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableWord(String wordToPractice, Widget child) {
    final cleanWord = AlignmentService.cleanWord(wordToPractice);
    if (cleanWord.isEmpty) return child;
    return GestureDetector(
      onTap: () => onWordTap?.call(cleanWord),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
    );
  }

  Widget _buildMatchWord(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMismatchWord(String target, String spoken) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF1744).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
          ),
          child: Text(
            target,
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '🗣️ "$spoken"',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingWord(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.lineThrough,
        ),
      ),
    );
  }

  Widget _buildExtraWord(String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          TranslationService.isKorean ? '➕ 초과 발음' : '➕ extra',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
