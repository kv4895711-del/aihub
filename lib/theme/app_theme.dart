 /// App theme system: glass/iOS-style with animated
  gradients, presets, and custom colors.                     library app_theme;

  import 'dart:ui' show ImageFilter;                         import 'package:flutter/material.dart';
  import '../core/constants/app_constants.dart';           
  /// A color theme preset with its own gradient stops and
  accent.                                                    class ColorThemePreset {
    final String id;                                           final String name;
    final List<Color> gradientStops;
    final Color accent;                                        final Color accentOnSurface;
    final Color surfaceTint;
    final Color glassTint;                                 
    const ColorThemePreset({
      required this.id,
      required this.name,                                        required this.gradientStops,
      required this.accent,
      required this.accentOnSurface,
      required this.surfaceTint,                                 required this.glassTint,
    });
                                                               Map<String, dynamic> toJson() => {
          'id': id,
          'name': name,                                              'gradientStops': gradientStops.map((c) =>
  c.value).toList(),
          'accent': accent.value,
          'accentOnSurface': accentOnSurface.value,                  'surfaceTint': surfaceTint.value,
          'glassTint': glassTint.value,
        };

    static ColorThemePreset fromJson(Map<String, dynamic>    json) =>
        ColorThemePreset(                                            id: json['id'] as String,
          name: json['name'] as String,
          gradientStops: (json['gradientStops'] as
  List<dynamic>)
              .map((v) => Color(v as int))                               .toList(),
          accent: Color(json['accent'] as int),                      accentOnSurface: Color(json['accentOnSurface'] as
  int),
          surfaceTint: Color(json['surfaceTint'] as int),            glassTint: Color(json['glassTint'] as int),
        );                                                   }
                                                             /// Built-in theme presets (8+). Each has a unique aurora
  gradient.
  final List<ColorThemePreset> kBuiltInPresets = [
    ColorThemePreset(                                            id: 'aurora',
      name: 'Aurora',
      gradientStops: [                                             const Color(0xFF0f172a),
        const Color(0xFF1e1b4b),                                   const Color(0xFF312e81),
        const Color(0xFF1e3a8a),                                 ],
      accent: const Color(0xFF60a5fa),
      accentOnSurface: const Color(0xFF0f172a),                  surfaceTint: const Color(0xFF1e293b),
      glassTint: const Color(0x1Affffff),                      ),
    ColorThemePreset(                                            id: 'sunset',
      name: 'Sunset',                                            gradientStops: [
        const Color(0xFF450a0a),                                   const Color(0xFF7f1d1d),
        const Color(0xFF9a3412),                                   const Color(0xFFc2410c),
      ],                                                         accent: const Color(0xFFfb923c),
      accentOnSurface: const Color(0xFF450a0a),                  surfaceTint: const Color(0xFF7f1d1d),
      glassTint: const Color(0x1Affffff),
    ),                                                         ColorThemePreset(
      id: 'ocean',                                               name: 'Ocean',
      gradientStops: [                                             const Color(0xFF0c4a6e),
        const Color(0xFF0e7490),                                   const Color(0xFF0891b2),
        const Color(0xFF06b6d4),                                 ],
      accent: const Color(0xFF22d3ee),                           accentOnSurface: const Color(0xFF0c4a6e),
      surfaceTint: const Color(0xFF0e7490),                      glassTint: const Color(0x1Affffff),
    ),                                                         ColorThemePreset(
      id: 'forest',
      name: 'Forest',                                            gradientStops: [
        const Color(0xFF052e16),                                   const Color(0xFF14532d),
        const Color(0xFF166534),
        const Color(0xFF15803d),
      ],
      accent: const Color(0xFF4ade80),                           accentOnSurface: const Color(0xFF052e16),
      surfaceTint: const Color(0xFF14532d),
      glassTint: const Color(0x1Affffff),                      ),
    ColorThemePreset(                                            id: 'violet',
      name: 'Violet',                                            gradientStops: [
        const Color(0xFF2e1065),                                   const Color(0xFF4c1d95),
        const Color(0xFF6b21a8),
        const Color(0xFF8b5cf6),                                 ],
      accent: const Color(0xFFa78bfa),
      accentOnSurface: const Color(0xFF2e1065),                  surfaceTint: const Color(0xFF4c1d95),
      glassTint: const Color(0x1Affffff),
    ),                                                         ColorThemePreset(
      id: 'rose',                                                name: 'Rose',
      gradientStops: [                                             const Color(0xFF4c0519),
        const Color(0xFF881337),                                   const Color(0xFFbe185d),
        const Color(0xFFe11d48),
      ],                                                         accent: const Color(0xFFfb7185),
      accentOnSurface: const Color(0xFF4c0519),
      surfaceTint: const Color(0xFF881337),
      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(
      id: 'amber',
      name: 'Amber',
      gradientStops: [
        const Color(0xFF451a03),                                   const Color(0xFF78350f),
        const Color(0xFF92400e),                                   const Color(0xFFb45309),
      ],
      accent: const Color(0xFFfbbf24),
      accentOnSurface: const Color(0xFF451a03),
      surfaceTint: const Color(0xFF78350f),                      glassTint: const Color(0x1Affffff),
    ),
    ColorThemePreset(                                            id: 'slate',
      name: 'Slate',                                             gradientStops: [
        const Color(0xFF0f172a),
        const Color(0xFF1e293b),                                   const Color(0xFF334155),
        const Color(0xFF475569),                                 ],
      accent: const Color(0xFF94a3b8),                           accentOnSurface: const Color(0xFF0f172a),
      surfaceTint: const Color(0xFF1e293b),                      glassTint: const Color(0x1Affffff),
    ),                                                       ];
                                                             /// Theme mode (system/light/dark).
  enum AppThemeMode { system, light, dark }

  /// Complete app theme data.
  class AppThemeData {                                         final AppThemeMode themeMode;
    final int presetIndex;
    final ColorThemePreset? customPreset;                  
    const AppThemeData({                                         this.themeMode = AppThemeMode.system,
      this.presetIndex = 0,
      this.customPreset,                                       });
                                                               ColorThemePreset get activePreset {
      if (presetIndex >= 0 && presetIndex <
  kBuiltInPresets.length) {                                        return kBuiltInPresets[presetIndex];
      }
      return customPreset ?? kBuiltInPresets[0];               }

    Map<String, dynamic> toJson() => {
          'themeMode': themeMode.index,                              'presetIndex': presetIndex,
          'customPreset': customPreset?.toJson(),
        };
                                                               static AppThemeData fromJson(Map<String, dynamic> json)
  => AppThemeData(
          themeMode: AppThemeMode.values[json['themeMode']   as int? ?? 0],
          presetIndex: json['presetIndex'] as int? ?? 0,
          customPreset: json['customPreset'] != null                     ?
  ColorThemePreset.fromJson(json['customPreset'] as
  Map<String, dynamic>)
              : null,                                              );
  }

  /// Builds the full ThemeData from active preset + mode.
  ThemeData buildAppTheme(AppThemeData themeData) {            final preset = themeData.activePreset;
    final isDark = themeData.themeMode == AppThemeMode.dark  ||
        (themeData.themeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.plat
  formBrightness ==
                Brightness.dark);                              final base = isDark ? ThemeData.dark() :
  ThemeData.light();                                       
    final surfaceColor = isDark
        ? preset.surfaceTint.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.7);                 final cardColor = isDark
        ? preset.surfaceTint.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.5);             
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(                      primary: preset.accent,
        onPrimary: preset.accentOnSurface,
        secondary: preset.accent,
        onSecondary: preset.accentOnSurface,                       surface: surfaceColor,
        onSurface: isDark ? Colors.white : Colors.black,
        surfaceContainerHighest: cardColor,                      ),
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: cardColor,
      canvasColor: Colors.transparent,                           textTheme: base.textTheme.copyWith(
        headlineLarge:
  base.textTheme.headlineLarge?.copyWith(                            color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w700,                             ),
        headlineMedium:                                      base.textTheme.headlineMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black,               fontWeight: FontWeight.w600,
        ),                                                         titleLarge: base.textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black,               fontWeight: FontWeight.w600,
        ),                                                         bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black,             ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(             color: (isDark ? Colors.white :
  Colors.black).withValues(alpha: 0.8),                            ),
        labelLarge: base.textTheme.labelLarge?.copyWith(             color: preset.accent,
          fontWeight: FontWeight.w600,                             ),
      ),                                                         appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,                       elevation: 0,
        surfaceTintColor: Colors.transparent,                      foregroundColor: isDark ? Colors.white :
  Colors.black,                                                    titleTextStyle:
  base.textTheme.titleLarge?.copyWith(                               color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,                             ),
      ),                                                         cardTheme: CardThemeData(
        color: cardColor,                                          elevation: 0,
        surfaceTintColor: Colors.transparent,                      shape: BorderRadius.circular(16),
        margin: const EdgeInsets.symmetric(horizontal: 16,   vertical: 8),
      ),                                                         inputDecorationTheme:/inputDecorationTheme: null,
    );                                                       }

  /// Animated gradient background widget (aurora style).
  class AnimatedGradientBackground extends StatefulWidget {
    final AppThemeData themeData;
    final Widget child;                                    
    const AnimatedGradientBackground({
      super.key,
      required this.themeData,
      required this.child,
    });

    @override                                                  State<AnimatedGradientBackground> createState() =>
        _AnimatedGradientBackgroundState();
  }

  class _AnimatedGradientBackgroundState extends
  State<AnimatedGradientBackground>
      with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _anim1;
    late Animation<double> _anim2;                             late Animation<double> _anim3;
                                                               @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(seconds: 20),
        vsync: this,
      )..repeat(reverse: true);

      _anim1 = Tween<double>(begin: -0.5, end:
  1.5).animate(                                                    CurvedAnimation(parent: _controller, curve: const
  Interval(0.0, 1.0)),                                           );
      _anim2 = Tween<double>(begin: -0.3, end:
  1.3).animate(
        CurvedAnimation(parent: _controller, curve: const
  Interval(0.2, 1.0)),
      );
      _anim3 = Tween<double>(begin: -0.1, end:
  1.1).animate(                                                    CurvedAnimation(parent: _controller, curve: const
  Interval(0.4, 1.0)),
      );                                                       }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final preset = widget.themeData.activePreset;
      final stops = preset.gradientStops;

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  0.0 + _anim1.value * 0.1,
                  0.3 + _anim2.value * 0.1,
                  0.6 + _anim3.value * 0.1,
                  1.0,
                ].map((s) => s.clamp(0.0, 1.0)).toList(),
                colors: stops,
              ),
            ),
            child: widget.child,
          );
        },
      );
    }                                                        }

  /// Glass container with blur.                             class GlassContainer extends StatelessWidget {
    final Widget child;
    final EdgeInsetsGeometry? padding;
    final EdgeInsetsGeometry? margin;
    final double borderRadius;
    final double blur;
    final Color? borderColor;
    final double borderWidth;                              
    const GlassContainer({
      super.key,
      required this.child,                                       this.padding,
      this.margin,                                               this.borderRadius = 16,
      this.blur = 20,                                            this.borderColor,
      this.borderWidth = 0.5,
    });                                                    
    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness ==         Brightness.dark;
      return ClipRRect(                                            borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(                                       filter: ImageFilter.blur(sigmaX: blur, sigmaY:
  blur),                                                             child: Container(
            padding: padding,                                          margin: margin,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.5),                 borderRadius:
  BorderRadius.circular(borderRadius),                                   border: Border.all(                                          color: borderColor ??
                    Colors.white.withValues(alpha: isDark ?  0.15 : 0.2),                                                             width: borderWidth,
              ),                                                         boxShadow: [
                BoxShadow(                                                   color: Colors.black.withValues(alpha:
  isDark ? 0.3 : 0.08),                                                      blurRadius: 20,
                  offset: const Offset(0, 8),                              ),
                BoxShadow(
                  color: Colors.black.withValues(alpha:
  isDark ? 0.1 : 0.03),                                                      blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],                                                       ),                                                         child: child,
          ),
        ),
      );
    }
  }                                                        
  /// Glass pill (for status indicators, chips).
  class GlassPill extends StatelessWidget {
    final Widget child;
    final EdgeInsetsGeometry padding;
    final Color? backgroundColor;                              final Color? borderColor;
    final double blur;

    const GlassPill({
      super.key,
      required this.child,                                       this.padding = const EdgeInsets.symmetric(horizontal:
  12, vertical: 6),
      this.backgroundColor,
      this.borderColor,
      this.blur = 15,
    });                                                    
    @override
    Widget build(BuildContext context) {                         final isDark = Theme.of(context).brightness ==
  Brightness.dark;                                               return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(                                       filter: ImageFilter.blur(sigmaX: blur, sigmaY:
  blur),
          child: Container(                                            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ??                                      (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha:       0.05)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ??                                          Colors.white.withValues(alpha: isDark ?
  0.15 : 0.1),
                width: 0.5,                                              ),
              child: child,                                            ),
          ),
        ),
      );
    }
  }                                                        
  /// Animated status pill widget.                           class StatusPill extends StatefulWidget {
    final String text;
    final Color color;
    final/icons? icon;

    const StatusPill({                                           super.key,
      required this.text,
      required this.color,
      this.icon,
    });
                                                               @override
    State<StatusPill> createState() => _StatusPillState();
  }                                                        
  class _StatusPillState extends State<StatusPill>
      with SingleTickerProviderStateMixin {                    late AnimationController _pulseController;
    late Animation<double> _pulseAnim;

    @override
    void initState() {
      super.initState();
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),              vsync: this,
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.6, end:            1.0).animate(
        CurvedAnimation(parent: _pulseController, curve:     Curves.easeInOut),
      );                                                       }
                                                               @override
    void dispose() {
      _pulseController.dispose();
      super.dispose();
    }
                                                               @override
    Widget build(BuildContext context) {                         return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) {
          return GlassPill(                                            backgroundColor: widget.color.withValues(alpha:
  0.15 * _pulseAnim.value),
            borderColor: widget.color.withValues(alpha: 0.5
  * _pulseAnim.value),
            child: Row(
              mainAxisSize: MainAxisSize.min,                            children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 12, color:
  widget.color),                                                             const SizedBox(width: 6),
                ],
                Text(
                  widget.text,                                               style: TextStyle(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  /// Shimmer loading placeholder.
  class ShimmerLoader extends StatefulWidget {
    final double width;
    final double height;
    final BorderRadius? borderRadius;

    const ShimmerLoader({
      super.key,
      required this.width,
      required this.height,
      this.borderRadius,
    });

    @override
    State<ShimmerLoader> createState() =>                    _ShimmerLoaderState();
  }                                                        
  class _ShimmerLoaderState extends State<ShimmerLoader>         with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _animation;                     
    @override                                                  void initState() {
      super.initState();                                         _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),              vsync: this,
      )..repeat();
      _animation = Tween<double>(begin: -1.0, end:
  2.0).animate(                                                    CurvedAnimation(parent: _controller, curve:
  Curves.easeInOut),                                             );
    }

    @override                                                  void dispose() {
      _controller.dispose();
      super.dispose();
    }                                                      
    @override                                                  Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;
      final baseColor = isDark                                       ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.05);                final highlightColor = isDark
          ? Colors.white.withValues(alpha: 0.2)                      : Colors.black.withValues(alpha: 0.1);

      return AnimatedBuilder(                                      animation: _animation,
        builder: (context, _) {                                      return Container(
            width: widget.width,                                       height: widget.height,
            decoration: BoxDecoration(                                   borderRadius: widget.borderRadius ??
  BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,                               end: Alignment.centerRight,
                colors: [baseColor, highlightColor,
  baseColor],
                stops: [                                                     (_animation.value - 0.3).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),                          (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),                                                       );
        },
      );                                                       }
  }

  /// Typing indicator (three bouncing dots).
  class TypingIndicator extends StatefulWidget {               final Color? color;
    final double dotSize;                                  
    const TypingIndicator({                                      super.key,
      this.color,                                                this.dotSize = 8,
    });

    @override
    State<TypingIndicator> createState() =>
  _TypingIndicatorState();                                   }

  class _TypingIndicatorState extends
  State<TypingIndicator>                                         with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    @override
    void initState() {                                           super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
    }                                                      
    @override
    void dispose() {
      _controller.dispose();
      super.dispose();                                         }
                                                               @override
    Widget build(BuildContext context) {
      final color = widget.color ??
  Theme.of(context).colorScheme.primary;
      return SizedBox(
        height: widget.dotSize + 4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final delay = index * 0.15;
                final value = (_controller.value - delay) %
  1.0;
                final scale = 0.5 + 0.5 *
  Curves.easeInOut.transform(value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const
  EdgeInsets.symmetric(horizontal: 3),
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,                                  ),
                  ),
                );
              },
            );
          }),
        ),
      );
    }
  }
