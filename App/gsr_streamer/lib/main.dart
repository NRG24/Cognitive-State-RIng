import 'package:flutter/material.dart';
import 'services/biometric_monitor.dart';
import 'screens/screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometric Monitor',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF2C2C2E),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          secondary: Color(0xFF64D2FF),
          surface: Color(0xFF2C2C2E),
          background: Color(0xFF1C1C1E),
        ),
        cardTheme: ThemeData.dark().cardTheme.copyWith(
          color: const Color(0xFF2C2C2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: Colors.white70,
            fontSize: 17,
          ),
        ),
      ),
      home: const BiometricTabs(),
    );
  }
}

class BiometricTabs extends StatefulWidget {
  const BiometricTabs({super.key});

  @override
  State<BiometricTabs> createState() => _BiometricTabsState();
}

class _BiometricTabsState extends State<BiometricTabs> with TickerProviderStateMixin {
  late TabController _tabController;
  final BiometricMonitor _monitor = BiometricMonitor();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _monitor.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Biometric Monitor'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.psychology), text: 'Cognitive'),
            Tab(icon: Icon(Icons.timeline), text: 'Trends'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(monitor: _monitor),
          CognitiveTab(monitor: _monitor),
          TrendsTab(monitor: _monitor),
          SettingsTab(monitor: _monitor),
        ],
      ),
    );
  }
}
