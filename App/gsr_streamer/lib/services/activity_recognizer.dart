import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity_type.dart';

/// Service for detecting and classifying activities based on biometric data
class ActivityRecognizer {
  static const String _historyKey = 'activity_history';
  static const String _transitionsKey = 'activity_transitions';
  
  // Activity detection thresholds
  static const int _restingHeartRateMax = 70;
  static const int _exerciseHeartRateMin = 100;
  static const double _restingGSRMax = 0.1;
  static const double _stressGSRMin = 0.35;
  static const double _exerciseTempMin = 37.0;
  static const double _restingHRVMin = 30.0;
  static const double _stressHRVMax = 15.0;
  
  // Confidence thresholds
  static const double _mediumConfidence = 0.6;
  
  /// Detect current activity from biometric data
  static ActivityDetection detectActivity({
    required int heartRate,
    required double hrv,
    required double gsrVariability,
    required double temperature,
    required String arousalLevel,
    required double cognitiveScore,
  }) {
    final metrics = <String, double>{
      'heartRate': heartRate.toDouble(),
      'hrv': hrv,
      'gsrVariability': gsrVariability,
      'temperature': temperature,
      'cognitiveScore': cognitiveScore,
    };

    // Calculate confidence scores for each activity type
    final scores = <ActivityType, double>{};
    
    scores[ActivityType.exercising] = _calculateExerciseScore(
      heartRate, hrv, gsrVariability, temperature, arousalLevel
    );
    
    scores[ActivityType.resting] = _calculateRestingScore(
      heartRate, hrv, gsrVariability, arousalLevel
    );
    
    scores[ActivityType.working] = _calculateWorkingScore(
      heartRate, hrv, gsrVariability, arousalLevel, cognitiveScore
    );
    
    scores[ActivityType.stressed] = _calculateStressScore(
      heartRate, hrv, gsrVariability, arousalLevel
    );
    
    scores[ActivityType.sleeping] = _calculateSleepingScore(
      heartRate, hrv, gsrVariability, arousalLevel
    );
    
    scores[ActivityType.recovering] = _calculateRecoveringScore(
      heartRate, hrv, gsrVariability, temperature
    );

    // Find activity with highest confidence
    ActivityType detectedActivity = ActivityType.unknown;
    double maxConfidence = 0.3; // Minimum threshold for detection

    scores.forEach((activity, confidence) {
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        detectedActivity = activity;
      }
    });

    return ActivityDetection(
      activityType: detectedActivity,
      confidence: maxConfidence,
      timestamp: DateTime.now(),
      metrics: metrics,
    );
  }

  /// Calculate probability of exercising
  static double _calculateExerciseScore(
    int hr, double hrv, double gsr, double temp, String arousal
  ) {
    double score = 0.0;
    
    // High heart rate
    if (hr >= _exerciseHeartRateMin) {
      score += 0.35;
      if (hr >= 120) score += 0.1;
      if (hr >= 140) score += 0.1;
    }
    
    // Elevated temperature (body heat from exercise)
    if (temp >= _exerciseTempMin) {
      score += 0.25;
      if (temp >= 37.5) score += 0.1;
    }
    
    // Moderate to high GSR (physical exertion)
    if (gsr >= 0.15 && gsr <= 0.5) {
      score += 0.15;
    }
    
    // Lower HRV during exercise
    if (hrv < 25 && hrv > 10) {
      score += 0.1;
    }
    
    // Engaged or stressed arousal (effort)
    if (arousal == 'Engaged' || arousal == 'Stressed') {
      score += 0.05;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate probability of resting
  static double _calculateRestingScore(
    int hr, double hrv, double gsr, String arousal
  ) {
    double score = 0.0;
    
    // Low heart rate
    if (hr <= _restingHeartRateMax) {
      score += 0.35;
      if (hr <= 60) score += 0.1;
    }
    
    // High HRV (relaxed state)
    if (hrv >= _restingHRVMin) {
      score += 0.25;
      if (hrv >= 40) score += 0.1;
    }
    
    // Low GSR variability
    if (gsr <= _restingGSRMax) {
      score += 0.25;
    }
    
    // Calm arousal states
    if (arousal == 'Deep Calm' || arousal == 'Relaxed') {
      score += 0.15;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate probability of working
  static double _calculateWorkingScore(
    int hr, double hrv, double gsr, String arousal, double cognitive
  ) {
    double score = 0.0;
    
    // Moderate heart rate (focused but not exercising)
    if (hr >= 65 && hr <= 90) {
      score += 0.25;
    }
    
    // Moderate HRV
    if (hrv >= 20 && hrv <= 35) {
      score += 0.15;
    }
    
    // Low to moderate GSR (mental engagement)
    if (gsr >= 0.1 && gsr <= 0.3) {
      score += 0.2;
    }
    
    // Alert or engaged arousal
    if (arousal == 'Alert' || arousal == 'Engaged') {
      score += 0.25;
    }
    
    // Good cognitive performance
    if (cognitive >= 65) {
      score += 0.15;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate probability of stress
  static double _calculateStressScore(
    int hr, double hrv, double gsr, String arousal
  ) {
    double score = 0.0;
    
    // Elevated heart rate (but not exercise level)
    if (hr >= 80 && hr <= 110) {
      score += 0.25;
    }
    
    // Low HRV (reduced resilience)
    if (hrv <= _stressHRVMax) {
      score += 0.3;
    }
    
    // High GSR variability
    if (gsr >= _stressGSRMin) {
      score += 0.3;
    }
    
    // Stressed arousal states
    if (arousal == 'Stressed' || arousal == 'Highly Aroused') {
      score += 0.15;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate probability of sleeping
  static double _calculateSleepingScore(
    int hr, double hrv, double gsr, String arousal
  ) {
    double score = 0.0;
    
    // Very low heart rate
    if (hr <= 55) {
      score += 0.3;
      if (hr <= 50) score += 0.1;
    }
    
    // Very high HRV (deep rest)
    if (hrv >= 40) {
      score += 0.3;
    }
    
    // Minimal GSR activity
    if (gsr <= 0.05) {
      score += 0.25;
    }
    
    // Deep calm state
    if (arousal == 'Deep Calm') {
      score += 0.15;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate probability of recovering (post-exercise)
  static double _calculateRecoveringScore(
    int hr, double hrv, double gsr, double temp
  ) {
    double score = 0.0;
    
    // Elevated but decreasing heart rate
    if (hr >= 75 && hr <= 95) {
      score += 0.3;
    }
    
    // Moderate HRV (recovering)
    if (hrv >= 15 && hrv <= 25) {
      score += 0.2;
    }
    
    // Elevated temperature (still cooling down)
    if (temp >= 36.8 && temp <= 37.5) {
      score += 0.25;
    }
    
    // Moderate GSR
    if (gsr >= 0.1 && gsr <= 0.25) {
      score += 0.25;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Generate activity statistics for a time period
  static ActivityStats generateStats(
    List<ActivityDetection> detections,
    Duration period,
  ) {
    final durationByActivity = <ActivityType, int>{};
    final countByActivity = <ActivityType, int>{};
    
    for (final detection in detections) {
      final type = detection.activityType;
      durationByActivity[type] = (durationByActivity[type] ?? 0) + 
          (detection.duration ~/ 60); // Convert to minutes
      countByActivity[type] = (countByActivity[type] ?? 0) + 1;
    }
    
    // Find dominant activity
    ActivityType dominant = ActivityType.unknown;
    int maxDuration = 0;
    
    durationByActivity.forEach((type, duration) {
      if (duration > maxDuration) {
        maxDuration = duration;
        dominant = type;
      }
    });
    
    final totalMinutes = durationByActivity.values.fold<int>(0, (a, b) => a + b);
    
    return ActivityStats(
      durationByActivity: durationByActivity,
      countByActivity: countByActivity,
      dominantActivity: dominant,
      totalMinutes: totalMinutes,
    );
  }

  /// Detect activity transitions
  static ActivityTransition? detectTransition(
    ActivityDetection previous,
    ActivityDetection current,
  ) {
    // Only create transition if activity changed and confidence is high
    if (previous.activityType == current.activityType) {
      return null;
    }
    
    if (current.confidence < _mediumConfidence) {
      return null;
    }
    
    // Determine possible trigger
    String? trigger;
    
    // Resting -> Working
    if (previous.activityType == ActivityType.resting && 
        current.activityType == ActivityType.working) {
      trigger = 'Started work session';
    }
    
    // Working -> Exercising
    if (previous.activityType == ActivityType.working && 
        current.activityType == ActivityType.exercising) {
      trigger = 'Started physical activity';
    }
    
    // Exercising -> Recovering
    if (previous.activityType == ActivityType.exercising && 
        current.activityType == ActivityType.recovering) {
      trigger = 'Exercise completed';
    }
    
    // Any -> Stressed
    if (current.activityType == ActivityType.stressed) {
      trigger = 'Stress trigger detected';
    }
    
    // Stressed -> Resting
    if (previous.activityType == ActivityType.stressed && 
        current.activityType == ActivityType.resting) {
      trigger = 'Stress resolved';
    }
    
    return ActivityTransition(
      fromActivity: previous.activityType,
      toActivity: current.activityType,
      timestamp: current.timestamp,
      trigger: trigger,
    );
  }

  /// Save activity history to persistent storage
  static Future<void> saveActivityHistory(
    List<ActivityDetection> detections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = detections.map((d) => d.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonList));
  }

  /// Load activity history from persistent storage
  static Future<List<ActivityDetection>> loadActivityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) return [];
    
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => ActivityDetection.fromJson(j)).toList();
  }

  /// Save activity transitions
  static Future<void> saveTransitions(
    List<ActivityTransition> transitions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transitions.map((t) => t.toJson()).toList();
    await prefs.setString(_transitionsKey, json.encode(jsonList));
  }

  /// Load activity transitions
  static Future<List<ActivityTransition>> loadTransitions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transitionsKey);
    
    if (jsonString == null) return [];
    
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => ActivityTransition.fromJson(j)).toList();
  }

  /// Get insights from activity patterns
  static List<String> getInsights(ActivityStats stats) {
    final insights = <String>[];
    
    // Exercise insights
    final exercisePercent = stats.getPercentage(ActivityType.exercising);
    if (exercisePercent >= 15) {
      insights.add('🏃 Great exercise routine! ${exercisePercent.toStringAsFixed(0)}% of time exercising');
    } else if (exercisePercent < 5) {
      insights.add('💡 Consider adding more physical activity to your routine');
    }
    
    // Stress insights
    final stressPercent = stats.getPercentage(ActivityType.stressed);
    if (stressPercent >= 30) {
      insights.add('⚠️ High stress levels detected - ${stressPercent.toStringAsFixed(0)}% of time stressed');
    } else if (stressPercent < 10) {
      insights.add('😌 Excellent stress management - low stress levels maintained');
    }
    
    // Rest insights
    final restPercent = stats.getPercentage(ActivityType.resting);
    if (restPercent >= 40) {
      insights.add('🧘 Good balance of rest and recovery');
    } else if (restPercent < 15) {
      insights.add('💤 Consider adding more rest periods for recovery');
    }
    
    // Work-life balance
    final workPercent = stats.getPercentage(ActivityType.working);
    if (workPercent >= 50) {
      insights.add('💼 Heavy work load detected - ensure adequate breaks');
    } else if (workPercent >= 30 && workPercent < 50) {
      insights.add('✅ Good work-life balance maintained');
    }
    
    return insights;
  }
}
