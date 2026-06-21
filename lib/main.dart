// main.dart: RunCoach 앱의 진입점이며 하단 탭과 전체 상태를 관리합니다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/run_activity.dart';
import 'screens/activity_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/home_screen.dart';
import 'screens/record_screen.dart';
import 'services/run_storage_service.dart';

void main() {
  runApp(const RunCoachApp());
}

class RunCoachApp extends StatelessWidget {
  const RunCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunCoach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05E676),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const RunCoachHome(),
    );
  }
}

class RunCoachHome extends StatefulWidget {
  const RunCoachHome({super.key});

  @override
  State<RunCoachHome> createState() => _RunCoachHomeState();
}

class _RunCoachHomeState extends State<RunCoachHome> {
  final _storage = RunStorageService();
  var _selectedIndex = 0;
  List<RunActivity> _runs = [];

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    final runs = await _storage.getRuns();
    if (!mounted) return;
    setState(() => _runs = runs);
  }

  Future<void> _saveRun(RunActivity run) async {
    final runs = await _storage.saveRun(run);
    if (!mounted) return;
    setState(() => _runs = runs);
  }

  Future<void> _deleteRun(String id) async {
    final runs = await _storage.deleteRun(id);
    if (!mounted) return;
    setState(() => _runs = runs);
  }

  void _goBack() {
    if (_selectedIndex == 0) {
      SystemNavigator.pop();
      return;
    }
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(runs: _runs, onBack: _goBack),
      ActivityScreen(onSave: _saveRun, runs: _runs, onBack: _goBack),
      RecordScreen(runs: _runs, onDelete: _deleteRun, onBack: _goBack),
      AnalysisScreen(runs: _runs, onBack: _goBack),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        body: SafeArea(top: false, child: screens[_selectedIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF111111),
          unselectedItemColor: const Color(0xFF8E8E93),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              activeIcon: Icon(Icons.directions_run),
              label: '활동',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: '기록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '분석',
            ),
          ],
        ),
      ),
    );
  }
}
