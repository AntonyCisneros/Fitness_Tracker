import 'package:flutter/material.dart' hide Route;
import 'dart:async';
import '../../data/datasources/gps_datasource.dart';
import '../../domain/entities/location_point.dart';
import '../../../../core/theme/app_theme.dart';

class RouteMapWidget extends StatefulWidget {
  final void Function(double distanceKm, int durationMinutes, double estimatedCalories)? onStop;

  const RouteMapWidget({super.key, this.onStop});

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget>
    with TickerProviderStateMixin {
  final GpsDataSource _dataSource = GpsDataSourceImpl();
  final Route _route = Route();

  StreamSubscription<LocationPoint>? _subscription;
  bool _isTracking = false;
  String _statusMessage = 'Presiona Iniciar para comenzar';

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      setState(() => _statusMessage = 'Permisos de ubicación denegados');
      return;
    }

    final gpsEnabled = await _dataSource.isGpsEnabled();
    if (!gpsEnabled) {
      setState(() => _statusMessage = 'Activa el GPS para continuar');
      return;
    }

    _subscription = _dataSource.locationStream.listen(
      (point) {
        if (_route.points.isEmpty) {
          setState(() {
            _route.addPoint(point);
            _statusMessage = '${_route.points.length} puntos registrados';
          });
        } else {
          final lastPoint = _route.points.last;
          final distance = lastPoint.distanceTo(point);
          if (distance >= 1) {
            setState(() {
              _route.addPoint(point);
              _statusMessage = '${_route.points.length} puntos registrados';
            });
          }
        }
      },
      onError: (error) {
        setState(() => _statusMessage = 'Error: $error');
      },
    );

    _pulseController.repeat(reverse: true);
    setState(() => _isTracking = true);
  }

  void _stopTracking() {
    _subscription?.cancel();
    _route.finish();
    _pulseController.stop();

    if (widget.onStop != null) {
      widget.onStop!(
        _route.distanceKm,
        _route.duration.inMinutes,
        _route.estimatedCalories,
      );
    }

    setState(() {
      _isTracking = false;
      _statusMessage = 'Ruta finalizada · ${_route.distanceKm.toStringAsFixed(2)} km';
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final mapHeight = Responsive.h(24).clamp(160.0, 240.0);

    return GlassCard(
      padding: EdgeInsets.all(Responsive.w(5).clamp(16, 22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.w(2).clamp(6, 10)),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.map,
                      color: AppColors.accent,
                      size: Responsive.w(5).clamp(18, 24),
                    ),
                  ),
                  SizedBox(width: Responsive.w(2.5).clamp(8, 14)),
                  Text(
                    'Ruta GPS',
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
          SizedBox(height: Responsive.h(1.2).clamp(8, 14)),
          Row(
            children: [
              if (_isTracking)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(
                              alpha: 0.3 + _pulseController.value * 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isTracking ? AppColors.success : AppColors.textMuted,
                    fontSize: Responsive.sp(11).clamp(10, 13),
                    fontWeight: _isTracking ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(1.8).clamp(12, 18)),

          // Canvas del mapa con altura proporcional
          Container(
            height: mapHeight,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: RoutePainter(route: _route, isTracking: _isTracking),
                size: Size.infinite,
              ),
            ),
          ),

          SizedBox(height: Responsive.h(2).clamp(14, 20)),

          // Métricas con Wrap para evitar overflow
          Container(
            padding: EdgeInsets.symmetric(
              vertical: Responsive.h(1.8).clamp(12, 18),
              horizontal: Responsive.w(2).clamp(8, 14),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(
                  icon: Icons.straighten,
                  value: _route.distanceKm.toStringAsFixed(2),
                  unit: 'km',
                  label: 'Distancia',
                ),
                _buildDivider(),
                _buildMetric(
                  icon: Icons.timer,
                  value: _formatDuration(_route.duration),
                  unit: '',
                  label: 'Tiempo',
                ),
                _buildDivider(),
                _buildMetric(
                  icon: Icons.speed,
                  value: _route.averageSpeed.toStringAsFixed(1),
                  unit: 'km/h',
                  label: 'Velocidad',
                ),
                _buildDivider(),
                _buildMetric(
                  icon: Icons.local_fire_department,
                  value: _route.estimatedCalories.toStringAsFixed(0),
                  unit: 'cal',
                  label: 'Calorías',
                ),
              ],
            ),
          ),
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
                  colors: [AppColors.accent, Color(0xFF0891B2)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_isTracking ? AppColors.danger : AppColors.accent)
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

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: Responsive.w(5).clamp(18, 22)),
          SizedBox(height: Responsive.h(0.6).clamp(4, 8)),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: Responsive.sp(15).clamp(13, 17),
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  ' $unit',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.sp(10).clamp(9, 11),
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.h(0.3).clamp(2, 4)),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: Responsive.sp(10).clamp(9, 11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: Responsive.h(3.5).clamp(24, 36),
      width: 1,
      color: AppColors.glassBorder,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class RoutePainter extends CustomPainter {
  final Route route;
  final bool isTracking;

  RoutePainter({required this.route, this.isTracking = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (route.points.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: isTracking ? 'Registrando ruta...' : 'Sin datos de ruta',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    double minLat = route.points.first.latitude;
    double maxLat = route.points.first.latitude;
    double minLon = route.points.first.longitude;
    double maxLon = route.points.first.longitude;

    for (final point in route.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    final padding = size.width * 0.06;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    Offset toPixel(LocationPoint point) {
      final latRange = maxLat - minLat;
      final lonRange = maxLon - minLon;

      final x = lonRange == 0
          ? drawWidth / 2
          : ((point.longitude - minLon) / lonRange) * drawWidth;
      final y = latRange == 0
          ? drawHeight / 2
          : ((maxLat - point.latitude) / latRange) * drawHeight;

      return Offset(x + padding, y + padding);
    }

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(toPixel(route.points.first).dx, toPixel(route.points.first).dy);

    for (int i = 1; i < route.points.length; i++) {
      final pixel = toPixel(route.points[i]);
      path.lineTo(pixel.dx, pixel.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final startPaint = Paint()..color = AppColors.success;
    canvas.drawCircle(toPixel(route.points.first), 8, startPaint);
    final startRingPaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(toPixel(route.points.first), 12, startRingPaint);

    final endPaint = Paint()..color = AppColors.danger;
    canvas.drawCircle(toPixel(route.points.last), 8, endPaint);
    final endRingPaint = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(toPixel(route.points.last), 12, endRingPaint);
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) {
    return oldDelegate.route.points.length != route.points.length ||
        oldDelegate.isTracking != isTracking;
  }
}
