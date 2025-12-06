import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stress_pattern.dart';
import '../models/session_data.dart';
import '../services/stress_analyzer.dart';

class StressPatternWidget extends StatelessWidget {
  final List<SessionData> sessions;
  final int daysToAnalyze;

  const StressPatternWidget({
    super.key,
    required this.sessions,
    this.daysToAnalyze = 7,
  });

  @override
  Widget build(BuildContext context) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysToAnalyze));
    final insights = StressAnalyzer.analyzePatterns(sessions, startDate, endDate);
    final dailySummaries = StressAnalyzer.generateDailySummaries(sessions, daysToAnalyze);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stress Overview Card
        _buildStressOverview(context, insights),
        const SizedBox(height: 16),
        
        // Patterns Detected
        if (insights.patterns.isNotEmpty)
          _buildPatternsCard(context, insights.patterns),
        if (insights.patterns.isNotEmpty)
          const SizedBox(height: 16),
        
        // Hourly Distribution Chart
        _buildHourlyDistribution(context, insights),
        const SizedBox(height: 16),
        
        // Daily Trend Chart
        if (dailySummaries.isNotEmpty)
          _buildDailyTrend(context, dailySummaries),
        if (dailySummaries.isNotEmpty)
          const SizedBox(height: 16),
        
        // Stress Spikes
        if (insights.stressSpikes.isNotEmpty)
          _buildStressSpikes(context, insights.stressSpikes),
      ],
    );
  }

  Widget _buildStressOverview(BuildContext context, StressInsights insights) {
    final stressColor = _getStressColor(insights.stressPercentage);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: stressColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Stress Analysis ($daysToAnalyze Days)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stress Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: stressColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stressColor.withOpacity(0.3), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStressIcon(insights.stressPercentage),
                    color: stressColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    insights.stressLevel,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: stressColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  '${insights.stressPercentage.toStringAsFixed(1)}%',
                  'Stress Time',
                  Colors.red.shade400,
                ),
                _buildStatColumn(
                  context,
                  '${insights.calmPercentage.toStringAsFixed(1)}%',
                  'Calm Time',
                  Colors.green.shade400,
                ),
                _buildStatColumn(
                  context,
                  '${insights.stressSpikes.length}',
                  'Stress Spikes',
                  Colors.orange.shade400,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Time breakdown
            _buildTimeBreakdown(context, insights),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBreakdown(BuildContext context, StressInsights insights) {
    final total = insights.totalMinutes.toDouble();
    if (total == 0 || total.isNaN || total.isInfinite) return const SizedBox();

    // Safely calculate fractions with clamping
    double safeFraction(double value) {
      final result = value / total;
      if (result.isNaN || result.isInfinite) return 0.0;
      return result.clamp(0.0, 1.0);
    }

    final stressFraction = safeFraction(insights.stressMinutes.toDouble());
    final alertFraction = safeFraction(insights.alertMinutes.toDouble());
    final calmFraction = safeFraction(insights.calmMinutes.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                // Stress
                if (stressFraction > 0)
                  Expanded(
                    flex: (stressFraction * 100).round(),
                    child: Container(color: Colors.red.shade400),
                  ),
                // Alert
                if (alertFraction > 0)
                  Expanded(
                    flex: (alertFraction * 100).round(),
                    child: Container(color: Colors.amber.shade400),
                  ),
                // Calm
                if (calmFraction > 0)
                  Expanded(
                    flex: (calmFraction * 100).round(),
                    child: Container(color: Colors.green.shade400),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Stress', Colors.red.shade400),
            _buildLegendItem('Alert', Colors.amber.shade400),
            _buildLegendItem('Calm', Colors.green.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPatternsCard(BuildContext context, List<String> patterns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pattern, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Detected Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...patterns.map((pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pattern,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyDistribution(BuildContext context, StressInsights insights) {
    if (insights.hourlyStressDistribution.isEmpty) {
      return const SizedBox();
    }

    final hours = List.generate(24, (i) => i);
    final data = hours.map((hour) => 
      FlSpot(hour.toDouble(), (insights.hourlyStressDistribution[hour] ?? 0).toDouble())
    ).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Stress by Time of Day',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}m',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}h',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: Colors.red.shade400,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.shade400.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toInt()}:00\n${spot.y.toInt()} min',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTrend(BuildContext context, List<DailyStressSummary> summaries) {
    final sortedSummaries = summaries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final data = sortedSummaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.stressPercentage);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Daily Stress Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedSummaries.length) {
                            return const Text('');
                          }
                          final date = sortedSummaries[value.toInt()].date;
                          return Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: Colors.orange.shade400,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange.shade400,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.shade400.withOpacity(0.2),
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

  Widget _buildStressSpikes(BuildContext context, List<StressSpike> spikes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Stress Spikes (${spikes.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...spikes.take(5).map((spike) => _buildSpikeItem(context, spike)),
            if (spikes.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${spikes.length - 5} more spikes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpikeItem(BuildContext context, StressSpike spike) {
    final dateStr = '${spike.startTime.month}/${spike.startTime.day}';
    final timeStr = '${spike.startTime.hour.toString().padLeft(2, '0')}:${spike.startTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade400.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 6),
              Text(
                '$dateStr at $timeStr (${spike.durationMinutes}min)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpikeMetric('HR', '${spike.maxHeartRate}', Colors.red.shade300),
              const SizedBox(width: 16),
              _buildSpikeMetric('HRV', '${spike.minHRV.toStringAsFixed(0)}', Colors.purple.shade300),
              const SizedBox(width: 16),
              _buildSpikeMetric('GSR', spike.maxGSR.toStringAsFixed(1), Colors.green.shade300),
            ],
          ),
          if (spike.possibleTrigger != null) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${spike.possibleTrigger}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpikeMetric(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStressColor(double percentage) {
    if (percentage < 15) return Colors.green.shade600;
    if (percentage < 30) return Colors.lightGreen.shade600;
    if (percentage < 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getStressIcon(double percentage) {
    if (percentage < 15) return Icons.sentiment_very_satisfied;
    if (percentage < 30) return Icons.sentiment_satisfied;
    if (percentage < 50) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
}
