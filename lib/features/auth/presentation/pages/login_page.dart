import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const LoginPage({super.key, required this.onAuthSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fondo gradiente
          Container(decoration: AppTheme.gradientBackground),

          // 2. Glassmorphism que cubre TODA la pantalla
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: AppColors.glassWhite.withValues(alpha: 0.08),
              ),
            ),
          ),

          // 3. Contenido centrado y scrollable
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.safePaddingHorizontal,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height * 0.7,
                    maxWidth: 480,
                  ),
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is AuthSuccess) {
                        widget.onAuthSuccess();
                      } else if (state is AuthFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo animado
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: Responsive.w(28).clamp(90, 130),
                                height: Responsive.w(28).clamp(90, 130),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: Responsive.w(12).clamp(36, 56),
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.h(4).clamp(28, 48)),

                            // Título
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  children: [
                                    Text(
                                      'Fitness Tracker',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: Responsive.sp(32).clamp(26, 38),
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.h(1.2).clamp(8, 14)),
                                    Text(
                                      'Tu compañero de entrenamiento inteligente',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: Responsive.sp(15).clamp(13, 17),
                                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.h(8).clamp(40, 80)),

                            // Botón de autenticación
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: state is AuthLoading
                                  ? Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassWhite,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.glassBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: const CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        GradientButton(
                                          text: 'Autenticar con Biometría',
                                          icon: Icons.fingerprint,
                                          onPressed: () {
                                            context.read<AuthBloc>().add(AuthenticateRequested());
                                          },
                                        ),
                                        SizedBox(height: Responsive.h(2.5).clamp(16, 24)),
                                        Text(
                                          'Usa tu huella dactilar o reconocimiento facial',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: Responsive.sp(12).clamp(11, 14),
                                            color: AppColors.textMuted.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            SizedBox(height: Responsive.h(4).clamp(24, 48)),

                            // Footer
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Seguro y privado',
                                style: TextStyle(
                                  fontSize: Responsive.sp(11).clamp(10, 12),
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
