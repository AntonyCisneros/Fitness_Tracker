import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.speed = 0,
    this.accuracy = 0,
    required this.timestamp,
  });

  factory LocationPoint.fromPosition(Position position) {
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  factory LocationPoint.fromMap(Map<dynamic, dynamic> map) {
    final alt = map['altitude'];
    final spd = map['speed'];
    final acc = map['accuracy'];
    return LocationPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: alt is num ? alt.toDouble() : 0.0,
      speed: spd is num ? spd.toDouble() : 0.0,
      accuracy: acc is num ? acc.toDouble() : 0.0,
      timestamp: DateTime.now(),
    );
  }

  double distanceTo(LocationPoint other) {
    const earthRadius = 6371000.0;

    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLon = (other.longitude - longitude) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) *
              math.sin(deltaLon / 2) * math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}

class Route {
  final List<LocationPoint> points;
  final DateTime startTime;
  DateTime? endTime;

  Route({
    List<LocationPoint>? points,
    DateTime? startTime,
  }) : points = points ?? [],
       startTime = startTime ?? DateTime.now();

  void addPoint(LocationPoint point) {
    points.add(point);
  }

  void finish() {
    endTime = DateTime.now();
  }

  double get totalDistance {
    if (points.length < 2) return 0;

    double distance = 0;
    for (int i = 1; i < points.length; i++) {
      distance += points[i - 1].distanceTo(points[i]);
    }
    return distance;
  }

  double get distanceKm => totalDistance / 1000;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get averageSpeed {
    final hours = duration.inSeconds / 3600;
    if (hours == 0) return 0;
    return distanceKm / hours;
  }

  double get estimatedCalories => distanceKm * 60;
}
