// recommendation.dart: 누적된 러닝 기록과 건강 지표를 분석하여 다음 러닝을 추천합니다.
import '../models/run_activity.dart';
import 'pace_utils.dart';
import 'run_analysis.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.name,
    required this.distanceKm,
    required this.targetPaceSeconds,
    required this.reason,
  });

  final String name;
  final double distanceKm;
  final int targetPaceSeconds;
  final String reason;

  String get targetPaceText => formatPace(targetPaceSeconds);
}

RecommendationResult getRecommendation(List<RunActivity> runs) {
  if (runs.isEmpty) {
    // 규칙 1: 기록 없음 → Easy Run 3km
    return const RecommendationResult(
      name: 'Easy Run',
      distanceKm: 3.0,
      targetPaceSeconds: 420, // 7:00
      reason: '등록된 러닝 기록이 없어 가볍게 시작할 수 있는 Easy Run 3km를 추천합니다.',
    );
  }

  // 1. 정렬된 최신 기록 추출
  final sortedRuns = sortRuns(runs);
  
  // 2. 지표 계산
  final weekDistance = getWeekDistance(runs);
  final streak = getCurrentStreak(runs);
  
  // 최근 3회 기록 분석
  final last3Runs = sortedRuns.take(3).toList();
  
  // 최근 3회 평균 페이스 계산
  var last3PaceSum = 0;
  var validPaceCount = 0;
  for (final r in last3Runs) {
    if (r.paceSecondsPerKm > 0) {
      last3PaceSum += r.paceSecondsPerKm;
      validPaceCount++;
    }
  }
  final recentAveragePace = validPaceCount > 0 ? (last3PaceSum / validPaceCount).round() : 0;

  // 최근 컨디션 중 "힘듦" 횟수
  final hardConditionCount = last3Runs.where((r) => r.condition == '힘듦').length;

  // 최근 3회 평균 심박수 계산
  var last3HrSum = 0;
  var validHrCount = 0;
  for (final r in last3Runs) {
    if (r.averageHeartRate != null && r.averageHeartRate! > 0) {
      last3HrSum += r.averageHeartRate!;
      validHrCount++;
    }
  }
  final recentAverageHeartRate = validHrCount > 0 ? (last3HrSum / validHrCount).round() : 0;

  // 3. 규칙 적용 (우선순위 순서대로 체크)
  
  // 규칙 2: 이번 주 누적 거리가 20km 이상이면 Recovery Run 3km 추천
  if (weekDistance >= 20.0) {
    return const RecommendationResult(
      name: 'Recovery Run',
      distanceKm: 3.0,
      targetPaceSeconds: 480, // 8:00
      reason: '이번 주 누적 거리가 20km 이상입니다. 피로가 쌓인 몸을 회복하기 위해 가벼운 Recovery Run을 추천합니다.',
    );
  }

  // 규칙 3: 최근 컨디션이 2회 이상 “힘듦”이면 Recovery Run 3km 추천
  if (hardConditionCount >= 2) {
    return const RecommendationResult(
      name: 'Recovery Run',
      distanceKm: 3.0,
      targetPaceSeconds: 480, // 8:00
      reason: '최근 3회 중 2회 이상 컨디션이 "힘듦"으로 기록되었습니다. 부상을 예방하고 피로를 풀기 위해 Recovery Run을 권장합니다.',
    );
  }

  // 규칙 4: 최근 평균 페이스가 7분/km보다 느리면 Easy Run 3km 추천
  if (recentAveragePace > 420) {
    return const RecommendationResult(
      name: 'Easy Run',
      distanceKm: 3.0,
      targetPaceSeconds: 450, // 7:30
      reason: '최근 평균 페이스가 7분/km보다 느립니다. 기초 체력과 러닝 폼을 다지기 위한 Easy Run을 추천합니다.',
    );
  }

  // 규칙 5: 최근 평균 페이스가 6분/km 이하이고 이번 주 거리가 20km 미만이면 Tempo Run 4km 추천
  if (recentAveragePace > 0 && recentAveragePace <= 360 && weekDistance < 20.0) {
    return const RecommendationResult(
      name: 'Tempo Run',
      distanceKm: 4.0,
      targetPaceSeconds: 330, // 5:30
      reason: '최근 평균 페이스가 6분/km 이하로 준수하며 주간 누적 거리가 20km 미만입니다. 페이스 훈련용 Tempo Run으로 심폐 지구력을 높여보세요.',
    );
  }

  // 규칙 6: 최근 평균 심박수 >= 165 이면 Recovery Run 3km 추천
  if (recentAverageHeartRate >= 165) {
    return const RecommendationResult(
      name: 'Recovery Run',
      distanceKm: 3.0,
      targetPaceSeconds: 480, // 8:00
      reason: '최근 평균 심박수가 165 bpm 이상으로 높게 기록되었습니다. 심혈관계 피로를 낮추고 회복을 돕는 가벼운 Recovery Run을 가질 것을 추천합니다.',
    );
  }

  // 규칙 7: streak가 3일 이상이면 무리하지 않도록 Easy Run 또는 Recovery Run 추천
  if (streak >= 3) {
    return const RecommendationResult(
      name: 'Easy Run',
      distanceKm: 3.0,
      targetPaceSeconds: 420, // 7:00
      reason: '3일 연속 러닝으로 좋은 흐름을 유지하고 계십니다! 과훈련을 방지하고 에너지를 안배하기 위해 가벼운 Easy Run을 추천합니다.',
    );
  }

  // 규칙 8: 그 외에는 Easy Run 4km 추천
  return const RecommendationResult(
    name: 'Easy Run',
    distanceKm: 4.0,
    targetPaceSeconds: 390, // 6:30
    reason: '몸 상태와 주간 거리가 모두 양호합니다. 러닝 리듬 유지와 기초 강화를 위한 기본 Easy Run 4km를 추천합니다.',
  );
}
