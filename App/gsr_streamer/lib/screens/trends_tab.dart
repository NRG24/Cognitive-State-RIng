import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/biometric_monitor.dart';
import '../models/models.dart';
import '../widgets/stress_pattern_widget.dart';
import '../widgets/trigger_identification_widget.dart';

class TrendsTab extends StatelessWidget {
  final BiometricMonitor monitor;
  
  const TrendsTab({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, child) {
        final sessions = monitor.sessions;
        final todaysSessions = sessions.where((s) => 
          s.startTime.day == DateTime.now().day &&
          s.startTime.month == DateTime.now().month &&
          s.startTime.year == DateTime.now().year
        ).toList();
        
        final weekSessions = sessions.where((s) => 
          s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ).toList();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trigger Identification (NEW!)
            if (monitor.stressTriggers.isNotEmpty)
              TriggerIdentificationWidget(
                triggers: monitor.stressTriggers,
                analysis: monitor.triggerAnalysis,
              ),
            if (monitor.stressTriggers.isNotEmpty)
              const SizedBox(height: 16),
            
            // Stress Pattern Analysis
            if (sessions.isNotEmpty)
              StressPatternWidget(sessions: sessions, daysToAnalyze: 7),
            if (sessions.isNotEmpty)
              const SizedBox(height: 16),
            
            // Statistics Summary Cards
            _buildStatisticsSummary(context, sessions, todaysSessions, weekSessions),
            const SizedBox(height: 16),
            
            // Today's Performance
            _buildTodayPerformance(context, todaysSessions),
            const SizedBox(height: 16),
            
            // Weekly Trends
            _buildWeeklyTrends(context, weekSessions),
            const SizedBox(height: 16),
            
            // Arousal Distribution
            if (todaysSessions.isNotEmpty)
              _buildArousalDistribution(context, todaysSessions),
            const SizedBox(height: 16),
            
            // Real-time Charts
            _buildRealtimeCharts(context),
            const SizedBox(height: 16),
            
            // Session History
            _buildSessionHistory(context, sessions),
          ],
        );
      },
    );
  }
  
  Widget _buildStatisticsSummary(BuildContext context, List<SessionData> allSessions, 
      List<SessionData> todaysSessions, List<SessionData> weekSessions) {
    
    final todayMinutes = todaysSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final weekMinutes = weekSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final allMinutes = allSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text('Statistics Summary', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(context, 'Today', '${todaysSessions.length}', 'sessions', '${todayMinutes}min'),
                _buildStatCard(context, 'This Week', '${weekSessions.length}', 'sessions', '${weekMinutes}min'),
                _buildStatCard(context, 'All Time', '${allSessions.length}', 'sessions', '${allMinutes}min'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, String subtitle, String extra) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            )),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              color: Theme.of(context).colorScheme.primary,
            )),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(extra, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodayPerformance(BuildContext context, List<SessionData> todaysSessions) {
    if (todaysSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text('No sessions today yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Connect your device to start tracking', 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
            ],
          ),
        ),
      );
    }
    
    final avgCogScore = todaysSessions.fold<double>(0, (sum, s) => sum + s.avgCognitiveScore) / todaysSessions.length;
    final avgHR = todaysSessions.fold<double>(0, (sum, s) => sum + s.avgHeartRate) / todaysSessions.length;
    final avgHRV = todaysSessions.fold<double>(0, (sum, s) => sum + s.avgHRV) / todaysSessions.length;
    final avgSpO2 = todaysSessions.fold<double>(0, (sum, s) => sum + s.avgSpO2) / todaysSessions.length;
    final avgTemp = todaysSessions.fold<double>(0, (sum, s) => sum + s.avgTemperature) / todaysSessions.length;
    final totalStress = todaysSessions.fold<int>(0, (sum, s) => sum + s.stressEvents);
    final totalCalm = todaysSessions.fold<int>(0, (sum, s) => sum + s.calmPeriods);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue.shade400, size: 24),
                const SizedBox(width: 12),
                Text('Today\'s Performance', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(context, 'Cognitive Score', avgCogScore.toStringAsFixed(1), 
              Icons.psychology, Colors.purple.shade400),
            _buildMetricRow(context, 'Avg Heart Rate', '${avgHR.toStringAsFixed(0)} BPM', 
              Icons.favorite, Colors.red.shade400),
            _buildMetricRow(context, 'Avg HRV', '${avgHRV.toStringAsFixed(1)} ms', 
              Icons.timeline, Colors.indigo.shade400),
            _buildMetricRow(context, 'Avg SpO2', '${avgSpO2.toStringAsFixed(0)}%', 
              Icons.water_drop, Colors.blue.shade400),
            _buildMetricRow(context, 'Avg Temperature', '${avgTemp.toStringAsFixed(1)}°C', 
              Icons.thermostat, Colors.orange.shade400),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.spa, color: Colors.green.shade400, size: 32),
                    const SizedBox(height: 4),
                    Text('$totalCalm', style: Theme.of(context).textTheme.titleLarge),
                    Text('Calm Periods', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade400, size: 32),
                    const SizedBox(height: 4),
                    Text('$totalStress', style: Theme.of(context).textTheme.titleLarge),
                    Text('Stress Events', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(BuildContext context, String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          )),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyTrends(BuildContext context, List<SessionData> weekSessions) {
    if (weekSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text('No weekly data yet', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }
    
    // Group by day
    Map<String, List<SessionData>> dayGroups = {};
    for (var session in weekSessions) {
      final key = '${session.startTime.month}/${session.startTime.day}';
      dayGroups.putIfAbsent(key, () => []).add(session);
    }
    
    // Calculate daily averages
    List<FlSpot> cogScoreSpots = [];
    List<FlSpot> hrSpots = [];
    int index = 0;
    
    dayGroups.forEach((day, sessions) {
      final avgCog = sessions.fold<double>(0, (sum, s) => sum + s.avgCognitiveScore) / sessions.length;
      final avgHR = sessions.fold<double>(0, (sum, s) => sum + s.avgHeartRate) / sessions.length;
      cogScoreSpots.add(FlSpot(index.toDouble(), avgCog));
      hrSpots.add(FlSpot(index.toDouble(), avgHR));
      index++;
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.green.shade400, size: 24),
                const SizedBox(width: 12),
                Text('Weekly Trends', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Cognitive Score', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cogScoreSpots,
                      isCurved: true,
                      color: Colors.purple.shade400,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.shade400.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Heart Rate', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: hrSpots,
                      isCurved: true,
                      color: Colors.red.shade400,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.shade400.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArousalDistribution(BuildContext context, List<SessionData> sessions) {
    // Aggregate arousal time across all sessions
    Map<String, int> totalArousal = {};
    for (var session in sessions) {
      session.arousalDistribution.forEach((state, time) {
        totalArousal[state] = (totalArousal[state] ?? 0) + time;
      });
    }
    
    final total = totalArousal.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.amber.shade400, size: 24),
                const SizedBox(width: 12),
                Text('Today\'s Arousal Distribution', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...totalArousal.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              final minutes = (entry.value / 60).toStringAsFixed(0);
              return _buildArousalBar(context, entry.key, percentage, minutes);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArousalBar(BuildContext context, String state, String percentage, String minutes) {
    Color color;
    switch (state) {
      case 'Deep Calm':
        color = Colors.indigo.shade600;
        break;
      case 'Relaxed':
        color = Colors.teal.shade500;
        break;
      case 'Alert':
        color = Colors.blue.shade600;
        break;
      case 'Engaged':
        color = Colors.amber.shade600;
        break;
      case 'Stressed':
        color = Colors.orange.shade600;
        break;
      case 'Highly Aroused':
        color = Colors.red.shade600;
        break;
      default:
        color = Colors.grey.shade600;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(state, style: Theme.of(context).textTheme.bodyMedium),
              Text('$percentage% ($minutes min)', 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: double.parse(percentage) / 100,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRealtimeCharts(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text('Real-time Data', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Heart Rate', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: monitor.heartRateData.isNotEmpty ? LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monitor.heartRateData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFFFF2D55),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ) : Center(child: Text('No data', style: Theme.of(context).textTheme.bodySmall)),
            ),
            const SizedBox(height: 16),
            Text('GSR', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: monitor.gsrData.isNotEmpty ? LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monitor.gsrData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF32D74B),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ) : Center(child: Text('No data', style: Theme.of(context).textTheme.bodySmall)),
            ),
            const SizedBox(height: 16),
            Text('Temperature', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: monitor.temperatureData.isNotEmpty ? LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monitor.temperatureData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFFFF9500),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ) : Center(child: Text('No data', style: Theme.of(context).textTheme.bodySmall)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionHistory(BuildContext context, List<SessionData> sessions) {
    if (sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text('No session history', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }
    
    // Show last 10 sessions
    final recentSessions = sessions.reversed.take(10).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                Text('Recent Sessions', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...recentSessions.map((session) => _buildSessionCard(context, session)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionCard(BuildContext context, SessionData session) {
    final dateStr = '${session.startTime.month}/${session.startTime.day} ${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              )),
              Text('${session.durationMinutes} min', 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSessionStat(context, 'Cognitive', session.avgCognitiveScore.toStringAsFixed(0), Colors.purple.shade400),
              _buildSessionStat(context, 'HR', '${session.avgHeartRate.toStringAsFixed(0)}', Colors.red.shade400),
              _buildSessionStat(context, 'HRV', '${session.avgHRV.toStringAsFixed(0)}', Colors.indigo.shade400),
              _buildSessionStat(context, 'SpO2', '${session.avgSpO2.toStringAsFixed(0)}%', Colors.blue.shade400),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        )),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white60,
        )),
      ],
    );
  }
}

