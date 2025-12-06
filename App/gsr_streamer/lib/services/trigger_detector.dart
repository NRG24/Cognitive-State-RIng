import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trigger_type.dart';
import '../models/activity_type.dart';

/// Service for identifying and analyzing stress triggers
class TriggerDetector {
  static const String _triggersKey = 'stress_triggers';

  // Thresholds for trigger detection
  static const double _gsrSpikeThreshold = 0.3; // Rapid increase in GSR
  static const int _hrSpikeThreshold = 20; // BPM increase
  static const double _hrvDropThreshold = 10.0; // HRV decrease
  static const double _tempRiseThreshold = 0.5; // Temperature increase in °C

  /// Detect stress triggers from current biometric changes
  static StressTrigger? detectTrigger({
    required int currentHR,
    required int previousHR,
    required double currentHRV,
    required double previousHRV,
    required double currentGSR,
    required double previousGSR,
    required double currentTemp,
    required double previousTemp,
    required String currentArousal,
    required String previousArousal,
    required ActivityType? currentActivity,
    required ActivityType? previousActivity,
  }) {
    // Calculate changes
    final hrChange = currentHR - previousHR;
    final hrvChange = previousHRV - currentHRV; // Positive = decrease
    final gsrChange = currentGSR - previousGSR;
    final tempChange = currentTemp - previousTemp;

    // Biometric snapshot
    final snapshot = <String, double>{
      'heartRate': currentHR.toDouble(),
      'hrv': currentHRV,
      'gsr': currentGSR,
      'temperature': currentTemp,
      'hrChange': hrChange.toDouble(),
      'hrvChange': hrvChange,
      'gsrChange': gsrChange,
    };

    // 1. Activity Change Trigger
    if (previousActivity != null &&
        currentActivity != null &&
        previousActivity != currentActivity) {
      if (currentActivity == ActivityType.stressed ||
          (previousActivity == ActivityType.resting &&
              currentActivity == ActivityType.working)) {
        return _createActivityChangeTrigger(
          currentActivity,
          previousActivity,
          snapshot,
        );
      }
    }

    // 2. Physiological Spike Trigger
    if (hrChange >= _hrSpikeThreshold ||
        hrvChange >= _hrvDropThreshold ||
        gsrChange >= _gsrSpikeThreshold) {
      return _createPhysiologicalTrigger(
        hrChange,
        hrvChange,
        gsrChange,
        snapshot,
        currentActivity,
      );
    }

    // 3. Arousal State Change Trigger
    if (previousArousal != currentArousal) {
      if ((currentArousal == 'Stressed' || currentArousal == 'Highly Aroused') &&
          (previousArousal == 'Relaxed' ||
              previousArousal == 'Deep Calm' ||
              previousArousal == 'Alert')) {
        return _createArousalChangeTrigger(
          currentArousal,
          previousArousal,
          snapshot,
          currentActivity,
        );
      }
    }

    // 4. Environmental Trigger (Temperature)
    if (tempChange >= _tempRiseThreshold &&
        currentTemp > 37.5 &&
        currentActivity != ActivityType.exercising) {
      return _createEnvironmentalTrigger(tempChange, snapshot);
    }

    // 5. Time-based Pattern Trigger
    final hour = DateTime.now().hour;
    if (_isKnownStressTime(hour) &&
        (currentArousal == 'Stressed' || currentArousal == 'Highly Aroused')) {
      return _createTimeOfDayTrigger(hour, snapshot, currentActivity);
    }

    return null;
  }

  /// Create activity change trigger
  static StressTrigger _createActivityChangeTrigger(
    ActivityType current,
    ActivityType previous,
    Map<String, double> snapshot,
  ) {
    final intensity = _calculateIntensity(snapshot);
    final severity = _calculateSeverity(intensity);

    return StressTrigger(
      type: TriggerType.activityChange,
      severity: severity,
      timestamp: DateTime.now(),
      description:
          'Transition from ${previous.displayName} to ${current.displayName}',
      biometricSnapshot: snapshot,
      context: '${previous.emoji} → ${current.emoji}',
      intensity: intensity,
      recommendation: _getActivityChangeRecommendation(current, previous),
    );
  }

  /// Create physiological spike trigger
  static StressTrigger _createPhysiologicalTrigger(
    int hrChange,
    double hrvChange,
    double gsrChange,
    Map<String, double> snapshot,
    ActivityType? activity,
  ) {
    final intensity = _calculateIntensity(snapshot);
    final severity = _calculateSeverity(intensity);

    String description = 'Rapid physiological changes detected: ';
    final changes = <String>[];

    if (hrChange >= _hrSpikeThreshold) {
      changes.add('HR +${hrChange} BPM');
    }
    if (hrvChange >= _hrvDropThreshold) {
      changes.add('HRV -${hrvChange.toStringAsFixed(1)}ms');
    }
    if (gsrChange >= _gsrSpikeThreshold) {
      changes.add('GSR +${gsrChange.toStringAsFixed(2)}');
    }

    description += changes.join(', ');

    return StressTrigger(
      type: TriggerType.physiological,
      severity: severity,
      timestamp: DateTime.now(),
      description: description,
      biometricSnapshot: snapshot,
      context: activity?.displayName,
      intensity: intensity,
      recommendation:
          'Sudden physiological changes detected. Take deep breaths and pause current activity.',
    );
  }

  /// Create arousal state change trigger
  static StressTrigger _createArousalChangeTrigger(
    String current,
    String previous,
    Map<String, double> snapshot,
    ActivityType? activity,
  ) {
    final intensity = _calculateIntensity(snapshot);
    final severity = _calculateSeverity(intensity);

    return StressTrigger(
      type: TriggerType.pattern,
      severity: severity,
      timestamp: DateTime.now(),
      description: 'Arousal shift: $previous → $current',
      biometricSnapshot: snapshot,
      context: activity?.displayName ?? 'Unknown activity',
      intensity: intensity,
      recommendation:
          'Stress levels increasing. Consider taking a short break or practicing breathing exercises.',
    );
  }

  /// Create environmental trigger
  static StressTrigger _createEnvironmentalTrigger(
    double tempChange,
    Map<String, double> snapshot,
  ) {
    final intensity = _calculateIntensity(snapshot);
    final severity = _calculateSeverity(intensity);

    return StressTrigger(
      type: TriggerType.environmental,
      severity: severity,
      timestamp: DateTime.now(),
      description:
          'Elevated temperature (+${tempChange.toStringAsFixed(1)}°C) without physical activity',
      biometricSnapshot: snapshot,
      context: 'Possible environmental heat or fever',
      intensity: intensity,
      recommendation:
          'Check your environment. Ensure adequate ventilation and hydration.',
    );
  }

  /// Create time of day trigger
  static StressTrigger _createTimeOfDayTrigger(
    int hour,
    Map<String, double> snapshot,
    ActivityType? activity,
  ) {
    final intensity = _calculateIntensity(snapshot);
    final severity = _calculateSeverity(intensity);

    String timeDesc = _getTimeDescription(hour);

    return StressTrigger(
      type: TriggerType.timeOfDay,
      severity: severity,
      timestamp: DateTime.now(),
      description: 'Recurring stress during $timeDesc',
      biometricSnapshot: snapshot,
      context: activity?.displayName ?? 'Pattern observed',
      intensity: intensity,
      recommendation: _getTimeBasedRecommendation(hour),
    );
  }

  /// Check if hour is a known stress time
  static bool _isKnownStressTime(int hour) {
    // Common stress times: morning rush, midday, late afternoon
    return hour >= 8 && hour <= 9 || // Morning
        hour >= 12 && hour <= 13 || // Lunch
        hour >= 14 && hour <= 16 || // Afternoon
        hour >= 17 && hour <= 19; // Evening commute
  }

  /// Get time description
  static String _getTimeDescription(int hour) {
    if (hour >= 8 && hour <= 9) return 'morning hours (8-9am)';
    if (hour >= 12 && hour <= 13) return 'midday period (12-1pm)';
    if (hour >= 14 && hour <= 16) return 'afternoon (2-4pm)';
    if (hour >= 17 && hour <= 19) return 'evening hours (5-7pm)';
    return 'this time of day';
  }

  /// Calculate trigger intensity
  static double _calculateIntensity(Map<String, double> snapshot) {
    double intensity = 0.0;

    final hr = snapshot['heartRate'] ?? 0;
    final hrv = snapshot['hrv'] ?? 0;
    final gsr = snapshot['gsr'] ?? 0;

    // Heart rate contribution
    if (hr > 100) intensity += 0.3;
    if (hr > 110) intensity += 0.1;
    if (hr > 120) intensity += 0.1;

    // HRV contribution (lower is worse)
    if (hrv < 20) intensity += 0.2;
    if (hrv < 15) intensity += 0.1;
    if (hrv < 10) intensity += 0.1;

    // GSR contribution
    if (gsr > 0.3) intensity += 0.2;
    if (gsr > 0.5) intensity += 0.1;
    if (gsr > 0.7) intensity += 0.1;

    return intensity.clamp(0.0, 1.0);
  }

  /// Calculate severity from intensity
  static TriggerSeverity _calculateSeverity(double intensity) {
    if (intensity >= 0.8) return TriggerSeverity.critical;
    if (intensity >= 0.6) return TriggerSeverity.severe;
    if (intensity >= 0.4) return TriggerSeverity.moderate;
    return TriggerSeverity.mild;
  }

  /// Analyze triggers to find patterns
  static TriggerAnalysis analyzeTriggers(List<StressTrigger> triggers) {
    if (triggers.isEmpty) {
      return TriggerAnalysis(
        totalTriggers: 0,
        triggersByType: {},
        triggersBySeverity: {},
        triggersByHour: {},
        triggersByDay: {},
        patterns: [],
        avgIntensity: 0.0,
        mostCommonType: TriggerType.unknown,
        insights: [],
      );
    }

    // Count by type
    final byType = <TriggerType, int>{};
    final bySeverity = <TriggerSeverity, int>{};
    final byHour = <int, int>{};
    final byDay = <int, int>{};
    double totalIntensity = 0.0;

    for (final trigger in triggers) {
      byType[trigger.type] = (byType[trigger.type] ?? 0) + 1;
      bySeverity[trigger.severity] = (bySeverity[trigger.severity] ?? 0) + 1;
      byHour[trigger.timestamp.hour] =
          (byHour[trigger.timestamp.hour] ?? 0) + 1;
      byDay[trigger.timestamp.weekday] =
          (byDay[trigger.timestamp.weekday] ?? 0) + 1;
      totalIntensity += trigger.intensity;
    }

    // Find most common type
    TriggerType mostCommon = TriggerType.unknown;
    int maxCount = 0;
    byType.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = type;
      }
    });

    // Detect patterns
    final patterns = _detectPatterns(triggers, byType, byHour, byDay);

    // Generate insights
    final insights = _generateInsights(triggers, byType, bySeverity, byHour);

    return TriggerAnalysis(
      totalTriggers: triggers.length,
      triggersByType: byType,
      triggersBySeverity: bySeverity,
      triggersByHour: byHour,
      triggersByDay: byDay,
      patterns: patterns,
      avgIntensity: totalIntensity / triggers.length,
      mostCommonType: mostCommon,
      insights: insights,
    );
  }

  /// Detect recurring patterns
  static List<TriggerPattern> _detectPatterns(
    List<StressTrigger> triggers,
    Map<TriggerType, int> byType,
    Map<int, int> byHour,
    Map<int, int> byDay,
  ) {
    final patterns = <TriggerPattern>[];

    // For each trigger type with multiple occurrences
    byType.forEach((type, count) {
      if (count < 3) return; // Need at least 3 occurrences for a pattern

      final typeTriggers = triggers.where((t) => t.type == type).toList();

      final hours = <int>[];
      final days = <int>[];
      double totalIntensity = 0;

      for (final trigger in typeTriggers) {
        hours.add(trigger.timestamp.hour);
        days.add(trigger.timestamp.weekday);
        totalIntensity += trigger.intensity;
      }

      patterns.add(TriggerPattern(
        primaryType: type,
        description: _getPatternDescription(type, count),
        occurrences: count,
        commonHours: hours,
        commonDays: days,
        averageIntensity: totalIntensity / count,
        recommendation: _getPatternRecommendation(type),
      ));
    });

    // Sort by occurrence count
    patterns.sort((a, b) => b.occurrences.compareTo(a.occurrences));

    return patterns;
  }

  /// Generate insights from trigger data
  static List<String> _generateInsights(
    List<StressTrigger> triggers,
    Map<TriggerType, int> byType,
    Map<TriggerSeverity, int> bySeverity,
    Map<int, int> byHour,
  ) {
    final insights = <String>[];

    // Critical triggers
    final critical = bySeverity[TriggerSeverity.critical] ?? 0;
    if (critical > 0) {
      insights.add(
          '🆘 $critical critical stress events detected - immediate attention recommended');
    }

    // Most common trigger type
    if (byType.isNotEmpty) {
      final sorted = byType.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topType = sorted.first;
      insights.add(
          '${topType.key.icon} Most common trigger: ${topType.key.displayName} (${topType.value} events)');
    }

    // Time-based insights
    if (byHour.isNotEmpty) {
      final sorted = byHour.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final peakHour = sorted.first.key;
      insights
          .add('⏰ Peak stress time: ${_getTimeDescription(peakHour)}');
    }

    // Frequency insight
    if (triggers.length >= 10) {
      insights.add(
          '⚠️ High trigger frequency detected - consider stress management strategies');
    } else if (triggers.length <= 3) {
      insights
          .add('✅ Low trigger frequency - stress levels well-managed');
    }

    return insights;
  }

  /// Get pattern description
  static String _getPatternDescription(TriggerType type, int count) {
    return 'Recurring ${type.displayName.toLowerCase()} stress pattern ($count occurrences)';
  }

  /// Get pattern recommendation
  static String _getPatternRecommendation(TriggerType type) {
    switch (type) {
      case TriggerType.timeOfDay:
        return 'Schedule breaks or relaxation exercises during these times';
      case TriggerType.activityChange:
        return 'Prepare for transitions with brief mindfulness exercises';
      case TriggerType.environmental:
        return 'Optimize your environment (temperature, lighting, noise)';
      case TriggerType.physiological:
        return 'Focus on sleep quality, hydration, and nutrition';
      case TriggerType.workload:
        return 'Better time management and task prioritization needed';
      case TriggerType.social:
        return 'Set boundaries and communicate needs clearly';
      case TriggerType.pattern:
        return 'Identify and address underlying recurring stressors';
      case TriggerType.unknown:
        return 'Continue monitoring to identify trigger patterns';
    }
  }

  /// Get activity change recommendation
  static String _getActivityChangeRecommendation(
    ActivityType current,
    ActivityType previous,
  ) {
    if (current == ActivityType.stressed) {
      return 'Take immediate action: deep breathing, short break, or change environment';
    }
    if (previous == ActivityType.resting && current == ActivityType.working) {
      return 'Ease into work gradually. Start with simple tasks.';
    }
    return 'Monitor your response to this transition and adjust as needed';
  }

  /// Get time-based recommendation
  static String _getTimeBasedRecommendation(int hour) {
    if (hour >= 8 && hour <= 9) {
      return 'Morning stress detected. Consider earlier wake time or calming morning routine.';
    }
    if (hour >= 12 && hour <= 13) {
      return 'Midday stress. Ensure proper lunch break and hydration.';
    }
    if (hour >= 14 && hour <= 16) {
      return 'Afternoon dip. Take short breaks, go for walk, or have healthy snack.';
    }
    if (hour >= 17 && hour <= 19) {
      return 'Evening stress. Plan transition from work to home mindfully.';
    }
    return 'Recurring pattern at this time. Consider schedule adjustments.';
  }

  /// Get mitigation strategies for trigger types
  static List<MitigationStrategy> getMitigationStrategies(
    TriggerAnalysis analysis,
  ) {
    final strategies = <MitigationStrategy>[];

    // Generate strategies for top trigger types
    final sortedTypes = analysis.triggersByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTypes.take(3)) {
      strategies.add(_getStrategyForType(entry.key, entry.value));
    }

    return strategies;
  }

  /// Get specific strategy for trigger type
  static MitigationStrategy _getStrategyForType(
      TriggerType type, int occurrences) {
    switch (type) {
      case TriggerType.timeOfDay:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'Time-based Stress Management',
          shortTerm: 'Schedule breaks 15 minutes before typical trigger times',
          longTerm: 'Restructure daily schedule to minimize stress periods',
          actionSteps: [
            'Identify exact times of day stress occurs',
            'Block calendar for pre-emptive breaks',
            'Use morning/evening routines to buffer transitions',
            'Consider flexible work hours if possible',
          ],
          priority: occurrences >= 10 ? 5 : 3,
        );

      case TriggerType.activityChange:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'Transition Management',
          shortTerm: 'Use 2-minute breathing exercise before major transitions',
          longTerm: 'Build transition rituals into daily routine',
          actionSteps: [
            'Create buffer time between activities',
            'Use physical movement to mark transitions',
            'Practice mindful awareness during changes',
            'Prepare mentally before switching tasks',
          ],
          priority: occurrences >= 8 ? 4 : 3,
        );

      case TriggerType.physiological:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'Physiological Resilience Building',
          shortTerm: 'Deep breathing immediately when triggers detected',
          longTerm: 'Improve overall physical health and stress resilience',
          actionSteps: [
            'Regular exercise (30 min, 3-4x per week)',
            'Prioritize 7-8 hours quality sleep',
            'Stay hydrated throughout day',
            'Consider meditation or yoga practice',
          ],
          priority: 5,
        );

      case TriggerType.environmental:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'Environment Optimization',
          shortTerm: 'Adjust immediate surroundings (temp, light, noise)',
          longTerm: 'Create optimal workspace and home environment',
          actionSteps: [
            'Control temperature (68-72°F ideal)',
            'Optimize lighting (natural light preferred)',
            'Reduce noise with headphones or white noise',
            'Add plants or calming elements to space',
          ],
          priority: 3,
        );

      case TriggerType.workload:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'Workload Management',
          shortTerm: 'Delegate or postpone non-urgent tasks',
          longTerm: 'Develop sustainable work practices and boundaries',
          actionSteps: [
            'Use time blocking for focused work',
            'Learn to say no to non-essential commitments',
            'Break large tasks into smaller chunks',
            'Communicate capacity limits to stakeholders',
          ],
          priority: 4,
        );

      default:
        return MitigationStrategy(
          triggerType: type,
          strategy: 'General Stress Management',
          shortTerm: 'Take immediate breaks when stress detected',
          longTerm: 'Build comprehensive stress management toolkit',
          actionSteps: [
            'Continue monitoring to identify patterns',
            'Experiment with different coping strategies',
            'Seek professional guidance if needed',
            'Track what works and build on successes',
          ],
          priority: 2,
        );
    }
  }

  /// Save triggers to persistent storage
  static Future<void> saveTriggers(List<StressTrigger> triggers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = triggers.map((t) => t.toJson()).toList();
    await prefs.setString(_triggersKey, json.encode(jsonList));
  }

  /// Load triggers from persistent storage
  static Future<List<StressTrigger>> loadTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_triggersKey);

    if (jsonString == null) return [];

    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => StressTrigger.fromJson(j)).toList();
  }
}
