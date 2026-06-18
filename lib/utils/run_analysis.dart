// run_analysis.dart: 저장된 러닝 기록을 통계와 분석 데이터로 변환합니다.
import '../models/run_activity.dart';
import 'pace_utils.dart';

class RunAnalysisResult {
  RunAnalysisResult({
    required this.totalRuns,
    required this.totalDistance,
    required this.totalDuration,
    required this.averagePace,
    required this.weekDistance,
    required this.longestRun,
    required this.fastestRun,
    required this.streak,
    required this.manualCount,
    required this.mockStravaCount,
    required this.ocrCount,
    required this.totalCalories,
    required this.totalElevationGain,
    required this.averageHeartRate,
    required this.averageCadence,
    required this.comment,
  });

  final int totalRuns;
  final double totalDistance;
  final int totalDuration;
  final int averagePace;
  final double weekDistance;
  final RunActivity? longestRun;
  final RunActivity? fastestRun;
  final int streak;
  final int manualCount;
  final int mockStravaCount;
  final int ocrCount;

  // 확장 건강 지표
  final int totalCalories;
  final double totalElevationGain;
  final int averageHeartRate; // null 제외 평균
  final int averageCadence;   // null 제외 평균

  final String comment;
}

List<RunActivity> sortRuns(List<RunActivity> runs) {
  final sorted = [...runs];
  sorted.sort((a, b) => b.date.compareTo(a.date));
  return sorted;
}

DateTime _startOfWeek(DateTime date) {
  final start = DateTime(date.year, date.month, date.day);
  final diffToMonday = start.weekday - DateTime.monday;
  return start.subtract(Duration(days: diffToMonday));
}

double getWeekDistance(List<RunActivity> runs, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final weekStart = _startOfWeek(today);
  final weekEnd = today.add(const Duration(days: 1)); // Include today up to midnight
  
  return runs.fold(0.0, (sum, run) {
    final runDate = run.date;
    final normalized = DateTime(runDate.year, runDate.month, runDate.day);
    if (!normalized.isBefore(weekStart) && normalized.isBefore(weekEnd)) {
      return sum + run.distanceKm;
    }
    return sum;
  });
}

int getCurrentStreak(List<RunActivity> runs, [DateTime? now]) {
  if (runs.isEmpty) return 0;
  
  final runDates = runs.map((run) => _dateText(run.date)).toSet();
  var cursor = now ?? DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);
  var streak = 0;

  if (runDates.contains(_dateText(cursor))) {
    while (runDates.contains(_dateText(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
  } else {
    final yesterday = cursor.subtract(const Duration(days: 1));
    if (runDates.contains(_dateText(yesterday))) {
      cursor = yesterday;
      while (runDates.contains(_dateText(cursor))) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
  }

  return streak;
}

RunAnalysisResult buildAnalysis(List<RunActivity> runs) {
  final totalRuns = runs.length;
  final totalDistance = runs.fold<double>(0.0, (sum, run) => sum + run.distanceKm);
  final totalDuration = runs.fold<int>(0, (sum, run) => sum + run.durationSeconds);
  final averagePace = calculatePaceSeconds(totalDistance, totalDuration);
  final weekDistance = getWeekDistance(runs);
  final streak = getCurrentStreak(runs);

  final manualCount = runs.where((r) => r.source == 'manual').length;
  final mockStravaCount = runs.where((r) => r.source == 'mock_strava').length;
  final ocrCount = runs.where((r) => r.source == 'screenshot_ocr').length;

  // 확장 건강 지표 누계 및 평균 계산 (null 제외)
  var totalCalories = 0;
  var totalElevationGain = 0.0;
  
  var heartRateSum = 0;
  var heartRateCount = 0;
  
  var cadenceSum = 0;
  var cadenceCount = 0;

  RunActivity? longestRun;
  RunActivity? fastestRun;

  for (final run in runs) {
    if (longestRun == null || run.distanceKm > longestRun.distanceKm) {
      longestRun = run;
    }
    if (run.paceSecondsPerKm > 0 &&
        (fastestRun == null || run.paceSecondsPerKm < fastestRun.paceSecondsPerKm)) {
      fastestRun = run;
    }

    if (run.calories != null) {
      totalCalories += run.calories!;
    }
    if (run.elevationGainM != null) {
      totalElevationGain += run.elevationGainM!;
    }
    if (run.averageHeartRate != null) {
      heartRateSum += run.averageHeartRate!;
      heartRateCount++;
    }
    if (run.cadence != null) {
      cadenceSum += run.cadence!;
      cadenceCount++;
    }
  }

  final averageHeartRate = heartRateCount > 0 ? (heartRateSum / heartRateCount).round() : 0;
  final averageCadence = cadenceCount > 0 ? (cadenceSum / cadenceCount).round() : 0;

  return RunAnalysisResult(
    totalRuns: totalRuns,
    totalDistance: totalDistance,
    totalDuration: totalDuration,
    averagePace: averagePace,
    weekDistance: weekDistance,
    longestRun: longestRun,
    fastestRun: fastestRun,
    streak: streak,
    manualCount: manualCount,
    mockStravaCount: mockStravaCount,
    ocrCount: ocrCount,
    totalCalories: totalCalories,
    totalElevationGain: totalElevationGain,
    averageHeartRate: averageHeartRate,
    averageCadence: averageCadence,
    comment: _analysisComment(totalRuns, weekDistance, averagePace, streak, averageHeartRate),
  );
}

String _analysisComment(
  int totalRuns,
  double weekDistance,
  int averagePace,
  int streak,
  int averageHeartRate,
) {
  if (totalRuns == 0) {
    return '첫 러닝을 기록하면 RunCoach가 페이스와 누적 데이터를 분석해 다음 러닝 방향을 제안합니다.';
  }
  if (averageHeartRate >= 165) {
    return '최근 평균 심박수(또는 평균)가 165 bpm 이상으로 다소 높습니다. 다음 러닝은 속도와 강도를 줄여 안전하게 달리는 심폐 회복 러닝을 권장합니다.';
  }
  if (weekDistance >= 20) {
    return '이번 주 누적 거리가 20km 이상으로 충분합니다. 다음 러닝은 피로가 누적되지 않도록 가벼운 Recovery Run을 추천합니다.';
  }
  if (streak >= 3) {
    return '3일 이상 연속으로 달리고 계십니다! 무리한 훈련은 부상을 유발하므로 하루 정도는 가볍게 걷거나 조깅을 섞어 주세요.';
  }
  if (averagePace > 0 && averagePace <= 360) {
    return '최근 평균 페이스가 빠른 편입니다. 훈련 효율을 극대화할 수 있도록 Tempo Run을 도전해 보세요.';
  }
  return '러닝 기록이 잘 쌓이고 있습니다. 무리하지 않고 체력을 천천히 키우는 것을 목표로 삼으세요.';
}

String _dateText(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
