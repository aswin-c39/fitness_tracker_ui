import 'package:flutter/material.dart';


class Person {
  final String id;
  final String name;
  final int heartRate;
  final double spo2;
  final DateTime timestamp;
  final PhysicalCondition condition;

  Person({
    required this.id,
    required this.name,
    required this.heartRate,
    required this.spo2,
    required this.timestamp,
    required this.condition,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      heartRate: json['heart_rate'] ?? 0,
      spo2: (json['spo2'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      condition: PhysicalConditionExtension.fromValues(
        json['heart_rate'] ?? 0,
        (json['spo2'] ?? 0.0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'heart_rate': heartRate,
      'spo2': spo2,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum PhysicalCondition {
  excellent,
  good,
  fair,
  poor,
  critical,
}

extension PhysicalConditionExtension on PhysicalCondition {
  static PhysicalCondition fromValues(int heartRate, double spo2) {
    // Critical conditions (immediate attention needed)
    if (spo2 < 90 || heartRate > 120 || heartRate < 50) {
      return PhysicalCondition.critical;
    }
    
    // Poor conditions
    if (spo2 < 95 || heartRate > 110 || heartRate < 60) {
      return PhysicalCondition.poor;
    }
    
    // Fair conditions
    if (spo2 < 97 || heartRate > 100 || heartRate < 65) {
      return PhysicalCondition.fair;
    }
    
    // Good conditions
    if (spo2 < 98 || heartRate > 85) {
      return PhysicalCondition.good;
    }
    
    // Excellent conditions
    return PhysicalCondition.excellent;
  }

  String get displayName {
    switch (this) {
      case PhysicalCondition.excellent:
        return 'Excellent';
      case PhysicalCondition.good:
        return 'Good';
      case PhysicalCondition.fair:
        return 'Fair';
      case PhysicalCondition.poor:
        return 'Poor';
      case PhysicalCondition.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case PhysicalCondition.excellent:
        return Colors.green[600]!;
      case PhysicalCondition.good:
        return Colors.lightGreen[600]!;
      case PhysicalCondition.fair:
        return Colors.orange[600]!;
      case PhysicalCondition.poor:
        return Colors.deepOrange[600]!;
      case PhysicalCondition.critical:
        return Colors.red[600]!;
    }
  }

  IconData get icon {
    switch (this) {
      case PhysicalCondition.excellent:
        return Icons.favorite;
      case PhysicalCondition.good:
        return Icons.thumb_up;
      case PhysicalCondition.fair:
        return Icons.warning_amber;
      case PhysicalCondition.poor:
        return Icons.error_outline;
      case PhysicalCondition.critical:
        return Icons.emergency;
    }
  }

  int get priority {
    switch (this) {
      case PhysicalCondition.critical:
        return 0;
      case PhysicalCondition.poor:
        return 1;
      case PhysicalCondition.fair:
        return 2;
      case PhysicalCondition.good:
        return 3;
      case PhysicalCondition.excellent:
        return 4;
    }
  }
}