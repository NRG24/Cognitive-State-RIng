/// Model for stress pattern analysis over time
class StressPattern {
  final DateTime timestamp;
  final String arousalLevel;
  final double gsrVariability;
  final int heartRate;
  final double hrv;
  final double temperature;
  final int durationSeconds;

  StressPattern({
    required this.timestamp,
    required this.arousalLevel,
    required this.gsrVariability,
    required this.heartRate,
    required this.hrv,
    required this.temperature,
    this.durationSeconds = 60, // Default 1 minute
  });

  bool get isStressed =>
      arousalLevel == 'Stressed' || arousalLevel == 'Highly Aroused';
  bool get isCalm =>
      arousalLevel == 'Deep Calm' || arousalLevel == 'Relaxed';

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'arousalLevel': arousalLevel,
        'gsrVariability': gsrVariability,
        'heartRate': heartRate,
        'hrv': hrv,
        'temperature': temperature,
        'durationSeconds': durationSeconds,
      };

  factory StressPattern.fromJson(Map<String, dynamic> json) => StressPattern(
        timestamp: DateTime.parse(json['timestamp']),
        arousalLevel: json['arousalLevel'],
        gsrVariability: json['gsrVariability'],
        heartRate: json['heartRate'],
        hrv: json['hrv'],
        temperature: json['temperature'] ?? 0.0,
        durationSeconds: json['durationSeconds'] ?? 60,
      );
}

/// Aggregated stress insights for a time period
class StressInsights {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalMinutes;
  final int stressMinutes;
  final int calmMinutes;
  final int alertMinutes;
  final List<StressSpike> stressSpikes;
  final Map<int, int> hourlyStressDistribution; // Hour of day -> stress minutes
  final double avgStressLevel;
  final List<String> patterns; // Detected patterns

  StressInsights({
    required this.periodStart,
    required this.periodEnd,
    required this.totalMinutes,
    required this.stressMinutes,
    required this.calmMinutes,
    required this.alertMinutes,
    required this.stressSpikes,
    required this.hourlyStressDistribution,
    required this.avgStressLevel,
    required this.patterns,
  });

  double get stressPercentage =>
      totalMinutes > 0 ? (stressMinutes / totalMinutes) * 100 : 0;
  double get calmPercentage =>
      totalMinutes > 0 ? (calmMinutes / totalMinutes) * 100 : 0;
  
  String get stressLevel {
    if (stressPercentage < 10) return 'Very Low Stress';
    if (stressPercentage < 20) return 'Low Stress';
    if (stressPercentage < 35) return 'Moderate Stress';
    if (stressPercentage < 50) return 'High Stress';
    return 'Very High Stress';
  }
}

/// Individual stress spike event
class StressSpike {
  final DateTime startTime;
  final DateTime endTime;
  final String peakArousal;
  final double maxGSR;
  final int maxHeartRate;
  final double minHRV;
  final String? possibleTrigger; // Time-based trigger detection

  StressSpike({
    required this.startTime,
    required this.endTime,
    required this.peakArousal,
    required this.maxGSR,
    required this.maxHeartRate,
    required this.minHRV,
    this.possibleTrigger,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  String get timeOfDay {
    final hour = startTime.hour;
    if (hour < 6) return 'Night';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'peakArousal': peakArousal,
        'maxGSR': maxGSR,
        'maxHeartRate': maxHeartRate,
        'minHRV': minHRV,
        'possibleTrigger': possibleTrigger,
      };

  factory StressSpike.fromJson(Map<String, dynamic> json) => StressSpike(
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        peakArousal: json['peakArousal'],
        maxGSR: json['maxGSR'],
        maxHeartRate: json['maxHeartRate'],
        minHRV: json['minHRV'],
        possibleTrigger: json['possibleTrigger'],
      );
}

/// Daily stress summary
class DailyStressSummary {
  final DateTime date;
  final int totalSessions;
  final int totalMinutes;
  final int stressMinutes;
  final int calmMinutes;
  final int stressSpikes;
  final double avgCognitiveScore;
  final String dominantState;
  final Map<String, int> arousalDistribution;

  DailyStressSummary({
    required this.date,
    required this.totalSessions,
    required this.totalMinutes,
    required this.stressMinutes,
    required this.calmMinutes,
    required this.stressSpikes,
    required this.avgCognitiveScore,
    required this.dominantState,
    required this.arousalDistribution,
  });

  double get stressPercentage =>
      totalMinutes > 0 ? (stressMinutes / totalMinutes) * 100 : 0;

  String get stressRating {
    if (stressPercentage < 15) return '😊 Low Stress Day';
    if (stressPercentage < 30) return '😐 Moderate Stress';
    if (stressPercentage < 50) return '😟 High Stress';
    return '😰 Very High Stress';
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'stressMinutes': stressMinutes,
        'calmMinutes': calmMinutes,
        'stressSpikes': stressSpikes,
        'avgCognitiveScore': avgCognitiveScore,
        'dominantState': dominantState,
        'arousalDistribution': arousalDistribution,
      };

  factory DailyStressSummary.fromJson(Map<String, dynamic> json) =>
      DailyStressSummary(
        date: DateTime.parse(json['date']),
        totalSessions: json['totalSessions'],
        totalMinutes: json['totalMinutes'],
        stressMinutes: json['stressMinutes'],
        calmMinutes: json['calmMinutes'],
        stressSpikes: json['stressSpikes'],
        avgCognitiveScore: json['avgCognitiveScore'],
        dominantState: json['dominantState'],
        arousalDistribution:
            Map<String, int>.from(json['arousalDistribution']),
      );
}
