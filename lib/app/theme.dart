import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전역 색상 팔레트. 기존 PronouncePro 다크 아이덴티티를 계승·정리한다.
class AppColors {
  AppColors._();

  // 배경 / 표면
  static const Color bgTop = Color(0xFF0F172A);
  static const Color bgBottom = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);

  // 브랜드
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDark = Color(0xFF00838F);

  // 점수 / 상태
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB40);
  static const Color danger = Color(0xFFFF5252);

  // 텍스트
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  /// 점수(0~100)에 대응하는 색.
  static Color forScore(double score) {
    if (score >= 85.0) return success;
    if (score >= 60.0) return warning;
    return danger;
  }

  /// 메인 배경 그라데이션.
  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 카드 표면 그라데이션.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surfaceLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 브랜드 그라데이션 (CTA 버튼 등).
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 앱 전역 테마.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgTop,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      dividerColor: Colors.white10,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  /// 공통 카드 데코레이션.
  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// 얇은 보더의 패널 데코레이션.
  static BoxDecoration panelDecoration() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      );
}
