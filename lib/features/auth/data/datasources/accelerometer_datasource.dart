import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  static const int _historySize = 30;
  static const double _stepThreshold = 12.0;

  static const double _enterRunning = 13.0;
  static const double _stayRunning = 11.0;
  static const double _enterWalking = 10.5;
  static const double _stayWalking = 8.8;
  static const int _activityConfidenceThreshold = 15;

  static const double _fallPeakThreshold = 38.0;
  static const double _fallQuietMin = 6.8;
  static const double _fallQuietMax = 12.8;
  static const int _fallCooldownSamples = 100;
  static const int _fallQuietRequired = 12;
  static const int _minSamplesBetweenPeaks = 50;
  static const int _maxFallSamples = 20;
  static const int _sendEveryNSamples = 3;

  final List<double> _magnitudeHistory = [];
  double _lastMagnitude = 0.0;

  String _lastRawActivityType = 'stationary';
  String _stableActivityType = 'stationary';
  int _activityConfidence = 0;

  bool _fallPotential = false;
  int _fallSamplesSincePeak = 0;
  int _fallQuietCount = 0;
  bool _fallConfirmed = false;
  int _fallCooldown = 0;
  int _samplesSinceLastPeak = 999;

  int _sampleCount = 0;
  int _stepCount = 0;

  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  StreamController<StepData>? _controller;

  @override
  Stream<StepData> get stepStream {
    _controller?.close();
    _controller = StreamController<StepData>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> startCounting() async {
    _resetState();

    _controller ??= StreamController<StepData>.broadcast();

    _sensorSubscription = accelerometerEventStream().listen(
      (event) {
        _onSensorData(event.x, event.y, event.z);
      },
      onError: (error) {
        _controller?.addError(error);
      },
    );
  }

  @override
  Future<void> stopCounting() async {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  void _resetState() {
    _stepCount = 0;
    _magnitudeHistory.clear();
    _lastMagnitude = 0.0;
    _lastRawActivityType = 'stationary';
    _stableActivityType = 'stationary';
    _activityConfidence = 0;
    _fallPotential = false;
    _fallSamplesSincePeak = 0;
    _fallQuietCount = 0;
    _fallConfirmed = false;
    _fallCooldown = 0;
    _samplesSinceLastPeak = 999;
    _sampleCount = 0;
  }

  void _onSensorData(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);

    _magnitudeHistory.add(magnitude);
    if (_magnitudeHistory.length > _historySize) {
      _magnitudeHistory.removeAt(0);
    }
    final avgMagnitude = _magnitudeHistory.fold(0.0, (a, b) => a + b) / _magnitudeHistory.length;

    if (magnitude > _stepThreshold && _lastMagnitude <= _stepThreshold) {
      _stepCount++;
    }
    _lastMagnitude = magnitude;

    final newActivityType = _classifyActivity(avgMagnitude);

    if (newActivityType == _lastRawActivityType) {
      _activityConfidence = (_activityConfidence + 1)
          .clamp(0, _activityConfidenceThreshold + 10);
    } else {
      _activityConfidence = (_activityConfidence - 3).clamp(0, 999);
    }

    if (_activityConfidence >= _activityConfidenceThreshold) {
      _stableActivityType = newActivityType;
    }
    _lastRawActivityType = newActivityType;

    _detectFall(magnitude);

    _sampleCount++;
    if (_sampleCount >= _sendEveryNSamples) {
      _sampleCount = 0;

      final data = StepData(
        stepCount: _stepCount,
        activityType: _parseActivityType(_stableActivityType),
        magnitude: avgMagnitude,
        fallDetected: _fallConfirmed,
      );

      _fallConfirmed = false;
      _controller?.add(data);
    }
  }

  String _classifyActivity(double avgMagnitude) {
    if (avgMagnitude > _enterRunning) return 'running';
    if (_lastRawActivityType == 'running' && avgMagnitude > _stayRunning) return 'running';
    if (avgMagnitude > _enterWalking) return 'walking';
    if (_lastRawActivityType == 'walking' && avgMagnitude > _stayWalking) return 'walking';
    return 'stationary';
  }

  void _detectFall(double magnitude) {
    if (_stableActivityType == 'running') {
      _fallPotential = false;
      _fallQuietCount = 0;
      _samplesSinceLastPeak = 999;
      return;
    }

    _samplesSinceLastPeak++;

    if (_fallCooldown > 0) {
      _fallCooldown--;
    }

    if (magnitude > _fallPeakThreshold &&
        _fallCooldown == 0 &&
        _samplesSinceLastPeak >= _minSamplesBetweenPeaks) {
      _fallPotential = true;
      _fallSamplesSincePeak = 0;
      _fallQuietCount = 0;
      _samplesSinceLastPeak = 0;
    }

    if (_fallPotential) {
      _fallSamplesSincePeak++;

      if (magnitude > _fallQuietMin && magnitude < _fallQuietMax) {
        _fallQuietCount++;
        if (_fallQuietCount >= _fallQuietRequired) {
          _fallConfirmed = true;
          _fallPotential = false;
          _fallCooldown = _fallCooldownSamples;
        }
      } else {
        _fallQuietCount = 0;
      }

      if (_fallSamplesSincePeak > _maxFallSamples) {
        _fallPotential = false;
      }
    }
  }

  ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'walking':
        return ActivityType.walking;
      case 'running':
        return ActivityType.running;
      default:
        return ActivityType.stationary;
    }
  }
}
