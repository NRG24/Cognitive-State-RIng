/// Enumeration of detected activity types
enum ActivityType {
  resting,
  working,
  exercising,
  sleeping,
  stressed,
  recovering,
  unknown;

  String get displayName {
    switch (this) {
      case ActivityType.resting:
        return 'Resting';
      case ActivityType.working:
        return 'Working';
      case ActivityType.exercising:
        return 'Exercising';
      case ActivityType.sleeping:
        return 'Sleeping';
      case ActivityType.stressed:
        return 'Stressed';
      case ActivityType.recovering:
        return 'Recovering';
      case ActivityType.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityType.resting:
        return '😌';
      case ActivityType.working:
        return '💼';
      case ActivityType.exercising:
        return '🏃';
      case ActivityType.sleeping:
        return '😴';
      case ActivityType.stressed:
        return '😰';
      case ActivityType.recovering:
        return '🧘';
      case ActivityType.unknown:
        return '❓';
    }
  }

  String get description {
    switch (this) {
      case ActivityType.resting:
        return 'Relaxed state with low physiological activity';
      case ActivityType.working:
        return 'Mental engagement with moderate arousal';
      case ActivityType.exercising:
        return 'Physical activity with elevated vitals';
      case ActivityType.sleeping:
        return 'Deep rest with minimal activity';
      case ActivityType.stressed:
        return 'High arousal without physical exertion';
      case ActivityType.recovering:
        return 'Post-activity recovery phase';
      case ActivityType.unknown:
        return 'Activity pattern not yet identified';
    }
  }

  String get recommendation {
    switch (this) {
      case ActivityType.resting:
        return 'Great time for reading, meditation, or creative thinking';
      case ActivityType.working:
        return 'Optimal state for focused work and problem-solving';
      case ActivityType.exercising:
        return 'Stay hydrated and monitor your intensity level';
      case ActivityType.sleeping:
        return 'Continue resting - recovery is important';
      case ActivityType.stressed:
        return 'Take a break, practice breathing exercises';
      case ActivityType.recovering:
        return 'Allow time for recovery before next activity';
      case ActivityType.unknown:
        return 'Continue monitoring to identify patterns';
    }
  }
}

/// Model for detected activity with confidence and metrics
class ActivityDetection {
  final ActivityType activityType;
  final double confidence; // 0.0 to 1.0
  final DateTime timestamp;
  final int duration; // seconds
  final Map<String, double> metrics; // Supporting data

  ActivityDetection({
    required this.activityType,
    required this.confidence,
    required this.timestamp,
    this.duration = 0,
    required this.metrics,
  });

  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  Map<String, dynamic> toJson() => {
        'activityType': activityType.name,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'duration': duration,
        'metrics': metrics,
      };

  factory ActivityDetection.fromJson(Map<String, dynamic> json) =>
      ActivityDetection(
        activityType: ActivityType.values.firstWhere(
          (e) => e.name == json['activityType'],
          orElse: () => ActivityType.unknown,
        ),
        confidence: json['confidence'],
        timestamp: DateTime.parse(json['timestamp']),
        duration: json['duration'] ?? 0,
        metrics: Map<String, double>.from(json['metrics']),
      );
}

/// Activity statistics over a time period
class ActivityStats {
  final Map<ActivityType, int> durationByActivity; // minutes per activity
  final Map<ActivityType, int> countByActivity; // number of occurrences
  final ActivityType dominantActivity;
  final int totalMinutes;

  ActivityStats({
    required this.durationByActivity,
    required this.countByActivity,
    required this.dominantActivity,
    required this.totalMinutes,
  });

  double getPercentage(ActivityType type) {
    if (totalMinutes == 0) return 0.0;
    return ((durationByActivity[type] ?? 0) / totalMinutes) * 100;
  }

  String get summary {
    final dominant = dominantActivity.displayName;
    final percentage = getPercentage(dominantActivity).toStringAsFixed(0);
    return 'Mostly $dominant ($percentage%)';
  }
}

/// Activity transition - when activity changes
class ActivityTransition {
  final ActivityType fromActivity;
  final ActivityType toActivity;
  final DateTime timestamp;
  final String? trigger; // What might have caused the transition

  ActivityTransition({
    required this.fromActivity,
    required this.toActivity,
    required this.timestamp,
    this.trigger,
  });

  String get transitionName =>
      '${fromActivity.displayName} → ${toActivity.displayName}';

  Map<String, dynamic> toJson() => {
        'fromActivity': fromActivity.name,
        'toActivity': toActivity.name,
        'timestamp': timestamp.toIso8601String(),
        'trigger': trigger,
      };

  factory ActivityTransition.fromJson(Map<String, dynamic> json) =>
      ActivityTransition(
        fromActivity: ActivityType.values.firstWhere(
          (e) => e.name == json['fromActivity'],
          orElse: () => ActivityType.unknown,
        ),
        toActivity: ActivityType.values.firstWhere(
          (e) => e.name == json['toActivity'],
          orElse: () => ActivityType.unknown,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        trigger: json['trigger'],
      );
}
