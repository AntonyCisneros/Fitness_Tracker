import 'package:flutter/material.dart';
import 'dart:ui';

/// Paleta de colores moderna y profesional
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF67E8F9);

  static const Color background = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color surfaceHover = Color(0xFF475569);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);

  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
}

/// Helpers responsive para diferentes tamaños de pantalla
class Responsive {
  Responsive._();

  static late double _screenWidth;
  static late double _screenHeight;
  static late double _textScale;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _textScale = mq.textScaler.scale(1.0);
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get textScale => _textScale;

  /// Porcentaje del ancho de pantalla
  static double w(double percent) => _screenWidth * (percent / 100);

  /// Porcentaje del alto de pantalla
  static double h(double percent) => _screenHeight * (percent / 100);

  /// Tamaño de fuente escalado
  static double sp(double size) => size * _textScale;

  /// Padding horizontal seguro (4% del ancho, mínimo 16)
  static double get safePaddingHorizontal => w(4).clamp(16.0, 32.0);

  /// Detecta pantallas muy altas (ratio > 2.0, como Redmi Note 14 20:9)
  static bool get isTallScreen => _screenHeight / _screenWidth > 2.0;

  /// Detecta pantallas pequeñas (ancho < 360)
  static bool get isSmallScreen => _screenWidth < 360;
}

/// Utilidades de diseño
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.backgroundLight,
          Color(0xFF172554),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  static BoxDecoration get cardGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.glassWhite,
          AppColors.glassWhite.withValues(alpha: 0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.glassBorder, width: 1),
    );
  }

  static BoxDecoration get primaryGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  static BoxDecoration get successGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.success, Color(0xFF059669)],
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  static BoxDecoration get dangerGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.danger, Color(0xFFDC2626)],
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  static List<BoxShadow> get softShadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> get glowShadow {
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

/// Widget reutilizable: Card con efecto glassmorphism
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius ?? 20),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: boxShadow ?? AppTheme.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Widget reutilizable: Botón con gradiente
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final BoxDecoration? gradient;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: gradient ?? AppTheme.primaryGradient,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable: Métrica con icono animado
class MetricBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isLarge;

  const MetricBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: isLarge ? 24 : 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: isLarge ? 18 : 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: isLarge ? 12 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget reutilizable: Indicador circular de progreso
class CircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? center;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.color = AppColors.primary,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.05)),
          ),
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          if (center != null)
            Center(child: center!),
        ],
      ),
    );
  }
}
