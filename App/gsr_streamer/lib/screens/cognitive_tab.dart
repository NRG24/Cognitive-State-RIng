import 'package:flutter/material.dart';
import '../services/biometric_monitor.dart';

class CognitiveTab extends StatelessWidget {
  final BiometricMonitor monitor;
  
  const CognitiveTab({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, child) {
        final cognitiveScore = monitor.cognitiveScore;
        final arousalLevel = monitor.arousalLevel;
        final arousalColor = monitor.arousalColor;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cognitive Score Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Cognitive Performance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: cognitiveScore / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCognitiveColor(cognitiveScore),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${cognitiveScore.round()}',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getCognitiveColor(cognitiveScore),
                                ),
                              ),
                              Text(
                                'SCORE',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getCognitiveDescription(cognitiveScore),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Arousal State Card
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_emotions, color: arousalColor, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Mental State',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: arousalColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: arousalColor.withOpacity(0.3), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arousalLevel,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: arousalColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getArousalDescription(arousalLevel),
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Detailed Insights
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.secondary, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Detailed Insights',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInsightSection(
                      'Heart Rate',
                      _getHRInsight(monitor.heartRate),
                      Icons.favorite,
                      const Color(0xFFFF2D55),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightSection(
                      'Heart Rate Variability',
                      _getHRVInsight(monitor.hrv),
                      Icons.timeline,
                      const Color(0xFF5856D6),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightSection(
                      'Blood Oxygen',
                      _getSpO2Insight(monitor.spo2),
                      Icons.water_drop,
                      const Color(0xFF64D2FF),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightSection(
                      'Skin Conductance',
                      _getGSRInsight(monitor.variabilityGSR),
                      Icons.waves,
                      const Color(0xFF32D74B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightSection(String title, String insight, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(
            insight,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Color _getCognitiveColor(double score) {
    if (score >= 85) return Colors.green.shade600;
    if (score >= 75) return Colors.lightGreen.shade600;
    if (score >= 65) return Colors.amber.shade600;
    if (score >= 50) return Colors.orange.shade600;
    if (score >= 35) return Colors.deepOrange.shade600;
    return Colors.red.shade600;
  }

  String _getHRInsight(int hr) {
    if (hr == 0) return 'No heart rate data available.';
    if (hr >= 60 && hr <= 85) {
      return 'Excellent resting heart rate. Your cardiovascular system is functioning optimally, providing ideal conditions for cognitive performance and focus.';
    } else if (hr >= 50 && hr <= 95) {
      return 'Good heart rate range. Your cardiovascular function supports healthy cognitive performance and mental clarity.';
    } else if (hr >= 40 && hr <= 105) {
      return 'Acceptable heart rate. While within normal limits, optimal cognitive performance may benefit from cardiovascular conditioning or relaxation.';
    } else if (hr < 40) {
      return 'Very low heart rate detected. This may indicate exceptional fitness or potential bradycardia. Monitor for symptoms and consult healthcare provider if concerned.';
    } else {
      return 'Elevated heart rate detected. This may indicate stress, anxiety, or physical exertion. Consider relaxation techniques and ensure adequate hydration.';
    }
  }

  String _getHRVInsight(double hrv) {
    if (hrv == 0) return 'No HRV data available.';
    if (hrv >= 40) {
      return 'Exceptional heart rate variability! High HRV indicates optimal autonomic nervous system balance, excellent stress resilience, and peak readiness for cognitive challenges. This is the ideal state for learning, problem-solving, and creative work.';
    } else if (hrv >= 25) {
      return 'Very good HRV indicating healthy autonomic balance. Your nervous system shows good flexibility and stress resilience, supporting excellent cognitive function and mental performance.';
    } else if (hrv >= 15) {
      return 'Good HRV levels. Your parasympathetic nervous system is functioning well, providing adequate recovery and cognitive capacity. This supports normal mental performance and stress management.';
    } else if (hrv >= 10) {
      return 'Low HRV detected. This suggests increased sympathetic dominance and reduced parasympathetic control. Your nervous system may be stressed, potentially impairing cognitive function and stress resilience.';
    } else {
      return 'Very low HRV. This indicates significant autonomic imbalance with potential sympathetic overdrive. This state is associated with psychological stress and impaired cognitive function. Consider stress management and recovery techniques.';
    }
  }

  String _getSpO2Insight(int spo2) {
    if (spo2 == 0) return 'No oxygen saturation data available.';
    if (spo2 >= 99) {
      return 'Excellent oxygen saturation! Your blood is carrying optimal oxygen levels, providing ideal conditions for brain function and cognitive performance.';
    } else if (spo2 >= 97) {
      return 'Very good oxygen levels. Your brain is receiving adequate oxygen for optimal cognitive function and mental clarity.';
    } else if (spo2 >= 95) {
      return 'Good oxygen saturation. Normal levels that support healthy brain function, though slightly below optimal.';
    } else if (spo2 >= 92) {
      return 'Moderate oxygen levels. While still in acceptable range, cognitive performance may be slightly affected. Consider deep breathing exercises.';
    } else if (spo2 >= 88) {
      return 'Low oxygen saturation detected. This may impact cognitive function, attention, and decision-making. Immediate attention to breathing and oxygenation recommended.';
    } else {
      return 'Very low oxygen levels detected. This significantly impacts brain function and cognitive performance. Seek immediate medical attention if persistent.';
    }
  }

  String _getGSRInsight(double variability) {
    if (variability == 0) return 'No GSR data available.';
    if (variability <= 0.03) {
      return 'Extremely stable GSR indicating deep relaxation and minimal sympathetic arousal. Perfect state for meditation, deep focus, and restorative activities. Your nervous system is in an ideal state for complex cognitive tasks.';
    } else if (variability <= 0.08) {
      return 'Very stable GSR showing excellent sympathetic nervous system control. This indicates calm alertness - an optimal state for learning, problem-solving, and creative thinking.';
    } else if (variability <= 0.15) {
      return 'Stable GSR with good autonomic control. You\'re in an engaged but not stressed state, excellent for most cognitive tasks and productive work.';
    } else if (variability <= 0.25) {
      return 'Moderate GSR variability indicating some sympathetic activation. You\'re alert and can handle complex tasks, though stress levels are slightly elevated.';
    } else if (variability <= 0.40) {
      return 'Elevated GSR variability showing increased sympathetic nervous system activity. This suggests moderate stress or emotional arousal. Consider breaks and stress management techniques.';
    } else if (variability <= 0.60) {
      return 'High GSR variability indicating significant sympathetic arousal and stress response. Your nervous system is actively responding to stressors. Break and relaxation strongly recommended.';
    } else {
      return 'Very high GSR variability showing intense sympathetic nervous system activation. This indicates high stress, strong emotional response, or fight-or-flight activation. Immediate stress management and relaxation techniques recommended.';
    }
  }

  String _getCognitiveDescription(double score) {
    if (score >= 85) return 'Peak Performance - Exceptional cognitive state';
    if (score >= 75) return 'High Performance - Excellent for complex tasks';
    if (score >= 65) return 'Good Performance - Suitable for most activities';
    if (score >= 50) return 'Moderate Performance - Best for routine tasks';
    if (score >= 35) return 'Low Performance - Consider rest and recovery';
    return 'Poor Performance - Prioritize rest and self-care';
  }

  String _getArousalDescription(String arousal) {
    switch (arousal) {
      case 'Deep Calm':
        return 'Deeply relaxed and centered. Optimal for meditation, reflection, and restorative activities.';
      case 'Relaxed':
        return 'Calm and comfortable. Excellent for learning, reading, and creative exploration.';
      case 'Alert':
        return 'Focused and attentive. Perfect for analysis, planning, and detailed work.';
      case 'Engaged':
        return 'Actively engaged and energized. Great for presentations, meetings, and collaborative work.';
      case 'Stressed':
        return 'Elevated stress levels. Take breaks, practice breathing exercises, and avoid complex decisions.';
      case 'Highly Aroused':
        return 'High stress detected. Immediate stress management recommended - step away from stressors.';
      default:
        return 'Monitoring your mental state and arousal patterns...';
    }
  }
}
