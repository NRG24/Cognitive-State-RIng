import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';
import 'activity_recognizer.dart';
import 'trigger_detector.dart';
import 'waveform_manager.dart';

class BiometricMonitor extends ChangeNotifier {
  // BLE and Notifications
  final _ble = FlutterReactiveBle();
  final _notifications = FlutterLocalNotificationsPlugin();
  
  // Connection state
  bool _isScanning = false;
  String _status = 'Disconnected';
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  // BLE UUIDs
  final String _serviceUuid = "19B10000-E8F2-537E-4F6C-D104768A1214";
  final String _gsrCharUuid = "19B10002-E8F2-537E-4F6C-D104768A1214";
  final String _heartCharUuid = "19B10003-E8F2-537E-4F6C-D104768A1214";
  final String _tempCharUuid = "19B10004-E8F2-537E-4F6C-D104768A1214";
  final String _hrvCharUuid = "19B10005-E8F2-537E-4F6C-D104768A1214";
  final String _spo2CharUuid = "19B10006-E8F2-537E-4F6C-D104768A1214";
  final String _batteryCharUuid = "19B10007-E8F2-537E-4F6C-D104768A1214";

  // Real-time biometric data
  List<double> _gsrData = [];
  List<double> _heartRateData = [];
  List<double> _hrvData = [];
  List<double> _spo2Data = [];
  List<double> _temperatureData = [];
  
  // Current biometric values
  double _baselineGSR = 0;
  double _variabilityGSR = 0;
  double _fingerTemperature = 0;
  int _heartRate = 0;
  double _hrv = 0;
  int _spo2 = 0;

  // Data persistence
  SharedPreferences? _prefs;
  DateTime? _sessionStartTime;
  int _sessionDuration = 0;
  Timer? _sessionTimer;

  // Historical statistics
  Map<String, dynamic> _todayStats = {};
  List<Map<String, dynamic>> _historicalSessions = [];
  List<SessionData> _sessions = [];

  // Session tracking
  final List<double> _sessionHeartRates = [];
  final List<double> _sessionHRVs = [];
  final List<double> _sessionSpO2s = [];
  final List<double> _sessionGSRs = [];
  final List<double> _sessionTemps = [];
  final List<double> _sessionCognitiveScores = [];
  
  final Map<String, int> _arousalTimeTracking = {
    'Deep Calm': 0,
    'Relaxed': 0,
    'Alert': 0,
    'Engaged': 0,
    'Stressed': 0,
    'Highly Aroused': 0,
  };
  
  String _lastArousalLevel = '';
  DateTime _lastArousalChange = DateTime.now();

  // Activity Recognition
  ActivityDetection? _currentActivity;
  ActivityDetection? _previousActivity;
  final List<ActivityDetection> _activityHistory = [];
  final List<ActivityTransition> _activityTransitions = [];
  Timer? _activityCheckTimer;

  // Trigger Detection
  final List<StressTrigger> _stressTriggers = [];
  TriggerAnalysis? _triggerAnalysis;
  
  // Previous values for trigger detection
  int _previousHR = 0;
  double _previousHRV = 0;
  double _previousGSR = 0;
  double _previousTemp = 0;
  String _previousArousal = '';

  // Waveform Management
  final WaveformManager _waveformManager = WaveformManager();

  // Notifications
  bool _notificationsEnabled = true;
  DateTime _lastNotificationTime = DateTime.now();
  String _lastNotifiedState = '';

  // Getters - Connection State
  bool get isScanning => _isScanning;
  String get status => _status;

  // Getters - Real-time Data
  List<double> get gsrData => _gsrData;
  List<double> get heartRateData => _heartRateData;
  List<double> get hrvData => _hrvData;
  List<double> get spo2Data => _spo2Data;
  List<double> get temperatureData => _temperatureData;

  // Getters - Current Values
  double get baselineGSR => _baselineGSR;
  double get variabilityGSR => _variabilityGSR;
  double get fingerTemperature => _fingerTemperature;
  int get heartRate => _heartRate;
  double get hrv => _hrv;
  int get spo2 => _spo2;

  // Getters - Session & History
  int get sessionDuration => _sessionDuration;
  DateTime? get sessionStartTime => _sessionStartTime;
  Map<String, dynamic> get todayStats => _todayStats;
  List<Map<String, dynamic>> get historicalSessions => _historicalSessions;
  List<SessionData> get sessions => _sessions;
  bool get notificationsEnabled => _notificationsEnabled;

  // Getters - Activity Recognition
  ActivityDetection? get currentActivity => _currentActivity;
  List<ActivityDetection> get activityHistory => _activityHistory;
  List<ActivityTransition> get activityTransitions => _activityTransitions;

  // Getters - Trigger Detection
  List<StressTrigger> get stressTriggers => _stressTriggers;
  TriggerAnalysis? get triggerAnalysis => _triggerAnalysis;

  // Getters - Waveform
  WaveformManager get waveformManager => _waveformManager;

  /// Initialize the biometric monitor
  Future<void> init() async {
    await _requestPermissions();
    await _initializeNotifications();
    await _loadHistoricalData();
    await _loadTriggers();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _sessionTimer?.cancel();
    _saveCurrentSession();
    super.dispose();
  }

  // ====================
  // Permission & Setup
  // ====================

  Future<void> _requestPermissions() async {
    try {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();
    } catch (e) {
      print('Permission request not supported on this platform: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(initSettings);
      print('Notifications initialized successfully');
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  // ====================
  // Notification Methods
  // ====================

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  Future<void> _sendNotification(String title, String body,
      {String? emoji}) async {
    if (!_notificationsEnabled) return;

    // Throttle notifications - minimum 5 minutes between same state
    if (_lastNotifiedState == title &&
        DateTime.now().difference(_lastNotificationTime).inMinutes < 5) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'biometric_channel',
      'Biometric Alerts',
      channelDescription: 'Notifications for significant biometric changes',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Biometric Alert',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        0,
        emoji != null ? '$emoji $title' : title,
        body,
        details,
      );

      _lastNotifiedState = title;
      _lastNotificationTime = DateTime.now();
      print('Notification sent: $title - $body');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  // ====================
  // Haptic Feedback (Currently unused, kept for future)
  // ====================

  void _triggerHaptic(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.success:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case HapticFeedbackType.warning:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  // ====================
  // Data Persistence
  // ====================

  Future<void> _loadHistoricalData() async {
    _prefs = await SharedPreferences.getInstance();

    // Load sessions
    final sessionsJson = _prefs?.getString('sessions') ?? '[]';
    final sessionsList =
        List<Map<String, dynamic>>.from(json.decode(sessionsJson));
    _sessions = sessionsList.map((json) => SessionData.fromJson(json)).toList();

    // Load today's stats
    final todayKey = _getTodayKey();
    final todayStatsJson = _prefs?.getString('stats_$todayKey');
    if (todayStatsJson != null) {
      _todayStats = json.decode(todayStatsJson);
    } else {
      _todayStats = _initializeEmptyStats();
    }

    // Load historical sessions (old format for compatibility)
    final oldSessionsJson = _prefs?.getString('historical_sessions') ?? '[]';
    _historicalSessions =
        List<Map<String, dynamic>>.from(json.decode(oldSessionsJson));

    // Clean old data
    _cleanOldData();

    notifyListeners();
  }

  Map<String, dynamic> _initializeEmptyStats() {
    return {
      'date': DateTime.now().toIso8601String(),
      'sessions': 0,
      'totalDuration': 0,
      'avgHeartRate': 0.0,
      'maxHeartRate': 0,
      'minHeartRate': 0,
      'avgHRV': 0.0,
      'avgSpO2': 0.0,
      'avgGSR': 0.0,
      'avgTemp': 0.0,
      'avgCognitiveScore': 0.0,
      'stressEvents': 0,
      'calmPeriods': 0,
    };
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveCurrentSession() async {
    if (_sessionStartTime == null || _prefs == null) return;
    if (_sessionHeartRates.isEmpty) return;

    // Calculate averages
    final avgHeartRate =
        _sessionHeartRates.reduce((a, b) => a + b) / _sessionHeartRates.length;
    final avgHRV = _sessionHRVs.isEmpty
        ? 0.0
        : _sessionHRVs.reduce((a, b) => a + b) / _sessionHRVs.length;
    final avgSpO2 = _sessionSpO2s.isEmpty
        ? 0.0
        : _sessionSpO2s.reduce((a, b) => a + b) / _sessionSpO2s.length;
    final avgGSR = _sessionGSRs.isEmpty
        ? 0.0
        : _sessionGSRs.reduce((a, b) => a + b) / _sessionGSRs.length;
    final avgTemp = _sessionTemps.isEmpty
        ? 0.0
        : _sessionTemps.reduce((a, b) => a + b) / _sessionTemps.length;
    final avgCognitiveScore = _sessionCognitiveScores.isEmpty
        ? 0.0
        : _sessionCognitiveScores.reduce((a, b) => a + b) /
            _sessionCognitiveScores.length;

    // Count stress/calm periods
    int stressEvents = _arousalTimeTracking['Stressed'] ?? 0;
    stressEvents += _arousalTimeTracking['Highly Aroused'] ?? 0;
    int calmPeriods = _arousalTimeTracking['Deep Calm'] ?? 0;
    calmPeriods += _arousalTimeTracking['Relaxed'] ?? 0;

    // Create session
    final session = SessionData(
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      avgHeartRate: avgHeartRate,
      avgHRV: avgHRV,
      avgSpO2: avgSpO2,
      avgGSR: avgGSR,
      avgTemperature: avgTemp,
      avgCognitiveScore: avgCognitiveScore,
      arousalDistribution: Map.from(_arousalTimeTracking),
      stressEvents: stressEvents,
      calmPeriods: calmPeriods,
    );

    _sessions.add(session);

    // Save to preferences
    final sessionsJson = json.encode(_sessions.map((s) => s.toJson()).toList());
    await _prefs?.setString('sessions', sessionsJson);

    // Save old format for compatibility
    final oldFormatSession = {
      'startTime': _sessionStartTime!.toIso8601String(),
      'duration': _sessionDuration,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': _sessionHeartRates.reduce((a, b) => a > b ? a : b),
      'minHeartRate': _sessionHeartRates.reduce((a, b) => a < b ? a : b),
      'avgHRV': avgHRV,
      'avgSpO2': avgSpO2,
      'avgGSR': avgGSR,
      'avgTemp': avgTemp,
      'avgCognitiveScore': avgCognitiveScore,
    };
    _historicalSessions.add(oldFormatSession);
    await _prefs?.setString(
        'historical_sessions', json.encode(_historicalSessions));

    _updateTodayStats(oldFormatSession);

    // Reset tracking
    _sessionHeartRates.clear();
    _sessionHRVs.clear();
    _sessionSpO2s.clear();
    _sessionGSRs.clear();
    _sessionTemps.clear();
    _sessionCognitiveScores.clear();
    _arousalTimeTracking.updateAll((key, value) => 0);
  }

  void _updateTodayStats(Map<String, dynamic> session) {
    _todayStats['sessions'] = (_todayStats['sessions'] ?? 0) + 1;
    _todayStats['totalDuration'] =
        (_todayStats['totalDuration'] ?? 0) + _sessionDuration;

    final sessions = _todayStats['sessions'];
    _todayStats['avgHeartRate'] =
        ((_todayStats['avgHeartRate'] ?? 0) * (sessions - 1) +
                session['avgHeartRate']) /
            sessions;
    _todayStats['avgHRV'] = ((_todayStats['avgHRV'] ?? 0) * (sessions - 1) +
            session['avgHRV']) /
        sessions;
    _todayStats['avgSpO2'] = ((_todayStats['avgSpO2'] ?? 0) * (sessions - 1) +
            session['avgSpO2']) /
        sessions;
    _todayStats['avgGSR'] = ((_todayStats['avgGSR'] ?? 0) * (sessions - 1) +
            session['avgGSR']) /
        sessions;
    _todayStats['avgTemp'] = ((_todayStats['avgTemp'] ?? 0) * (sessions - 1) +
            session['avgTemp']) /
        sessions;
    _todayStats['avgCognitiveScore'] =
        ((_todayStats['avgCognitiveScore'] ?? 0) * (sessions - 1) +
                session['avgCognitiveScore']) /
            sessions;

    // Update max/min
    if (_todayStats['maxHeartRate'] == 0 ||
        session['maxHeartRate'] > _todayStats['maxHeartRate']) {
      _todayStats['maxHeartRate'] = session['maxHeartRate'];
    }
    if (_todayStats['minHeartRate'] == 0 ||
        session['minHeartRate'] < _todayStats['minHeartRate']) {
      _todayStats['minHeartRate'] = session['minHeartRate'];
    }

    // Count stress/calm
    if (_variabilityGSR > 0.4) {
      _todayStats['stressEvents'] = (_todayStats['stressEvents'] ?? 0) + 1;
    } else if (_variabilityGSR < 0.15) {
      _todayStats['calmPeriods'] = (_todayStats['calmPeriods'] ?? 0) + 1;
    }

    final todayKey = _getTodayKey();
    _prefs?.setString('stats_$todayKey', json.encode(_todayStats));

    notifyListeners();
  }

  void _cleanOldData() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _historicalSessions.removeWhere((session) {
      final sessionDate = DateTime.parse(session['startTime']);
      return sessionDate.isBefore(thirtyDaysAgo);
    });

    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('stats_')) {
        final dateStr = key.substring(6);
        try {
          final date = DateTime.parse(dateStr);
          if (date.isBefore(thirtyDaysAgo)) {
            _prefs?.remove(key);
          }
        } catch (e) {
          // Invalid date, skip
        }
      }
    }
  }

  // ====================
  // Session Tracking
  // ====================

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionDuration = 0;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionDuration++;
      _trackArousalTime();
      
      // Update activity recognition every 30 seconds
      if (_sessionDuration % 30 == 0) {
        _updateActivityRecognition();
      }
      
      // Check for stress triggers every 10 seconds
      if (_sessionDuration % 10 == 0) {
        _checkForTriggers();
      }
      
      notifyListeners();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _saveCurrentSession();
  }

  String get sessionDurationFormatted {
    final hours = _sessionDuration ~/ 3600;
    final minutes = (_sessionDuration % 3600) ~/ 60;
    final seconds = _sessionDuration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _trackArousalTime() {
    final currentArousal = arousalLevel;
    if (currentArousal != _lastArousalLevel && _lastArousalLevel.isNotEmpty) {
      final timeInState =
          DateTime.now().difference(_lastArousalChange).inSeconds;
      _arousalTimeTracking[_lastArousalLevel] =
          (_arousalTimeTracking[_lastArousalLevel] ?? 0) + timeInState;
      _lastArousalChange = DateTime.now();

      _handleArousalChange(currentArousal);
    }
    _lastArousalLevel = currentArousal;

    // Track metrics
    if (_heartRate > 0) _sessionHeartRates.add(_heartRate.toDouble());
    if (_hrv > 0) _sessionHRVs.add(_hrv);
    if (_spo2 > 0) _sessionSpO2s.add(_spo2.toDouble());
    if (_baselineGSR > 0) _sessionGSRs.add(_baselineGSR);
    if (_fingerTemperature > 0) _sessionTemps.add(_fingerTemperature);
    _sessionCognitiveScores.add(cognitiveScore);
  }

  void _handleArousalChange(String newState) {
    switch (newState) {
      case 'Deep Calm':
        _sendNotification(
          'Deep Calm Achieved',
          'You\'ve entered a deeply relaxed state. Perfect for meditation or rest.',
          emoji: '🧘',
        );
        break;

      case 'Engaged':
        if (_lastArousalLevel == 'Relaxed' ||
            _lastArousalLevel == 'Deep Calm') {
          _sendNotification(
            'Engaged State',
            'Your arousal levels are increasing. You\'re in an active, focused state.',
            emoji: '⚡',
          );
        }
        break;

      case 'Stressed':
        _sendNotification(
          'Stress Detected',
          'Elevated stress levels detected. Consider taking a break or trying breathing exercises.',
          emoji: '😰',
        );
        break;

      case 'Highly Aroused':
        _sendNotification(
          'High Stress Alert',
          'Very high stress levels detected! Please take immediate action to relax.',
          emoji: '⚠️',
        );
        break;
    }
  }

  // ====================
  // Activity Recognition
  // ====================

  void _updateActivityRecognition() {
    // Detect current activity
    final detection = ActivityRecognizer.detectActivity(
      heartRate: _heartRate,
      hrv: _hrv,
      gsrVariability: _variabilityGSR,
      temperature: _fingerTemperature,
      arousalLevel: arousalLevel,
      cognitiveScore: cognitiveScore,
    );

    // Update duration if same activity
    if (_currentActivity != null &&
        _currentActivity!.activityType == detection.activityType) {
      _currentActivity = ActivityDetection(
        activityType: detection.activityType,
        confidence: detection.confidence,
        timestamp: _currentActivity!.timestamp,
        duration: DateTime.now().difference(_currentActivity!.timestamp).inSeconds,
        metrics: detection.metrics,
      );
    } else {
      // Check for transition
      if (_currentActivity != null) {
        final transition = ActivityRecognizer.detectTransition(
          _currentActivity!,
          detection,
        );
        
        if (transition != null) {
          _activityTransitions.add(transition);
          _sendActivityTransitionNotification(transition);
        }
      }

      _previousActivity = _currentActivity;
      _currentActivity = detection;
    }

    // Add to history (keep last 100 detections)
    _activityHistory.add(detection);
    if (_activityHistory.length > 100) {
      _activityHistory.removeAt(0);
    }
  }

  void _sendActivityTransitionNotification(ActivityTransition transition) {
    // Only notify for significant transitions
    if (transition.toActivity == ActivityType.exercising) {
      _sendNotification(
        'Exercise Detected',
        'Physical activity started. Stay hydrated!',
        emoji: '🏃',
      );
    } else if (transition.toActivity == ActivityType.stressed) {
      _sendNotification(
        'Stress Transition',
        'Activity shifted to stressed state. ${transition.trigger ?? ""}',
        emoji: '😰',
      );
    } else if (transition.toActivity == ActivityType.resting &&
               transition.fromActivity == ActivityType.stressed) {
      _sendNotification(
        'Stress Resolved',
        'Great! You\'ve transitioned to a resting state.',
        emoji: '😌',
      );
    }
  }

  // ====================
  // Trigger Detection
  // ====================

  void _checkForTriggers() {
    // Don't check if no valid data
    if (_heartRate == 0 || _baselineGSR == 0) return;

    final trigger = TriggerDetector.detectTrigger(
      currentHR: _heartRate,
      previousHR: _previousHR,
      currentHRV: _hrv,
      previousHRV: _previousHRV,
      currentGSR: _baselineGSR,
      previousGSR: _previousGSR,
      currentTemp: _fingerTemperature,
      previousTemp: _previousTemp,
      currentArousal: arousalLevel,
      previousArousal: _previousArousal,
      currentActivity: _currentActivity?.activityType,
      previousActivity: _previousActivity?.activityType,
    );

    if (trigger != null) {
      _stressTriggers.add(trigger);
      
      // Keep only last 100 triggers
      if (_stressTriggers.length > 100) {
        _stressTriggers.removeAt(0);
      }

      // Update analysis
      _triggerAnalysis = TriggerDetector.analyzeTriggers(_stressTriggers);

      // Save triggers
      TriggerDetector.saveTriggers(_stressTriggers);

      // Send notification for critical triggers
      if (trigger.severity == TriggerSeverity.critical ||
          trigger.severity == TriggerSeverity.severe) {
        _sendTriggerNotification(trigger);
      }
    }

    // Update previous values for next check
    _previousHR = _heartRate;
    _previousHRV = _hrv;
    _previousGSR = _baselineGSR;
    _previousTemp = _fingerTemperature;
    _previousArousal = arousalLevel;
  }

  void _sendTriggerNotification(StressTrigger trigger) {
    _sendNotification(
      '${trigger.severity.emoji} Stress Trigger Detected',
      trigger.description,
      emoji: trigger.type.icon,
    );
  }

  /// Load saved triggers
  Future<void> _loadTriggers() async {
    final savedTriggers = await TriggerDetector.loadTriggers();
    _stressTriggers.clear();
    _stressTriggers.addAll(savedTriggers);
    
    if (_stressTriggers.isNotEmpty) {
      _triggerAnalysis = TriggerDetector.analyzeTriggers(_stressTriggers);
    }
    
    notifyListeners();
  }

  // ====================
  // Cognitive Analysis
  // ====================

  double get cognitiveScore {
    if (_heartRate == 0) return 75;

    double baseScore = 75;

    // Heart rate adjustment
    if (_heartRate >= 50 && _heartRate <= 100) {
      baseScore += 5;
    } else {
      baseScore -= 5;
    }

    // HRV adjustment
    if (_hrv > 15) {
      baseScore += 5;
    } else if (_hrv > 0) {
      baseScore -= 5;
    }

    // GSR stress adjustment
    if (_variabilityGSR <= 0.25) {
      baseScore += 5;
    } else if (_variabilityGSR > 0.5) {
      baseScore -= 10;
    }

    // Temperature-based pattern recognition
    if (_fingerTemperature > 0) {
      if (_fingerTemperature > 34.0 &&
          _heartRate > 90 &&
          _variabilityGSR > 0.4) {
        baseScore += 5; // Exercise pattern
      } else if (_fingerTemperature > 37.0 && _heartRate < 90) {
        baseScore -= 3; // Illness pattern
      } else if (_fingerTemperature >= 30.0 && _fingerTemperature <= 36.0) {
        baseScore += 2; // Normal temperature
      }
    }

    return baseScore.clamp(65, 90);
  }

  String get arousalLevel {
    if (_variabilityGSR == 0 && _baselineGSR == 0) return 'Initializing...';

    double gsrVar = _variabilityGSR;

    if (gsrVar < 0.05) {
      return 'Deep Calm';
    } else if (gsrVar < 0.15) {
      return 'Relaxed';
    } else if (gsrVar < 0.28) {
      return 'Alert';
    } else if (gsrVar < 0.45) {
      return 'Engaged';
    } else if (gsrVar < 0.75) {
      return 'Stressed';
    } else {
      return 'Highly Aroused';
    }
  }

  Color get arousalColor {
    switch (arousalLevel) {
      case 'Deep Calm':
        return Colors.indigo.shade600;
      case 'Relaxed':
        return Colors.teal.shade500;
      case 'Alert':
        return Colors.blue.shade600;
      case 'Engaged':
        return Colors.amber.shade600;
      case 'Stressed':
        return Colors.orange.shade600;
      case 'Highly Aroused':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String get mentalStateInsight {
    double score = cognitiveScore;
    String arousal = arousalLevel;

    if (score >= 85 && (arousal == 'Deep Calm' || arousal == 'Relaxed')) {
      return 'Optimal state for deep work and creative thinking';
    } else if (score >= 75 && arousal == 'Alert') {
      return 'Excellent focus - perfect for learning and problem solving';
    } else if (score >= 65 && arousal == 'Engaged') {
      return 'High performance state - great for challenging tasks';
    } else if (score >= 50 && arousal == 'Stressed') {
      return 'Manageable stress - good for routine tasks, consider breaks';
    } else if (arousal == 'Highly Aroused') {
      return 'High stress detected - prioritize relaxation and self-care';
    } else if (score < 40) {
      return 'Low cognitive performance - rest and recovery recommended';
    } else {
      return 'Moderate state - suitable for light activities';
    }
  }

  List<String> get recommendations {
    double score = cognitiveScore;
    String arousal = arousalLevel;
    List<String> recs = [];

    if (arousal == 'Highly Aroused' || arousal == 'Stressed') {
      recs.add('💆‍♀️ Try deep breathing exercises');
      recs.add('🚶‍♀️ Take a short walk outside');
      recs.add('🎵 Listen to calming music');
    }

    if (score < 50) {
      recs.add('💤 Consider taking a rest break');
      recs.add('💧 Stay hydrated');
      recs.add('🍎 Have a healthy snack');
    }

    if (arousal == 'Deep Calm' && score >= 80) {
      recs.add('🧠 Perfect time for complex mental tasks');
      recs.add('📚 Great for learning new concepts');
      recs.add('🎨 Ideal for creative work');
    }

    if (arousal == 'Alert' && score >= 70) {
      recs.add('✍️ Excellent for writing and analysis');
      recs.add('📊 Good time for data work');
      recs.add('🎯 Focus on important decisions');
    }

    if (_heartRate > 100) {
      recs.add('❤️ Heart rate elevated - check if you need rest');
    }

    if (_spo2 < 95) {
      recs.add('🫁 Consider deep breathing for better oxygenation');
    }

    if (recs.isEmpty) {
      recs.add('✅ You\'re in good balance - maintain current activities');
    }

    return recs;
  }

  // ====================
  // BLE Connection
  // ====================

  void startScan() {
    if (_isScanning) return;

    _isScanning = true;
    _status = 'Scanning...';
    notifyListeners();

    _scanSubscription?.cancel();

    _scanSubscription = _ble
        .scanForDevices(
      withServices: [Uuid.parse(_serviceUuid)],
      scanMode: ScanMode.lowLatency,
    )
        .listen(
      (device) {
        print('Found device: ${device.name} (${device.id})');
        if (device.name == 'GSR_HEART') {
          _scanSubscription?.cancel();
          _isScanning = false;
          _status = 'Device found';
          notifyListeners();
          print('Found GSR_HEART device! Attempting to connect...');
          _connectToDevice(device.id);
        }
      },
      onError: (error) {
        print('Scan error: $error');
        _status = 'Scan error: $error';
        _isScanning = false;
        notifyListeners();
      },
      cancelOnError: true,
    );

    Future.delayed(const Duration(seconds: 30), () {
      _scanSubscription?.cancel();
      if (_isScanning) {
        _isScanning = false;
        _status = 'Scan timeout';
        notifyListeners();
      }
    });
  }

  void _connectToDevice(String deviceId) {
    _connectionSubscription?.cancel();

    _status = 'Connecting...';
    notifyListeners();

    try {
      _connectionSubscription = _ble
          .connectToDevice(
        id: deviceId,
        connectionTimeout: const Duration(seconds: 10),
      )
          .listen(
        (connectionState) {
          print('Connection state: $connectionState');

          switch (connectionState.connectionState) {
            case DeviceConnectionState.connecting:
              _status = 'Connecting...';
              break;
            case DeviceConnectionState.connected:
              _status = 'Connected!';
              _sendNotification(
                'Device Connected',
                'Successfully connected to GSR_HEART sensor',
                emoji: '✅',
              );
              _startSessionTimer();
              _startListening(deviceId);
              break;
            case DeviceConnectionState.disconnecting:
              _status = 'Disconnecting...';
              _stopSessionTimer();
              break;
            case DeviceConnectionState.disconnected:
              _status = 'Disconnected';
              _stopSessionTimer();
              break;
          }
          notifyListeners();
        },
        onError: (error) {
          print('Connection error: $error');
          _status = 'Connection error: $error';
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error: $e');
      _status = 'Error: $e';
      notifyListeners();
    }
  }

  void _startListening(String deviceId) {
    print('Starting to listen for data...');

    // GSR characteristic
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_gsrCharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        // Parse as integer (GSR value directly)
        if (data.length >= 4) {
          final gsrValue = ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.little).toDouble();

          if (gsrValue >= 0 && gsrValue <= 1023) {
            if (_gsrData.length >= 100) _gsrData.removeAt(0);
            _gsrData.add(gsrValue);
            _baselineGSR = gsrValue; // Use current value as baseline for now
            _sessionGSRs.add(gsrValue);
            
            // Add to waveform
            _waveformManager.addPoint(WaveformType.gsr, gsrValue);

            notifyListeners();
          }
        }
      } catch (e) {
        print('Error parsing GSR data: $e');
      }
    });

    // Heart Rate characteristic
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_heartCharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        // Parse as integer (BPM value directly)
        if (data.length >= 4) {
          final heartRate = ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.little);
          
          if (heartRate > 20 && heartRate < 220) {
            if (_heartRateData.length >= 100) _heartRateData.removeAt(0);
            _heartRateData.add(heartRate.toDouble());
            _heartRate = heartRate;
            _sessionHeartRates.add(heartRate.toDouble());
            
            // Add to waveform
            _waveformManager.addPoint(WaveformType.heartRate, heartRate.toDouble());
          }

          _trackArousalTime();
          notifyListeners();
        }
      } catch (e) {
        print('Error parsing heart data: $e');
      }
    });

    // Temperature characteristic
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_tempCharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        // Parse as float (temperature value in Celsius)
        if (data.length >= 4) {
          final temperature = ByteData.sublistView(Uint8List.fromList(data)).getFloat32(0, Endian.little);
          
          if (temperature > 20 && temperature < 45) { // Valid human temperature range
            if (_temperatureData.length >= 100) _temperatureData.removeAt(0);
            _temperatureData.add(temperature);
            _fingerTemperature = temperature;
            
            // Add to waveform
            _waveformManager.addPoint(WaveformType.temperature, temperature);
          }

          notifyListeners();
        }
      } catch (e) {
        print('Error parsing temperature data: $e');
      }
    });

    // HRV characteristic (with error handling)
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_hrvCharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        if (data.length >= 4) {
          final hrv = ByteData.sublistView(Uint8List.fromList(data)).getFloat32(0, Endian.little);
          
          if (hrv >= 0 && hrv < 500) { // Valid HRV range
            if (_hrvData.length >= 100) _hrvData.removeAt(0);
            _hrvData.add(hrv);
            _hrv = hrv;
            
            // Add to waveform
            _waveformManager.addPoint(WaveformType.hrv, hrv);
          }

          notifyListeners();
        }
      } catch (e) {
        print('Error parsing HRV data: $e');
      }
    }, onError: (error) {
      print('HRV characteristic error (may not be available yet): $error');
    });

    // SpO2 characteristic (with error handling)
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_spo2CharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        if (data.length >= 4) {
          final spo2 = ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.little);
          
          if (spo2 >= 70 && spo2 <= 100) { // Valid SpO2 range
            if (_spo2Data.length >= 100) _spo2Data.removeAt(0);
            _spo2Data.add(spo2.toDouble());
            _spo2 = spo2;
          }

          notifyListeners();
        }
      } catch (e) {
        print('Error parsing SpO2 data: $e');
      }
    }, onError: (error) {
      print('SpO2 characteristic error (may not be available yet): $error');
    });

    // Battery characteristic (optional - may not be available)
    _ble
        .subscribeToCharacteristic(QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_batteryCharUuid),
      deviceId: deviceId,
    ))
        .listen((data) {
      try {
        if (data.length >= 2) {
          final batteryLevel = ByteData.sublistView(Uint8List.fromList(data)).getInt16(0, Endian.little);
          
          if (batteryLevel >= 0 && batteryLevel <= 100) {
            // Battery percentage can be displayed in UI
            print('Battery: $batteryLevel%');
          }

          notifyListeners();
        }
      } catch (e) {
        print('Error parsing battery data: $e');
      }
    }, onError: (error) {
      print('Battery characteristic not available (optional): $error');
    });
  }
}
