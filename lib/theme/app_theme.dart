/// App theme system: glass/iOS-style with animated
  gradients, presets, and custom colors.
  library app_theme;

  import 'dart:ui' show ImageFilter;
  import 'package:flutter/material.dart';
  import '../core/constants/app_constants.dart';

  /// A color theme preset with its own gradient stops and
  accent.
  class ColorThemePreset {
    final String id;
    final String name;
    final List<Color> gradientStops;
    final Color accent;
    final Color accentOnSurface;
    final Color surfaceTint;
    final Color glassTint;

    const ColorThemePreset({
      required this.id,
      required this.name,
      required this.gradientStops,
      required this.accent,
      required this.accentOnSurface,
      required this.surfaceTint,
      required this.glassTint,
    });

    Map<String, dynamic> toJson() => {
          'id': id,
          'name': name,
          'gradientStops': gradientStops.map((c) =>
  c.value).toList(),
          'accent': accent.value,
          'accentOnSurface': accentOnSurface.value,
          'surfaceTint': surfaceTint.value,
          'glassTint': glassTint.value,
        };

    static ColorThemePreset fromJson(Map<String, dynamic>
  json) =>
        ColorThemePreset(
          id: json['id'] as String,
          name: json['name'] as String,
          gradientStops: (json['gradientStops'] as
  List<dynamic>)
              .map((v) => Color(v as int))
              .toList(),
          accent: Color(json['accent'] as int),
          accentOnSurface: Color(json['accentOnSurface'] as
  int),
          surfaceTint: Color(json['surfaceTint'] as int),
          glassTint: Color(json['glassTint'] as int),
        );
  }

  /// Built-in theme presets (8+). Each has a unique aurora
  gradient.
  final List<ColorThemePreset> kBuiltInPresets = [
    ColorThemePreset(
      id: 'aurora',
      name: 'Aurora',
      gradientStops: [
        const Color(0xFF0f172a),
        const Color(0xFF1e1b4b),
        const Color(0xFF312e81),
        const Color(0xFF1e3a8a),
      ],
      accent: const Color(0xFF60a5fa),
      accentOnSurface: const Color(0xFF0f172a),
      surfaceTint: const Color(0xFF1e293b),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'sunset',
      name: 'Sunset',
      gradientStops: [
        const Color(0xFF450a0a),
        const Color(0xFF7f1d1d),
        const Color(0xFF9a3412),
        const Color(0xFFc2410c),
      ],
      accent: const Color(0xFFfb923c),
      accentOnSurface: const Color(0xFF450a0a),
      surfaceTint: const Color(0xFF7f1d1d),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'ocean',
      name: 'Ocean',
      gradientStops: [
        const Color(0xFF0c4a6e),
        const Color(0xFF0e7490),
        const Color(0xFF0891b2),
        const Color(0xFF06b6d4),
      ],
      accent: const Color(0xFF22d3ee),
      accentOnSurface: const Color(0xFF0c4a6e),
      surfaceTint: const Color(0xFF0e7490),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'forest',
      name: 'Forest',
      gradientStops: [
        const Color(0xFF052e16),
        const Color(0xFF14532d),
        const Color(0xFF166534),
        const Color(0xFF15803d),
      ],
      accent: const Color(0xFF4ade80),
      accentOnSurface: const Color(0xFF052e16),
      surfaceTint: const Color(0xFF14532d),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'violet',
      name: 'Violet',
      gradientStops: [
        const Color(0xFF2e1065),
        const Color(0xFF4c1d95),
        const Color(0xFF6b21a8),
        const Color(0xFF8b5cf6),
      ],
      accent: const Color(0xFFa78bfa),
      accentOnSurface: const Color(0xFF2e1065),
      surfaceTint: const Color(0xFF4c1d95),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'rose',
      name: 'Rose',
      gradientStops: [
        const Color(0xFF4c0519),
        const Color(0xFF881337),
        const Color(0xFFbe185d),
        const Color(0xFFe11d48),
      ],
      accent: const Color(0xFFfb7185),
      accentOnSurface: const Color(0xFF4c0519),
      surfaceTint: const Color(0xFF881337),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'amber',
      name: 'Amber',
      gradientStops: [
        const Color(0xFF451a03),
        const Color(0xFF78350f),
        const Color(0xFF92400e),
        const Color(0xFFb45309),
      ],
      accent: const Color(0xFFfbbf24),
      accentOnSurface: const Color(0xFF451a03),
      surfaceTint: const Color(0xFF78350f),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'slate',
      name: 'Slate',
      gradientStops: [
        const Color(0xFF0f172a),
        const Color(0xFF1e293b),
        const Color(0xFF334155),
        const Color(0xFF475569),
      ],
      accent: const Color(0xFF94a3b8),
      accentOnSurface: const Color(0xFF0f172a),
      surfaceTint: const Color(0xFF1e293b),
      glassTint: const Color(0x1Affffff),
    ),
  ];

  /// Theme mode (system/light/dark).
  enum AppThemeMode { system, light, dark }

  /// Complete app theme data.
  class AppThemeData {
    final AppThemeMode themeMode;
    final int presetIndex;
    final ColorThemePreset? customPreset;

    const AppThemeData({
      this.themeMode = AppThemeMode.system,
      this.presetIndex = 0,
      this.customPreset,
    });

    ColorThemePreset get activePreset {
      if (presetIndex >= 0 && presetIndex <
  kBuiltInPresets.length) {
        return kBuiltInPresets[presetIndex];
      }
      return customPreset ?? kBuiltInPresets[0];
    }

    Map<String, dynamic> toJson() => {
          'themeMode': themeMode.index,
          'presetIndex': presetIndex,
          'customPreset': customPreset?.toJson(),
        };

    static AppThemeData fromJson(Map<String, dynamic> json)
  => AppThemeData(
          themeMode: AppThemeMode.values[json['themeMode']
  as int? ?? 0],
          presetIndex: json['presetIndex'] as int? ?? 0,
          customPreset: json['customPreset'] != null
              ?
  ColorThemePreset.fromJson(json['customPreset'] as
  Map<String, dynamic>)
              : null,
        );
  }

  /// Builds the full ThemeData from active preset + mode.
  ThemeData buildAppTheme(AppThemeData themeData) {
    final preset = themeData.activePreset;
    final isDark = themeData.themeMode == AppThemeMode.dark
  ||
        (themeData.themeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.plat
  formBrightness ==
                Brightness.dark);
    final base = isDark ? ThemeData.dark() :
  ThemeData.light();

    final surfaceColor = isDark
        ? preset.surfaceTint.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.7);
    final cardColor = isDark
        ? preset.surfaceTint.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.5);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: preset.accent,
        onPrimary: preset.accentOnSurface,
        secondary: preset.accent,
        onSecondary: preset.accentOnSurface,
        surface: surfaceColor,
        onSurface: isDark ? Colors.white : Colors.black,
        surfaceContainerHighest: cardColor,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: cardColor,
      canvasColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        headlineLarge:
  base.textTheme.headlineLarge?.copyWith(
        headlineMedium:
  base.textTheme.headlineMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: (isDark ? Colors.white :
  Colors.black).withValues(alpha: 0.8),
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: preset.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white :
  Colors.black,
        titleTextStyle:
  base.textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black,               fontWeight: FontWeight.w600,
        ),                                                       ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: BorderRadius.circular(16),
        margin: const EdgeInsets.symmetric(horizontal: 16,
  vertical: 8),                                                  ),
      inputDecorationTheme:/inputDecorationTheme: null,  //
  placeholder removed
    );
  }
