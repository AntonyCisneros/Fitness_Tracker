import 'package:flutter/material.dart';
import 'dart:async';
import '../../../auth/data/datasources/accelerometer_datasource.dart';
import '../../../auth/domain/entities/step_data.dart';
import '../../../../core/services/tts_service.dart';
import 'fall_detection_dialog.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  final AccelerometerDataSource _dataSource = AccelerometerDataSourceImpl();
  final TtsService _tts = TtsService();

  StreamSubscription<StepData>? _subscription;
  StepData? _currentData;
  bool _isTracking = false;

  /// DEBOUNCE: el aviso de voz solo se dispara si la actividad se mantiene
  /// estable durante _stabilityDuration sin interrupción, y siempre que sea
  /// diferente al último estado ya anunciado.
  ///
  /// Justificación de 3 segundos:
  /// - A ~16 paquetes/segundo (50Hz / 3 muestras por envío), 3s = ~48 paquetes
  /// - Suficiente para filtrar pausas breves, aceleraciones momentáneas y ruido
  ///   del sensor que no representan un cambio real de actividad
  /// - Menos de 2s: falsos positivos por fluctuaciones del acelerómetro
  /// - Más de 5s: el feedback llega demasiado tarde para ser útil
  static const _stabilityDuration = Duration(milliseconds: 1500);
  ActivityType? _pendingActivity;
  ActivityType? _announcedActivity;
  Timer? _stabilityTimer;

  bool _isShowingFallDialog = false;

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stabilityTimer?.cancel();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de sensores denegados'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _dataSource.startCounting();
    _tts.reset();
    _announcedActivity = null;
    _pendingActivity = null;

    _subscription = _dataSource.stepStream.listen(
      (data) {
        if (!mounted) return;

        setState(() {
          _currentData = data;
        });

        print('📡 Stream: steps=${data.stepCount} activity=${data.activityType} '
            'mag=${data.magnitude.toStringAsFixed(2)} fall=${data.fallDetected}');
        _handleActivityChange(data.activityType);
        _handleFallDetection(data);
      },
      onError: (error) {
        print('❌ Error en stream: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sensor: $error'), backgroundColor: Colors.red),
          );
        }
      },
    );

    setState(() {
      _isTracking = true;
    });
  }

  void _stopTracking() async {
    await _dataSource.stopCounting();
    _subscription?.cancel();
    _stabilityTimer?.cancel();

    setState(() {
      _isTracking = false;
    });
  }

  /// DEBOUNCE: mecanismo que evita anuncios falsos por fluctuaciones del sensor.
  ///
  /// Funcionamiento:
  /// 1. Cuando la actividad cruda cambia, se inicia un timer de 3 segundos
  /// 2. Si durante esos 3s la actividad vuelve a cambiar, el timer se reinicia
  /// 3. Solo si la actividad se mantiene estable los 3s completos, se anuncia
  /// 4. No se repite el anuncio si la actividad ya fue anunciada antes
  void _handleActivityChange(ActivityType currentActivity) {
    print('🔄 Debounce: actual=$currentActivity pending=$_pendingActivity announced=$_announcedActivity');
    if (_pendingActivity != currentActivity) {
      _stabilityTimer?.cancel();
      _pendingActivity = currentActivity;
      print('⏱️  Timer 3s iniciado para: $currentActivity');

      _stabilityTimer = Timer(_stabilityDuration, () {
        final matches = _pendingActivity == currentActivity;
        final isNew = _announcedActivity != currentActivity;
        print('⏰  Timer 3s completado: pending=$_pendingActivity current=$currentActivity '
            'matches=$matches isNew=$isNew');

        if (matches && isNew) {
          _announcedActivity = currentActivity;
          print('🔊 ANUNCIANDO: $currentActivity');
          _announceActivity(currentActivity);
        }
      });
    }
  }

  /// Síntesis de voz: anuncia el cambio de actividad en español.
  /// Usa el idioma español independientemente del idioma del sistema,
  /// cumpliendo con el requisito mínimo de español.
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

  /// Detección de caída: cuando el acelerómetro reporta fallDetected=true
  /// (pico >3g seguido de reposo), se muestra un diálogo de confirmación
  /// y se emite alerta por voz. El flag _isShowingFallDialog evita múltiples
  /// diálogos simultáneos.
  void _handleFallDetection(StepData data) {
    if (data.fallDetected && !_isShowingFallDialog) {
      _isShowingFallDialog = true;
      print('🚨 CAÍDA DETECTADA - mostrando diálogo y hablando');
      _tts.speakAlert('Atención, posible caída detectada. ¿Estás bien?');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const FallDetectionDialog(),
      ).then((_) {
        _isShowingFallDialog = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contador de Pasos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? 'Detener' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(),

            Text(
              '${_currentData?.stepCount ?? 0}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const Text('pasos', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip(
                  icon: _getActivityIcon(_currentData?.activityType),
                  label: _getActivityLabel(_currentData?.activityType),
                  color: Colors.blue,
                ),
                _buildInfoChip(
                  icon: Icons.local_fire_department,
                  label: '${_currentData?.estimatedCalories.toStringAsFixed(1) ?? "0"} cal',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
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
}
