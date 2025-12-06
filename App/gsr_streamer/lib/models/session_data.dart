/// Model for storing a single biometric monitoring session
class SessionData {
  final DateTime startTime;
  final DateTime endTime;
  final double avgHeartRate;
  final double avgHRV;
  final double avgSpO2;
  final double avgGSR;
  final double avgTemperature;
  final double avgCognitiveScore;
  final Map<String, int> arousalDistribution; // How much time in each state
  final int stressEvents; // Number of high stress periods
  final int calmPeriods; // Number of calm periods

  SessionData({
    required this.startTime,
    required this.endTime,
    required this.avgHeartRate,
    required this.avgHRV,
    required this.avgSpO2,
    required this.avgGSR,
    required this.avgTemperature,
    required this.avgCognitiveScore,
    required this.arousalDistribution,
    required this.stressEvents,
    required this.calmPeriods,
  });

  /// Calculate session duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Convert session to JSON for storage
  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'avgHeartRate': avgHeartRate,
        'avgHRV': avgHRV,
        'avgSpO2': avgSpO2,
        'avgGSR': avgGSR,
        'avgTemperature': avgTemperature,
        'avgCognitiveScore': avgCognitiveScore,
        'arousalDistribution': arousalDistribution,
        'stressEvents': stressEvents,
        'calmPeriods': calmPeriods,
      };

  /// Create session from JSON storage
  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        avgHeartRate: json['avgHeartRate'],
        avgHRV: json['avgHRV'],
        avgSpO2: json['avgSpO2'],
        avgGSR: json['avgGSR'],
        avgTemperature: json['avgTemperature'] ?? 0.0,
        avgCognitiveScore: json['avgCognitiveScore'],
        arousalDistribution:
            Map<String, int>.from(json['arousalDistribution']),
        stressEvents: json['stressEvents'],
        calmPeriods: json['calmPeriods'],
      );
}
