import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity_type.dart';
import '../services/activity_recognizer.dart';

class ActivityRecognitionWidget extends StatelessWidget {
  final ActivityDetection? currentActivity;
  final List<ActivityDetection> activityHistory;
  final List<ActivityTransition> transitions;

  const ActivityRecognitionWidget({
    super.key,
    required this.currentActivity,
    required this.activityHistory,
    required this.transitions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Activity Card
        _buildCurrentActivityCard(context),
        const SizedBox(height: 16),
        
        // Activity Stats
        if (activityHistory.isNotEmpty)
          _buildActivityStats(context),
        if (activityHistory.isNotEmpty)
          const SizedBox(height: 16),
        
        // Activity Timeline
        if (activityHistory.length > 5)
          _buildActivityTimeline(context),
        if (activityHistory.length > 5)
          const SizedBox(height: 16),
        
        // Recent Transitions
        if (transitions.isNotEmpty)
          _buildRecentTransitions(context),
      ],
    );
  }

  Widget _buildCurrentActivityCard(BuildContext context) {
    if (currentActivity == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(
                  'Detecting Activity...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activity = currentActivity!;
    final activityColor = _getActivityColor(activity.activityType);
    final durationStr = _formatDuration(activity.duration);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: activityColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Current Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Activity Type Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: activityColor.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Text(
                    activity.activityType.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.activityType.displayName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: activityColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.activityType.description,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Confidence and Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  '${(activity.confidence * 100).toStringAsFixed(0)}%',
                  'Confidence',
                  _getConfidenceColor(activity.confidence),
                ),
                Container(width: 1, height: 40, color: Colors.grey[700]),
                _buildMetricColumn(
                  durationStr,
                  'Duration',
                  Colors.blue.shade400,
                ),
                Container(width: 1, height: 40, color: Colors.grey[700]),
                _buildMetricColumn(
                  activity.confidenceLevel,
                  'Level',
                  _getConfidenceColor(activity.confidence),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activityColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: activityColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.activityType.recommendation,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStats(BuildContext context) {
    final stats = ActivityRecognizer.generateStats(
      activityHistory,
      Duration(minutes: activityHistory.length),
    );

    final insights = ActivityRecognizer.getInsights(stats);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Activity Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dominant Activity
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getActivityColor(stats.dominantActivity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    stats.dominantActivity.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dominant Activity',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          stats.summary,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Activity Breakdown
            ...ActivityType.values.where((type) {
              final duration = stats.durationByActivity[type] ?? 0;
              return duration > 0;
            }).map((type) {
              final duration = stats.durationByActivity[type]!;
              final percentage = stats.getPercentage(type);
              return _buildActivityBar(type, duration, percentage);
            }),
            
            // Insights
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBar(ActivityType type, int duration, double percentage) {
    final color = _getActivityColor(type);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    type.displayName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '${duration}m (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(BuildContext context) {
    // Show last 20 activities
    final recentActivities = activityHistory.reversed.take(20).toList().reversed.toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentActivities.length,
                itemBuilder: (context, index) {
                  final activity = recentActivities[index];
                  return _buildTimelineItem(activity);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ActivityDetection activity) {
    final color = _getActivityColor(activity.activityType);
    final time = '${activity.timestamp.hour}:${activity.timestamp.minute.toString().padLeft(2, '0')}';
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                activity.activityType.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            activity.activityType.displayName,
            style: const TextStyle(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransitions(BuildContext context) {
    final recentTransitions = transitions.reversed.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Recent Transitions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentTransitions.map((transition) => _buildTransitionItem(transition)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionItem(ActivityTransition transition) {
    final fromColor = _getActivityColor(transition.fromActivity);
    final toColor = _getActivityColor(transition.toActivity);
    final timeStr = '${transition.timestamp.hour}:${transition.timestamp.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: toColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // From Activity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: fromColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              transition.fromActivity.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          // To Activity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: toColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              transition.toActivity.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transition.transitionName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (transition.trigger != null)
                  Text(
                    transition.trigger!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.resting:
        return Colors.green.shade400;
      case ActivityType.working:
        return Colors.blue.shade400;
      case ActivityType.exercising:
        return Colors.orange.shade400;
      case ActivityType.sleeping:
        return Colors.indigo.shade400;
      case ActivityType.stressed:
        return Colors.red.shade400;
      case ActivityType.recovering:
        return Colors.teal.shade400;
      case ActivityType.unknown:
        return Colors.grey.shade400;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green.shade400;
    if (confidence >= 0.6) return Colors.amber.shade400;
    return Colors.orange.shade400;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}
