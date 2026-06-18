// run_storage_service.dart: shared_preferences로 RunActivity 기록을 저장하고 불러옵니다.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/run_activity.dart';

class RunStorageService {
  static const _runsKey = 'runcoach_activities';

  Future<List<RunActivity>> getRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_runsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => RunActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RunActivity>> saveRun(RunActivity run) async {
    final currentRuns = await getRuns();
    final nextRuns = [run, ...currentRuns];
    await saveRuns(nextRuns);
    return nextRuns;
  }

  Future<List<RunActivity>> deleteRun(String id) async {
    final currentRuns = await getRuns();
    final nextRuns = currentRuns.where((run) => run.id != id).toList();
    await saveRuns(nextRuns);
    return nextRuns;
  }

  Future<void> saveRuns(List<RunActivity> runs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(runs.map((run) => run.toJson()).toList());
    await prefs.setString(_runsKey, encoded);
  }
}
