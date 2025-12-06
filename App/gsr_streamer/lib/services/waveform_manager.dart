import 'dart:collection';
import '../models/waveform_data.dart';

/// Manages real-time waveform data buffers
class WaveformManager {
  final Map<WaveformType, Queue<WaveformPoint>> _buffers = {};
  final Map<WaveformType, WaveformConfig> _configs = {};

  WaveformManager() {
    // Initialize buffers for each type
    for (var type in WaveformType.values) {
      _buffers[type] = Queue<WaveformPoint>();
      _configs[type] = const WaveformConfig();
    }
  }

  /// Add a data point to the waveform
  void addPoint(WaveformType type, double value) {
    final point = WaveformPoint(
      timestamp: DateTime.now(),
      value: value,
      type: type,
    );

    final buffer = _buffers[type]!;
    final config = _configs[type]!;

    buffer.addLast(point);

    // Remove old points based on max points
    while (buffer.length > config.maxPoints) {
      buffer.removeFirst();
    }

    // Remove points outside time window
    final cutoffTime = DateTime.now().subtract(config.timeWindow);
    while (buffer.isNotEmpty && buffer.first.timestamp.isBefore(cutoffTime)) {
      buffer.removeFirst();
    }
  }

  /// Get waveform points for a specific type
  List<WaveformPoint> getPoints(WaveformType type) {
    return _buffers[type]?.toList() ?? [];
  }

  /// Get the most recent point
  WaveformPoint? getLatestPoint(WaveformType type) {
    final buffer = _buffers[type];
    return buffer?.isNotEmpty == true ? buffer!.last : null;
  }

  /// Get statistics for a waveform
  WaveformStats getStats(WaveformType type) {
    final points = getPoints(type);

    if (points.isEmpty) {
      return WaveformStats(
        min: 0,
        max: 0,
        avg: 0,
        current: 0,
        pointCount: 0,
        type: type,
      );
    }

    final values = points.map((p) => p.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final current = points.last.value;

    return WaveformStats(
      min: min,
      max: max,
      avg: avg,
      current: current,
      pointCount: points.length,
      type: type,
    );
  }

  /// Update configuration for a waveform type
  void updateConfig(WaveformType type, WaveformConfig config) {
    _configs[type] = config;
  }

  /// Clear all data for a specific type
  void clear(WaveformType type) {
    _buffers[type]?.clear();
  }

  /// Clear all waveform data
  void clearAll() {
    for (var buffer in _buffers.values) {
      buffer.clear();
    }
  }

  /// Get point count for a type
  int getPointCount(WaveformType type) {
    return _buffers[type]?.length ?? 0;
  }

  /// Check if there's data available
  bool hasData(WaveformType type) {
    return getPointCount(type) > 0;
  }

  /// Get normalized points for rendering (0.0 to 1.0)
  List<double> getNormalizedValues(WaveformType type) {
    final points = getPoints(type);
    if (points.isEmpty) return [];

    final values = points.map((p) => p.value).toList();
    final config = _configs[type]!;

    double min, max;

    if (config.autoScale) {
      // Auto-scale based on actual data
      min = values.reduce((a, b) => a < b ? a : b);
      max = values.reduce((a, b) => a > b ? a : b);
      
      // Add 10% padding
      final range = max - min;
      min -= range * 0.1;
      max += range * 0.1;
    } else {
      // Use fixed scale
      min = config.minY ?? 0;
      max = config.maxY ?? 100;
    }

    // Prevent division by zero
    if ((max - min).abs() < 0.001) {
      return List.filled(values.length, 0.5);
    }

    // Normalize to 0-1 range
    return values.map((v) => ((v - min) / (max - min)).clamp(0.0, 1.0)).toList();
  }

  /// Get time range in seconds
  double getTimeRangeSeconds(WaveformType type) {
    final points = getPoints(type);
    if (points.length < 2) return 0;

    final first = points.first.timestamp;
    final last = points.last.timestamp;
    return last.difference(first).inMilliseconds / 1000.0;
  }
}

/// Battery level manager
class BatteryManager {
  BatteryInfo? _currentBattery;
  final List<BatteryInfo> _history = [];
  static const int _maxHistorySize = 100;

  BatteryInfo? get currentBattery => _currentBattery;
  List<BatteryInfo> get history => List.unmodifiable(_history);

  /// Update battery information
  void updateBattery({
    required int percentage,
    required double voltage,
    required bool isCharging,
  }) {
    final status = BatteryStatus.fromPercentage(percentage);

    _currentBattery = BatteryInfo(
      percentage: percentage,
      voltage: voltage,
      isCharging: isCharging,
      timestamp: DateTime.now(),
      status: status,
    );

    // Add to history
    _history.add(_currentBattery!);

    // Keep history size manageable
    while (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Get battery trend (positive = charging, negative = discharging)
  double getBatteryTrend() {
    if (_history.length < 2) return 0;

    // Compare last 10 readings
    final recentCount = 10.clamp(2, _history.length);
    final recent = _history.sublist(_history.length - recentCount);

    final first = recent.first.percentage;
    final last = recent.last.percentage;

    return (last - first).toDouble();
  }

  /// Get estimated time remaining (in minutes)
  int? getEstimatedTimeRemaining() {
    if (_currentBattery == null || _currentBattery!.isCharging) {
      return null;
    }

    final trend = getBatteryTrend();
    if (trend >= 0) return null; // Not discharging

    if (_history.length < 5) return null; // Need more data

    // Calculate discharge rate (%/hour)
    final recentCount = 20.clamp(5, _history.length);
    final recent = _history.sublist(_history.length - recentCount);
    final timeSpan = recent.last.timestamp.difference(recent.first.timestamp);
    final percentageChange = recent.last.percentage - recent.first.percentage;

    if (timeSpan.inMinutes == 0) return null;

    final ratePerHour = (percentageChange / timeSpan.inMinutes) * 60;

    if (ratePerHour >= 0) return null; // Not discharging

    // Estimate remaining time
    final remainingPercentage = _currentBattery!.percentage;
    final hoursRemaining = remainingPercentage / ratePerHour.abs();

    return (hoursRemaining * 60).round();
  }

  /// Check if battery is critically low
  bool get isCritical =>
      _currentBattery?.status == BatteryStatus.critical ||
      (_currentBattery?.percentage ?? 100) < 10;

  /// Check if battery is low
  bool get isLow =>
      _currentBattery?.status == BatteryStatus.low ||
      (_currentBattery?.percentage ?? 100) < 20;

  /// Get battery health (based on voltage)
  String getBatteryHealth() {
    if (_currentBattery == null) return 'Unknown';

    final voltage = _currentBattery!.voltage;

    // XIAO nRF52840 uses 3.7V LiPo battery
    // Full: ~4.2V, Empty: ~3.0V
    if (voltage >= 4.1) return 'Excellent';
    if (voltage >= 3.8) return 'Good';
    if (voltage >= 3.5) return 'Fair';
    if (voltage >= 3.2) return 'Poor';
    return 'Critical';
  }

  /// Clear battery history
  void clearHistory() {
    _history.clear();
  }
}
