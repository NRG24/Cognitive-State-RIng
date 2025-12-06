import 'package:flutter/material.dart';
import '../models/waveform_data.dart';
import '../services/waveform_manager.dart';

/// Widget for displaying battery status
class BatteryWidget extends StatelessWidget {
  final BatteryManager batteryManager;
  final bool showDetails;

  const BatteryWidget({
    super.key,
    required this.batteryManager,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final battery = batteryManager.currentBattery;

    if (battery == null) {
      return _buildNoBatteryState();
    }

    if (showDetails) {
      return _buildDetailedView(battery);
    } else {
      return _buildCompactView(battery);
    }
  }

  Widget _buildNoBatteryState() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.battery_unknown, size: 32, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              'Battery status unavailable',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BatteryInfo battery) {
    final color = Color(battery.status.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            battery.statusIcon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Text(
            battery.percentageStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(BatteryInfo battery) {
    final color = Color(battery.status.colorValue);
    final trend = batteryManager.getBatteryTrend();
    final timeRemaining = batteryManager.getEstimatedTimeRemaining();
    final health = batteryManager.getBatteryHealth();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      battery.statusIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Battery',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        battery.percentageStr,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(battery.statusText, color),
              ],
            ),
            const SizedBox(height: 16),

            // Battery level indicator
            _buildBatteryLevelBar(battery.percentage, color),
            const SizedBox(height: 16),

            // Info grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Voltage',
                    '${battery.voltage.toStringAsFixed(2)}V',
                    Icons.flash_on,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Health',
                    health,
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Charging/Trend info
            if (battery.isCharging)
              _buildChargingInfo()
            else if (timeRemaining != null)
              _buildTimeRemainingInfo(timeRemaining)
            else if (trend != 0)
              _buildTrendInfo(trend),

            const SizedBox(height: 12),

            // Warnings
            if (batteryManager.isCritical)
              _buildWarning(
                'Critical Battery Level',
                'Device will shut down soon. Please charge immediately.',
                Colors.red,
              )
            else if (batteryManager.isLow)
              _buildWarning(
                'Low Battery',
                'Consider charging the device soon.',
                Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBatteryLevelBar(int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Battery Level',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: percentage > 50 ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.power, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Device is charging',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemainingInfo(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimated time remaining: $timeStr',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendInfo(double trend) {
    final isIncreasing = trend > 0;
    final color = isIncreasing ? Colors.green : Colors.orange;
    final icon = isIncreasing ? Icons.trending_up : Icons.trending_down;
    final text = isIncreasing
        ? 'Battery level increasing'
        : 'Battery level decreasing';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(String title, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact battery indicator for header/status bar
class CompactBatteryIndicator extends StatelessWidget {
  final BatteryManager batteryManager;

  const CompactBatteryIndicator({
    super.key,
    required this.batteryManager,
  });

  @override
  Widget build(BuildContext context) {
    final battery = batteryManager.currentBattery;

    if (battery == null) {
      return const SizedBox.shrink();
    }

    final color = Color(battery.status.colorValue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBatteryIcon(battery.percentage, battery.isCharging, color),
        const SizedBox(width: 6),
        Text(
          battery.percentageStr,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryIcon(int percentage, bool isCharging, Color color) {
    IconData icon;

    if (isCharging) {
      icon = Icons.battery_charging_full;
    } else if (percentage >= 90) {
      icon = Icons.battery_full;
    } else if (percentage >= 60) {
      icon = Icons.battery_5_bar;
    } else if (percentage >= 40) {
      icon = Icons.battery_4_bar;
    } else if (percentage >= 20) {
      icon = Icons.battery_2_bar;
    } else {
      icon = Icons.battery_alert;
    }

    return Icon(icon, size: 18, color: color);
  }
}
