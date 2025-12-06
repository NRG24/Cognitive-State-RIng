import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/biometric_monitor.dart';
import '../widgets/activity_recognition_widget.dart';
import '../widgets/waveform_widget.dart';
import '../models/waveform_data.dart';

class OverviewTab extends StatelessWidget {
  final BiometricMonitor monitor;
  
  const OverviewTab({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, child) {
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildConnectionStatus(context),
            if (monitor.status == 'Connected!')
              _buildSessionInfo(context),
            _buildMetricCard(
              context: context,
              title: 'Heart Rate',
              value: monitor.heartRate.toString(),
              unit: 'BPM',
              color: const Color(0xFFFF2D55),
              icon: Icons.favorite,
              graphData: monitor.heartRateData,
            ),
            _buildMetricCard(
              context: context,
              title: 'Heart Rate Variability',
              value: monitor.hrv.toStringAsFixed(1),
              unit: 'ms',
              color: const Color(0xFF5856D6),
              icon: Icons.timeline,
              graphData: monitor.hrvData,
            ),
            _buildMetricCard(
              context: context,
              title: 'Blood Oxygen',
              value: monitor.spo2.toString(),
              unit: '%',
              color: const Color(0xFF64D2FF),
              icon: Icons.water_drop,
              graphData: monitor.spo2Data,
            ),
            _buildMetricCard(
              context: context,
              title: 'Galvanic Skin Response',
              value: monitor.baselineGSR.toStringAsFixed(1),
              unit: 'µS',
              color: const Color(0xFF32D74B),
              icon: Icons.waves,
              graphData: monitor.gsrData,
            ),
            _buildMetricCard(
              context: context,
              title: 'Temperature',
              value: monitor.fingerTemperature.toStringAsFixed(1),
              unit: '°C',
              color: const Color(0xFFFF9500),
              icon: Icons.thermostat,
              graphData: monitor.temperatureData,
            ),
            _buildArousalCard(context),
            const SizedBox(height: 16),
            
            // Real-time Waveforms
            const Text(
              'Real-time Waveforms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            WaveformWidget(
              waveformManager: monitor.waveformManager,
              type: WaveformType.heartRate,
              height: 180,
              showStats: true,
              showGrid: true,
            ),
            const SizedBox(height: 12),
            CompactWaveformWidget(
              waveformManager: monitor.waveformManager,
              type: WaveformType.gsr,
            ),
            const SizedBox(height: 12),
            CompactWaveformWidget(
              waveformManager: monitor.waveformManager,
              type: WaveformType.temperature,
            ),
            const SizedBox(height: 16),
            
            // Activity Recognition
            if (monitor.currentActivity != null)
              ActivityRecognitionWidget(
                currentActivity: monitor.currentActivity,
                activityHistory: monitor.activityHistory,
                transitions: monitor.activityTransitions,
              ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final isConnected = monitor.status == 'Connected!';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFF32D74B).withOpacity(0.1) : const Color(0xFFFF453A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? const Color(0xFF32D74B) : const Color(0xFFFF453A),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monitor.status,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF32D74B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF32D74B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    final duration = Duration(seconds: monitor.sessionDuration);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Session Duration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hours > 0 
                  ? '${hours}h ${minutes}m ${seconds}s'
                  : '${minutes}m ${seconds}s',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required List<double> graphData,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (graphData.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          graphData.length,
                          (i) => FlSpot(i.toDouble(), graphData[i]),
                        ),
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArousalCard(BuildContext context) {
    final arousalState = monitor.arousalLevel;
    final arousalColor = monitor.arousalColor;

    String arousalDescription;
    IconData arousalIcon;

    switch (arousalState) {
      case 'Deep Calm':
        arousalDescription = 'Very relaxed and at ease';
        arousalIcon = Icons.spa;
        break;
      case 'Relaxed':
        arousalDescription = 'Calm and comfortable';
        arousalIcon = Icons.self_improvement;
        break;
      case 'Alert':
        arousalDescription = 'Focused and attentive';
        arousalIcon = Icons.psychology;
        break;
      case 'Engaged':
        arousalDescription = 'Actively engaged';
        arousalIcon = Icons.bolt;
        break;
      case 'Stressed':
        arousalDescription = 'Heightened response detected';
        arousalIcon = Icons.warning_amber_rounded;
        break;
      case 'Highly Aroused':
        arousalDescription = 'Very high arousal';
        arousalIcon = Icons.local_fire_department;
        break;
      default:
        arousalDescription = 'Gathering data...';
        arousalIcon = Icons.hourglass_empty;
    }

    // Temperature context
    String tempContext = '';
    if (monitor.fingerTemperature > 37.5) {
      tempContext = ' 🤒 Elevated temperature detected';
    } else if (monitor.fingerTemperature > 37.0 && (arousalState == 'Engaged' || arousalState == 'Stressed' || arousalState == 'Highly Aroused')) {
      tempContext = ' 🏃 Possible physical activity';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: arousalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(arousalIcon, color: arousalColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Arousal State',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              arousalState,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: arousalColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              arousalDescription + tempContext,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: arousalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: arousalColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(arousalIcon, color: arousalColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    arousalState,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: arousalColor,
                    ),
                  ),
                ],
              ),
            ),
            if (monitor.gsrData.length > 10) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          monitor.gsrData.length,
                          (i) => FlSpot(i.toDouble(), monitor.gsrData[i]),
                        ),
                        isCurved: true,
                        color: arousalColor,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: arousalColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
