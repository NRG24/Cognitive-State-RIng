/// Types of stress triggers that can be detected
enum TriggerType {
  timeOfDay,
  activityChange,
  environmental,
  physiological,
  workload,
  social,
  pattern,
  unknown;

  String get displayName {
    switch (this) {
      case TriggerType.timeOfDay:
        return 'Time of Day';
      case TriggerType.activityChange:
        return 'Activity Change';
      case TriggerType.environmental:
        return 'Environmental';
      case TriggerType.physiological:
        return 'Physiological';
      case TriggerType.workload:
        return 'Workload';
      case TriggerType.social:
        return 'Social';
      case TriggerType.pattern:
        return 'Recurring Pattern';
      case TriggerType.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case TriggerType.timeOfDay:
        return '⏰';
      case TriggerType.activityChange:
        return '🔄';
      case TriggerType.environmental:
        return '🌡️';
      case TriggerType.physiological:
        return '❤️';
      case TriggerType.workload:
        return '💼';
      case TriggerType.social:
        return '👥';
      case TriggerType.pattern:
        return '🔁';
      case TriggerType.unknown:
        return '❓';
    }
  }
}

/// Severity level of a stress trigger
enum TriggerSeverity {
  mild,
  moderate,
  severe,
  critical;

  String get displayName {
    switch (this) {
      case TriggerSeverity.mild:
        return 'Mild';
      case TriggerSeverity.moderate:
        return 'Moderate';
      case TriggerSeverity.severe:
        return 'Severe';
      case TriggerSeverity.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case TriggerSeverity.mild:
        return '😐';
      case TriggerSeverity.moderate:
        return '😟';
      case TriggerSeverity.severe:
        return '😰';
      case TriggerSeverity.critical:
        return '🆘';
    }
  }
}

/// Detected stress trigger event
class StressTrigger {
  final TriggerType type;
  final TriggerSeverity severity;
  final DateTime timestamp;
  final String description;
  final Map<String, double> biometricSnapshot; // HR, HRV, GSR at trigger time
  final String? context; // Activity, location, etc.
  final double intensity; // 0.0 to 1.0
  final int durationSeconds;
  final String? recommendation;

  StressTrigger({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.description,
    required this.biometricSnapshot,
    this.context,
    required this.intensity,
    this.durationSeconds = 0,
    this.recommendation,
  });

  String get timeOfDay {
    final hour = timestamp.hour;
    if (hour < 6) return 'Late Night';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  String get formattedDate =>
      '${timestamp.month}/${timestamp.day}/${timestamp.year}';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'biometricSnapshot': biometricSnapshot,
        'context': context,
        'intensity': intensity,
        'durationSeconds': durationSeconds,
        'recommendation': recommendation,
      };

  factory StressTrigger.fromJson(Map<String, dynamic> json) => StressTrigger(
        type: TriggerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TriggerType.unknown,
        ),
        severity: TriggerSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => TriggerSeverity.moderate,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
        biometricSnapshot: Map<String, double>.from(json['biometricSnapshot']),
        context: json['context'],
        intensity: json['intensity'],
        durationSeconds: json['durationSeconds'] ?? 0,
        recommendation: json['recommendation'],
      );
}

/// Pattern of recurring stress triggers
class TriggerPattern {
  final TriggerType primaryType;
  final String description;
  final int occurrences;
  final List<int> commonHours; // Hours when this pattern occurs
  final List<int> commonDays; // Days of week (1-7)
  final double averageIntensity;
  final String recommendation;

  TriggerPattern({
    required this.primaryType,
    required this.description,
    required this.occurrences,
    required this.commonHours,
    required this.commonDays,
    required this.averageIntensity,
    required this.recommendation,
  });

  String get frequency {
    if (occurrences >= 20) return 'Very Frequent';
    if (occurrences >= 10) return 'Frequent';
    if (occurrences >= 5) return 'Occasional';
    return 'Rare';
  }

  String get commonTime {
    if (commonHours.isEmpty) return 'Varies';
    final avgHour = commonHours.reduce((a, b) => a + b) ~/ commonHours.length;
    if (avgHour < 6) return 'Late Night (12-6am)';
    if (avgHour < 12) return 'Morning (6am-12pm)';
    if (avgHour < 17) return 'Afternoon (12-5pm)';
    if (avgHour < 21) return 'Evening (5-9pm)';
    return 'Night (9pm-12am)';
  }

  String get commonDaysStr {
    if (commonDays.isEmpty) return 'Any day';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return commonDays.map((d) => days[d - 1]).join(', ');
  }
}

/// Analysis of trigger trends over time
class TriggerAnalysis {
  final int totalTriggers;
  final Map<TriggerType, int> triggersByType;
  final Map<TriggerSeverity, int> triggersBySeverity;
  final Map<int, int> triggersByHour; // Hour -> count
  final Map<int, int> triggersByDay; // Day of week -> count
  final List<TriggerPattern> patterns;
  final double avgIntensity;
  final TriggerType mostCommonType;
  final List<String> insights;

  TriggerAnalysis({
    required this.totalTriggers,
    required this.triggersByType,
    required this.triggersBySeverity,
    required this.triggersByHour,
    required this.triggersByDay,
    required this.patterns,
    required this.avgIntensity,
    required this.mostCommonType,
    required this.insights,
  });

  int get criticalTriggers =>
      triggersBySeverity[TriggerSeverity.critical] ?? 0;
  int get severeTriggers => triggersBySeverity[TriggerSeverity.severe] ?? 0;

  String get overallRisk {
    if (criticalTriggers > 5) return 'High Risk';
    if (severeTriggers > 10) return 'Elevated Risk';
    if (totalTriggers > 20) return 'Moderate Risk';
    return 'Low Risk';
  }
}

/// Trigger mitigation strategy
class MitigationStrategy {
  final TriggerType triggerType;
  final String strategy;
  final String shortTerm;
  final String longTerm;
  final List<String> actionSteps;
  final int priority; // 1-5, 5 being highest

  MitigationStrategy({
    required this.triggerType,
    required this.strategy,
    required this.shortTerm,
    required this.longTerm,
    required this.actionSteps,
    required this.priority,
  });

  String get priorityLabel {
    if (priority >= 4) return 'High Priority';
    if (priority >= 3) return 'Medium Priority';
    return 'Low Priority';
  }
}
