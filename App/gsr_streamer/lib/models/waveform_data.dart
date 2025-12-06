/// Model for real-time waveform data points
class WaveformPoint {
  final DateTime timestamp;
  final double value;
  final WaveformType type;

  WaveformPoint({
    required this.timestamp,
    required this.value,
    required this.type,
  });

  /// Time in milliseconds since epoch
  int get timeMs => timestamp.millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'type': type.name,
      };

  factory WaveformPoint.fromJson(Map<String, dynamic> json) => WaveformPoint(
        timestamp: DateTime.parse(json['timestamp']),
        value: json['value'],
        type: WaveformType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => WaveformType.heartRate,
        ),
      );
}

/// Types of waveforms available
enum WaveformType {
  heartRate,
  gsr,
  temperature,
  hrv;

  String get displayName {
    switch (this) {
      case WaveformType.heartRate:
        return 'Heart Rate';
      case WaveformType.gsr:
        return 'GSR';
      case WaveformType.temperature:
        return 'Temperature';
      case WaveformType.hrv:
        return 'HRV';
    }
  }

  String get unit {
    switch (this) {
      case WaveformType.heartRate:
        return 'BPM';
      case WaveformType.gsr:
        return 'µS';
      case WaveformType.temperature:
        return '°C';
      case WaveformType.hrv:
        return 'ms';
    }
  }

  String get icon {
    switch (this) {
      case WaveformType.heartRate:
        return '❤️';
      case WaveformType.gsr:
        return '⚡';
      case WaveformType.temperature:
        return '🌡️';
      case WaveformType.hrv:
        return '📊';
    }
  }

  /// Get color for waveform line
  int get colorValue {
    switch (this) {
      case WaveformType.heartRate:
        return 0xFFE53935; // Red
      case WaveformType.gsr:
        return 0xFF43A047; // Green
      case WaveformType.temperature:
        return 0xFFFF6F00; // Orange
      case WaveformType.hrv:
        return 0xFF1E88E5; // Blue
    }
  }
}

/// Waveform buffer configuration
class WaveformConfig {
  final int maxPoints;
  final Duration timeWindow;
  final bool autoScale;
  final double? minY;
  final double? maxY;

  const WaveformConfig({
    this.maxPoints = 100,
    this.timeWindow = const Duration(seconds: 30),
    this.autoScale = true,
    this.minY,
    this.maxY,
  });
}

/// Waveform statistics
class WaveformStats {
  final double min;
  final double max;
  final double avg;
  final double current;
  final int pointCount;
  final WaveformType type;

  WaveformStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.current,
    required this.pointCount,
    required this.type,
  });

  double get range => max - min;

  String get formattedCurrent => '${current.toStringAsFixed(1)} ${type.unit}';
  String get formattedAvg => '${avg.toStringAsFixed(1)} ${type.unit}';
  String get formattedMin => '${min.toStringAsFixed(1)} ${type.unit}';
  String get formattedMax => '${max.toStringAsFixed(1)} ${type.unit}';
}

/// Battery information
class BatteryInfo {
  final int percentage;
  final double voltage;
  final bool isCharging;
  final DateTime timestamp;
  final BatteryStatus status;

  BatteryInfo({
    required this.percentage,
    required this.voltage,
    required this.isCharging,
    required this.timestamp,
    required this.status,
  });

  String get percentageStr => '$percentage%';
  
  String get statusIcon {
    if (isCharging) return '🔌';
    if (percentage >= 80) return '🔋';
    if (percentage >= 50) return '🔋';
    if (percentage >= 20) return '🪫';
    return '🪫';
  }

  String get statusText {
    if (isCharging) return 'Charging';
    return status.displayName;
  }

  Map<String, dynamic> toJson() => {
        'percentage': percentage,
        'voltage': voltage,
        'isCharging': isCharging,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };

  factory BatteryInfo.fromJson(Map<String, dynamic> json) => BatteryInfo(
        percentage: json['percentage'],
        voltage: json['voltage'],
        isCharging: json['isCharging'],
        timestamp: DateTime.parse(json['timestamp']),
        status: BatteryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BatteryStatus.unknown,
        ),
      );
}

/// Battery status levels
enum BatteryStatus {
  full,
  good,
  medium,
  low,
  critical,
  unknown;

  String get displayName {
    switch (this) {
      case BatteryStatus.full:
        return 'Full';
      case BatteryStatus.good:
        return 'Good';
      case BatteryStatus.medium:
        return 'Medium';
      case BatteryStatus.low:
        return 'Low';
      case BatteryStatus.critical:
        return 'Critical';
      case BatteryStatus.unknown:
        return 'Unknown';
    }
  }

  int get colorValue {
    switch (this) {
      case BatteryStatus.full:
      case BatteryStatus.good:
        return 0xFF4CAF50; // Green
      case BatteryStatus.medium:
        return 0xFFFFC107; // Amber
      case BatteryStatus.low:
        return 0xFFFF9800; // Orange
      case BatteryStatus.critical:
        return 0xFFF44336; // Red
      case BatteryStatus.unknown:
        return 0xFF9E9E9E; // Grey
    }
  }

  static BatteryStatus fromPercentage(int percentage) {
    if (percentage >= 90) return BatteryStatus.full;
    if (percentage >= 60) return BatteryStatus.good;
    if (percentage >= 30) return BatteryStatus.medium;
    if (percentage >= 15) return BatteryStatus.low;
    if (percentage > 0) return BatteryStatus.critical;
    return BatteryStatus.unknown;
  }
}
