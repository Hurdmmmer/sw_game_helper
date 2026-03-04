import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 全局主题：中文优先、桌面工具风（非游戏风）。
class AppTheme {
  AppTheme._();

  static const String _baseFontFamily = 'Microsoft YaHei UI';

  static const List<String> _fontFallback = [
    'Microsoft YaHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'sans-serif',
  ];

  static const _baseLineHeight = 1.35;

  static TextStyle _textStyle({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = _baseLineHeight,
  }) {
    return TextStyle(
      fontFamily: _baseFontFamily,
      fontFamilyFallback: _fontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: _textStyle(size: 34, weight: FontWeight.w700, color: scheme.onSurface, height: 1.2),
      displayMedium: _textStyle(size: 30, weight: FontWeight.w700, color: scheme.onSurface, height: 1.2),
      displaySmall: _textStyle(size: 26, weight: FontWeight.w700, color: scheme.onSurface, height: 1.25),
      headlineLarge: _textStyle(size: 24, weight: FontWeight.w700, color: scheme.onSurface, height: 1.25),
      headlineMedium: _textStyle(size: 22, weight: FontWeight.w700, color: scheme.onSurface, height: 1.25),
      headlineSmall: _textStyle(size: 20, weight: FontWeight.w600, color: scheme.onSurface, height: 1.25),
      titleLarge: _textStyle(size: 18, weight: FontWeight.w600, color: scheme.onSurface, height: 1.3),
      titleMedium: _textStyle(size: 16, weight: FontWeight.w600, color: scheme.onSurface, height: 1.3),
      titleSmall: _textStyle(size: 14, weight: FontWeight.w600, color: scheme.onSurfaceVariant, height: 1.3),
      bodyLarge: _textStyle(size: 16, weight: FontWeight.w400, color: scheme.onSurface),
      bodyMedium: _textStyle(size: 14, weight: FontWeight.w400, color: scheme.onSurfaceVariant),
      bodySmall: _textStyle(size: 12, weight: FontWeight.w400, color: scheme.onSurfaceVariant),
      labelLarge: _textStyle(size: 14, weight: FontWeight.w600, color: scheme.onSurface, height: 1.25),
      labelMedium: _textStyle(size: 12, weight: FontWeight.w600, color: scheme.onSurfaceVariant, height: 1.25),
      labelSmall: _textStyle(size: 11, weight: FontWeight.w500, color: scheme.onSurfaceVariant, height: 1.2),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffold,
  }) {
    final textTheme = _buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: _baseFontFamily,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: textTheme.labelLarge,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.88);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.94);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant;
            }
            return scheme.onPrimary;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 4,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: _textStyle(
          size: 14,
          weight: FontWeight.w500,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        deleteIconColor: scheme.onSurfaceVariant,
        disabledColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.tertiaryContainer,
        labelStyle: textTheme.bodyMedium!,
        secondaryLabelStyle: textTheme.bodyMedium!.copyWith(color: scheme.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const brightness = Brightness.light;
    final scheme = const ColorScheme(
      brightness: brightness,
      primary: Color(0xFF2563EB),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: Color(0xFF0EA5E9),
      onSecondary: Color(0xFF082F49),
      secondaryContainer: Color(0xFFE0F2FE),
      onSecondaryContainer: Color(0xFF0C4A6E),
      tertiary: Color(0xFF059669),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD1FAE5),
      onTertiaryContainer: Color(0xFF065F46),
      error: Color(0xFFB91C1C),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      surfaceContainerHighest: Color(0xFFEFF3F8),
      surfaceContainerHigh: Color(0xFFF7FAFD),
      surfaceContainerLow: Color(0xFFFCFDFE),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Color(0x1F000000),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFF0F172A),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF60A5FA),
    );

    return _buildTheme(scheme: scheme, scaffold: const Color(0xFFF7FAFD));
  }

  static ThemeData get darkTheme {
    const brightness = Brightness.dark;
    final scheme = const ColorScheme(
      brightness: brightness,
      primary: Color(0xFF60A5FA),
      onPrimary: Color(0xFF0B1220),
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: Color(0xFF38BDF8),
      onSecondary: Color(0xFF082F49),
      secondaryContainer: Color(0xFF0C4A6E),
      onSecondaryContainer: Color(0xFFE0F2FE),
      tertiary: Color(0xFF34D399),
      onTertiary: Color(0xFF052E2B),
      tertiaryContainer: Color(0xFF065F46),
      onTertiaryContainer: Color(0xFFD1FAE5),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFECACA),
      surface: Color(0xFF111827),
      onSurface: Color(0xFFE5E7EB),
      surfaceContainerHighest: Color(0xFF1F2937),
      surfaceContainerHigh: Color(0xFF273449),
      surfaceContainerLow: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF263345),
      shadow: Color(0x66000000),
      scrim: Color(0xB3000000),
      inverseSurface: Color(0xFFF8FAFC),
      onInverseSurface: Color(0xFF111827),
      inversePrimary: Color(0xFF2563EB),
    );

    return _buildTheme(scheme: scheme, scaffold: const Color(0xFF0B1220));
  }
}
