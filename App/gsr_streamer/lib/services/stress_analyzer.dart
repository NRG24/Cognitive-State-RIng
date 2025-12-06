import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/session_data.dart';
import '../models/stress_pattern.dart';

/// Service for analyzing stress patterns over time
class StressAnalyzer {
  static const String _spikesKey = 'stress_spikes';
  
  /// Analyze stress patterns from sessions
  static StressInsights analyzePatterns(
    List<SessionData> sessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (sessions.isEmpty) {
      return StressInsights(
        periodStart: startDate,
        periodEnd: endDate,
        totalMinutes: 0,
        stressMinutes: 0,
        calmMinutes: 0,
        alertMinutes: 0,
        stressSpikes: [],
        hourlyStressDistribution: {},
        avgStressLevel: 0,
        patterns: [],
      );
    }

    // Filter sessions in date range
    final relevantSessions = sessions.where((s) =>
        s.startTime.isAfter(startDate) && s.startTime.isBefore(endDate));

    int totalMinutes = 0;
    int stressMinutes = 0;
    int calmMinutes = 0;
    int alertMinutes = 0;
    Map<int, int> hourlyStress = {};
    List<StressSpike> spikes = [];

    for (final session in relevantSessions) {
      totalMinutes += session.durationMinutes;
      
      // Calculate stress/calm time from arousal distribution
      final stressed = (session.arousalDistribution['Stressed'] ?? 0);
      final highlyAroused = (session.arousalDistribution['Highly Aroused'] ?? 0);
      final deepCalm = (session.arousalDistribution['Deep Calm'] ?? 0);
      final relaxed = (session.arousalDistribution['Relaxed'] ?? 0);
      final alert = (session.arousalDistribution['Alert'] ?? 0);
      final engaged = (session.arousalDistribution['Engaged'] ?? 0);

      stressMinutes += (stressed + highlyAroused) ~/ 60;
      calmMinutes += (deepCalm + relaxed) ~/ 60;
      alertMinutes += (alert + engaged) ~/ 60;

      // Track hourly distribution
      final hour = session.startTime.hour;
      final sessionStress = (stressed + highlyAroused) ~/ 60;
      hourlyStress[hour] = (hourlyStress[hour] ?? 0) + sessionStress;

      // Detect stress spikes (sessions with >50% stress time)
      final sessionDuration = session.durationMinutes * 60;
      if (sessionDuration > 0 &&
          (stressed + highlyAroused) / sessionDuration > 0.5) {
        spikes.add(StressSpike(
          startTime: session.startTime,
          endTime: session.endTime,
          peakArousal: highlyAroused > stressed ? 'Highly Aroused' : 'Stressed',
          maxGSR: session.avgGSR,
          maxHeartRate: session.avgHeartRate.toInt(),
          minHRV: session.avgHRV,
          possibleTrigger: _detectTrigger(session.startTime),
        ));
      }
    }

    // Detect patterns
    final patterns = _detectPatterns(
      sessions: relevantSessions.toList(),
      hourlyStress: hourlyStress,
      spikes: spikes,
    );

    final avgStress = totalMinutes > 0 ? (stressMinutes / totalMinutes).toDouble() : 0.0;

    return StressInsights(
      periodStart: startDate,
      periodEnd: endDate,
      totalMinutes: totalMinutes,
      stressMinutes: stressMinutes,
      calmMinutes: calmMinutes,
      alertMinutes: alertMinutes,
      stressSpikes: spikes,
      hourlyStressDistribution: hourlyStress,
      avgStressLevel: avgStress,
      patterns: patterns,
    );
  }

  /// Generate daily stress summaries
  static List<DailyStressSummary> generateDailySummaries(
    List<SessionData> sessions,
    int days,
  ) {
    final summaries = <DailyStressSummary>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));
      
      final daySessions = sessions.where((s) =>
          s.startTime.isAfter(date) && s.startTime.isBefore(nextDate)).toList();

      if (daySessions.isEmpty) continue;

      int totalMinutes = 0;
      int stressMinutes = 0;
      int calmMinutes = 0;
      int spikes = 0;
      double totalCognitiveScore = 0;
      Map<String, int> arousalDist = {};

      for (final session in daySessions) {
        totalMinutes += session.durationMinutes;
        totalCognitiveScore += session.avgCognitiveScore;

        final stressed = (session.arousalDistribution['Stressed'] ?? 0);
        final highlyAroused = (session.arousalDistribution['Highly Aroused'] ?? 0);
        final deepCalm = (session.arousalDistribution['Deep Calm'] ?? 0);
        final relaxed = (session.arousalDistribution['Relaxed'] ?? 0);

        stressMinutes += (stressed + highlyAroused) ~/ 60;
        calmMinutes += (deepCalm + relaxed) ~/ 60;

        // Count stress spikes
        if ((stressed + highlyAroused) / (session.durationMinutes * 60) > 0.5) {
          spikes++;
        }

        // Aggregate arousal distribution
        session.arousalDistribution.forEach((key, value) {
          arousalDist[key] = (arousalDist[key] ?? 0) + value;
        });
      }

      // Find dominant state
      String dominantState = 'Alert';
      int maxTime = 0;
      arousalDist.forEach((state, time) {
        if (time > maxTime) {
          maxTime = time;
          dominantState = state;
        }
      });

      summaries.add(DailyStressSummary(
        date: date,
        totalSessions: daySessions.length,
        totalMinutes: totalMinutes,
        stressMinutes: stressMinutes,
        calmMinutes: calmMinutes,
        stressSpikes: spikes,
        avgCognitiveScore: daySessions.isNotEmpty
            ? totalCognitiveScore / daySessions.length
            : 0,
        dominantState: dominantState,
        arousalDistribution: arousalDist,
      ));
    }

    return summaries;
  }

  /// Detect patterns from stress data
  static List<String> _detectPatterns({
    required List<SessionData> sessions,
    required Map<int, int> hourlyStress,
    required List<StressSpike> spikes,
  }) {
    final patterns = <String>[];

    // Pattern 1: Time of day stress
    if (hourlyStress.isNotEmpty) {
      final sortedHours = hourlyStress.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedHours.isNotEmpty) {
        final peakHour = sortedHours.first.key;
        if (peakHour >= 6 && peakHour < 12) {
          patterns.add('🌅 Morning stress pattern detected');
        } else if (peakHour >= 12 && peakHour < 17) {
          patterns.add('☀️ Afternoon stress pattern detected');
        } else if (peakHour >= 17 && peakHour < 21) {
          patterns.add('🌆 Evening stress pattern detected');
        }
      }
    }

    // Pattern 2: Frequent stress spikes
    if (spikes.length > 5) {
      patterns.add('⚠️ Frequent stress spikes detected (${spikes.length} events)');
    }

    // Pattern 3: Weekday patterns
    final weekdayStress = <int, int>{};
    for (final session in sessions) {
      final weekday = session.startTime.weekday;
      final stressed = (session.arousalDistribution['Stressed'] ?? 0);
      final highlyAroused = (session.arousalDistribution['Highly Aroused'] ?? 0);
      weekdayStress[weekday] = (weekdayStress[weekday] ?? 0) + stressed + highlyAroused;
    }

    if (weekdayStress.isNotEmpty) {
      final sortedDays = weekdayStress.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedDays.isNotEmpty) {
        final stressDay = sortedDays.first.key;
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][stressDay - 1];
        patterns.add('📅 Highest stress on ${dayName}s');
      }
    }

    // Pattern 4: Temperature correlation
    final highTempSessions = sessions.where((s) => s.avgTemperature > 37.0).toList();
    if (highTempSessions.length > sessions.length * 0.3) {
      patterns.add('🌡️ Elevated temperature often correlates with stress');
    }

    // Pattern 5: Low HRV pattern
    final lowHRVCount = sessions.where((s) => s.avgHRV < 20).length;
    if (lowHRVCount > sessions.length * 0.4) {
      patterns.add('💔 Low HRV pattern - reduced stress resilience');
    }

    return patterns;
  }

  /// Detect possible trigger based on time of day
  static String _detectTrigger(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 8 && hour <= 9) return 'Morning commute/start of work';
    if (hour >= 11 && hour <= 13) return 'Midday/lunch period';
    if (hour >= 14 && hour <= 16) return 'Afternoon work period';
    if (hour >= 17 && hour <= 19) return 'Evening commute/end of work';
    if (hour >= 20 && hour <= 22) return 'Evening activities';
    if (hour >= 0 && hour <= 2) return 'Late night activity';
    
    return 'Unknown trigger';
  }

  /// Save stress patterns to persistent storage
  static Future<void> saveStressSpikes(List<StressSpike> spikes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = spikes.map((s) => s.toJson()).toList();
    await prefs.setString(_spikesKey, json.encode(jsonList));
  }

  /// Load stress spikes from persistent storage
  static Future<List<StressSpike>> loadStressSpikes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_spikesKey);
    
    if (jsonString == null) return [];
    
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((j) => StressSpike.fromJson(j)).toList();
  }
}
