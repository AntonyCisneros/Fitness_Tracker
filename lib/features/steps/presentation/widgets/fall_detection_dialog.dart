import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FallDetectionDialog extends StatefulWidget {
  const FallDetectionDialog({super.key});

  @override
  State<FallDetectionDialog> createState() => _FallDetectionDialogState();
}

class _FallDetectionDialogState extends State<FallDetectionDialog>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _warningShown = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 5 && !_warningShown) {
        _warningShown = true;
      }
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = _secondsRemaining <= 5;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCritical
                  ? [
                      const Color(0xFF7C2D12),
                      const Color(0xFF451A03),
                    ]
                  : [
                      AppColors.surface,
                      AppColors.backgroundLight,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCritical
                  ? AppColors.danger.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCritical
                    ? AppColors.danger.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono pulsante
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isCritical
                            ? AppColors.danger.withValues(alpha: 0.2)
                            : AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isCritical ? AppColors.danger : AppColors.warning)
                                .withValues(alpha: 0.2 + _pulseController.value * 0.3),
                            blurRadius: 20,
                            spreadRadius: 4 + _pulseController.value * 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: isCritical ? AppColors.dangerLight : AppColors.warningLight,
                        size: 36,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  '¿Estás bien?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isCritical ? AppColors.dangerLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se ha detectado una posible caída.\nPor favor confirma que te encuentras bien.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _secondsRemaining / 15,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCritical ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_secondsRemaining}s restantes',
                  style: TextStyle(
                    color: isCritical ? AppColors.dangerLight : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                if (_warningShown) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emergency, color: AppColors.dangerLight, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tiempo crítico. Si no respondes, se activará alerta de emergencia.',
                            style: TextStyle(
                              color: AppColors.dangerLight.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: AppTheme.successGradient,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Estoy bien',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
