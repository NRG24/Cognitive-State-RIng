import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/biometric_monitor.dart';

class SettingsTab extends StatelessWidget {
  final BiometricMonitor monitor;
  
  const SettingsTab({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // App Settings Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.notifications, 
                      color: monitor.notificationsEnabled 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey),
                    title: const Text('Notifications'),
                    subtitle: Text(monitor.notificationsEnabled 
                      ? 'Receive alerts for stress and arousal changes' 
                      : 'Notifications are disabled'),
                    trailing: Switch(
                      value: monitor.notificationsEnabled,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        monitor.toggleNotifications();
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.vibration, 
                      color: Theme.of(context).colorScheme.primary),
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Feel vibrations for state changes'),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Device Connection Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.bluetooth, 
                      color: Theme.of(context).colorScheme.primary),
                    title: const Text('Device Status'),
                    subtitle: Text(monitor.status),
                    trailing: monitor.status != 'Connected!' 
                        ? ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              monitor.startScan();
                            },
                            child: const Text('Connect'),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Today's Statistics Card
            Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Today\'s Statistics', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: monitor,
                  builder: (context, child) {
                    final todayStats = monitor.todayStats;
                    final hasTodayData = todayStats.isNotEmpty && todayStats['sessions'] > 0;
                    
                    if (!hasTodayData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No sessions recorded today'),
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        _buildStatRow(context, 'Total Sessions', '${todayStats['sessions']}'),
                        _buildStatRow(context, 'Total Duration', _formatDuration(todayStats['totalDuration'] ?? 0)),
                        _buildStatRow(context, 'Avg Heart Rate', '${todayStats['avgHeartRate']?.toStringAsFixed(1) ?? '0'} BPM'),
                        _buildStatRow(context, 'Max Heart Rate', '${todayStats['maxHeartRate']} BPM'),
                        _buildStatRow(context, 'Min Heart Rate', '${todayStats['minHeartRate']} BPM'),
                        _buildStatRow(context, 'Avg HRV', '${todayStats['avgHRV']?.toStringAsFixed(1) ?? '0'} ms'),
                        _buildStatRow(context, 'Avg SpO2', '${todayStats['avgSpO2']?.toStringAsFixed(1) ?? '0'}%'),
                        _buildStatRow(context, 'Avg Temperature', '${todayStats['avgTemp']?.toStringAsFixed(1) ?? '0'}°C'),
                        _buildStatRow(context, 'Avg Cognitive Score', '${todayStats['avgCognitiveScore']?.toStringAsFixed(0) ?? '0'}'),
                        _buildStatRow(context, 'Stress Events', '${todayStats['stressEvents'] ?? 0}'),
                        _buildStatRow(context, 'Calm Periods', '${todayStats['calmPeriods'] ?? 0}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Historical Sessions Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Recent Sessions', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: monitor,
                  builder: (context, child) {
                    final sessions = monitor.historicalSessions;
                    
                    if (sessions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No historical sessions'),
                        ),
                      );
                    }
                    
                    // Show last 10 sessions
                    final recentSessions = sessions.reversed.take(10).toList();
                    
                    return Column(
                      children: recentSessions.map((session) {
                        final startTime = DateTime.parse(session['startTime']);
                        final duration = session['duration'] as int;
                        final avgHR = session['avgHeartRate'] as double;
                        final avgScore = session['avgCognitiveScore'] as double;
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.monitor_heart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${_formatDuration(duration)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${startTime.month}/${startTime.day}/${startTime.year} • HR: ${avgHR.toStringAsFixed(0)} • Score: ${avgScore.toStringAsFixed(0)}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Biometric Monitor v1.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'This app monitors your biometric data using a XIAO nRF52840 with MAX30102 sensor and GSR sensor. '
                    'It provides real-time analysis of your cognitive performance and arousal state.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
