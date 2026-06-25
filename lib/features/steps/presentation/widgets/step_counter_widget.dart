import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/datasources/accelerometer_datasource.dart';
import '../../../auth/domain/entities/step_data.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'fall_detection_dialog.dart';

class StepCounterWidget extends StatefulWidget {
  final void Function(int stepCount, String activityType, double estimatedCalories)? onStop;

  const StepCounterWidget({super.key, this.onStop});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget>
    with TickerProviderStateMixin {
  final AccelerometerDataSource _dataSource = AccelerometerDataSourceImpl();
  final TtsService _tts = TtsService();

  StreamSubscription<StepData>? _subscription;
  StepData? _currentData;
  bool _isTracking = false;

  static const _stabilityDuration = Duration(milliseconds: 2500);
  ActivityType? _pendingActivity;
  ActivityType? _announcedActivity;
  Timer? _stabilityTimer;

  bool _isShowingFallDialog = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _tts.init();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stabilityTimer?.cancel();
    _pulseController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() async {
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        _showSnack('Permisos de sensores denegados', isError: true);
      }
      return;
    }

    await _dataSource.startCounting();
    _tts.reset();
    _announcedActivity = null;
    _pendingActivity = null;
    _pulseController.repeat(reverse: true);

    _subscription = _dataSource.stepStream.listen(
      (data) {
        if (!mounted) return;
        setState(() => _currentData = data);
        _handleActivityChange(data.activityType);
        _handleFallDetection(data);
      },
      onError: (error) {
        if (mounted) _showSnack('Error sensor: $error', isError: true);
      },
    );

    setState(() => _isTracking = true);
  }

  void _stopTracking() async {
    await _dataSource.stopCounting();
    _subscription?.cancel();
    _stabilityTimer?.cancel();
    _pulseController.stop();

    if (_currentData != null && widget.onStop != null) {
      widget.onStop!(
        _currentData!.stepCount,
        _getActivityLabel(_currentData!.activityType),
        _currentData!.estimatedCalories,
      );
    }

    setState(() => _isTracking = false);
  }

  void _handleActivityChange(ActivityType currentActivity) {
    if (_pendingActivity != currentActivity) {
      _stabilityTimer?.cancel();
      _pendingActivity = currentActivity;
      _stabilityTimer = Timer(_stabilityDuration, () {
        if (_pendingActivity == currentActivity &&
            _announcedActivity != currentActivity) {
          _announcedActivity = currentActivity;
          _announceActivity(currentActivity);
        }
      });
    }
  }

  void _announceActivity(ActivityType activity) {
    switch (activity) {
      case ActivityType.walking:
        _tts.speak('Estás caminando');
        break;
      case ActivityType.running:
        _tts.speak('Estás corriendo');
        break;
      case ActivityType.stationary:
        _tts.speak('Te has detenido');
        break;
    }
  }

  void _handleFallDetection(StepData data) {
    if (data.fallDetected && !_isShowingFallDialog) {
      _isShowingFallDialog = true;
      _tts.speakAlert('Atención, posible caída detectada. ¿Estás bien?');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const FallDetectionDialog(),
      ).then((_) => _isShowingFallDialog = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final stepCount = _currentData?.stepCount ?? 0;
    final calories = _currentData?.estimatedCalories ?? 0.0;
    final activityType = _currentData?.activityType;
    final goal = 10000;
    final progress = (stepCount / goal).clamp(0.0, 1.0);

    final circleSize = Responsive.w(42).clamp(140.0, 190.0);
    final strokeWidth = Responsive.w(2.8).clamp(8.0, 14.0);

    return GlassCard(
      padding: EdgeInsets.all(Responsive.w(5).clamp(16, 24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.w(2).clamp(6, 10)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_walk,
                      color: AppColors.primaryLight,
                      size: Responsive.w(5).clamp(18, 24),
                    ),
                  ),
                  SizedBox(width: Responsive.w(2.5).clamp(8, 14)),
                  Text(
                    'Contador de Pasos',
                    style: TextStyle(
                      fontSize: Responsive.sp(16).clamp(14, 19),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildTrackButton(),
            ],
          ),
          SizedBox(height: Responsive.h(2.5).clamp(16, 28)),

          // Indicador circular proporcional
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: strokeWidth,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.surfaceLight.withValues(alpha: 0.5),
                  ),
                ),
              ),
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$stepCount',
                    style: TextStyle(
                      fontSize: Responsive.sp(36).clamp(28, 46),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'de $goal pasos',
                    style: TextStyle(
                      fontSize: Responsive.sp(12).clamp(11, 14),
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: Responsive.h(2.5).clamp(16, 28)),

          // Métricas con Wrap para evitar overflow en pantallas estrechas
          Wrap(
            spacing: Responsive.w(2).clamp(8, 16),
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              MetricBadge(
                icon: _getActivityIcon(activityType),
                value: _getActivityLabel(activityType),
                label: 'Actividad',
                color: _getActivityColor(activityType),
                isLarge: true,
              ),
              MetricBadge(
                icon: Icons.local_fire_department,
                value: calories.toStringAsFixed(1),
                label: 'Calorías',
                color: AppColors.warning,
                isLarge: true,
              ),
              MetricBadge(
                icon: Icons.speed,
                value: (_currentData?.magnitude ?? 0).toStringAsFixed(1),
                label: 'Magnitud',
                color: AppColors.accent,
                isLarge: true,
              ),
            ],
          ),

          if (_isTracking) ...[
            SizedBox(height: Responsive.h(1.8).clamp(12, 18)),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                      alpha: 0.1 + _pulseController.value * 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Rastreando...',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackButton() {
    return GestureDetector(
      onTap: _toggleTracking,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(3.5).clamp(12, 18),
          vertical: Responsive.w(2.2).clamp(8, 12),
        ),
        decoration: BoxDecoration(
          gradient: _isTracking
              ? const LinearGradient(
                  colors: [AppColors.danger, Color(0xFFDC2626)],
                )
              : const LinearGradient(
                  colors: [AppColors.success, Color(0xFF059669)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_isTracking ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: Responsive.w(4).clamp(16, 20),
            ),
            const SizedBox(width: 6),
            Text(
              _isTracking ? 'Detener' : 'Iniciar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: Responsive.sp(12).clamp(11, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.stationary:
        return Icons.accessibility_new;
      default:
        return Icons.help_outline;
    }
  }

  String _getActivityLabel(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return 'Caminando';
      case ActivityType.running:
        return 'Corriendo';
      case ActivityType.stationary:
        return 'Quieto';
      default:
        return 'Detectando...';
    }
  }

  Color _getActivityColor(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return AppColors.primary;
      case ActivityType.running:
        return AppColors.warning;
      case ActivityType.stationary:
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }
}
