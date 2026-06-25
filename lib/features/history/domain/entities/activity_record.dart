import 'package:equatable/equatable.dart';

class ActivityRecord extends Equatable {
  final int? id;
  final DateTime date;
  final int stepCount;
  final String activityType;
  final double estimatedCalories;
  final double distanceKm;
  final int durationMinutes;
  final String? notes;

  const ActivityRecord({
    this.id,
    required this.date,
    required this.stepCount,
    required this.activityType,
    required this.estimatedCalories,
    required this.distanceKm,
    required this.durationMinutes,
    this.notes,
  });

  ActivityRecord copyWith({
    int? id,
    DateTime? date,
    int? stepCount,
    String? activityType,
    double? estimatedCalories,
    double? distanceKm,
    int? durationMinutes,
    String? notes,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      activityType: activityType ?? this.activityType,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'stepCount': stepCount,
      'activityType': activityType,
      'estimatedCalories': estimatedCalories,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      stepCount: map['stepCount'] as int,
      activityType: map['activityType'] as String,
      estimatedCalories: (map['estimatedCalories'] as num).toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        stepCount,
        activityType,
        estimatedCalories,
        distanceKm,
        durationMinutes,
        notes,
      ];
}
