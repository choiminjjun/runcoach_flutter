// analysis_screen.dart: 누적 러닝 데이터를 통계와 코멘트, 추천 가이드로 보여줍니다.
import 'package:flutter/material.dart';

import '../models/run_activity.dart';
import '../utils/run_analysis.dart';
import '../utils/pace_utils.dart';
import '../utils/recommendation.dart';
import '../widgets/page_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/recommendation_card.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key, required this.runs, required this.onBack});

  final List<RunActivity> runs;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final analysis = buildAnalysis(runs);
    final recommendation = getRecommendation(runs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
      children: [
        PageHeader(
          title: '분석',
          description: '누적 데이터를 바탕으로 러닝 흐름을 확인하세요.',
          icon: Icons.bar_chart_outlined,
          onBack: onBack,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RunCoach 리포트',
                style: TextStyle(
                  color: Color(0xFFA8F7C9),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatDistance(analysis.totalDistance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '총 누적 거리',
                style: TextStyle(
                  color: Color(0xFFCFCFCF),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            final cards = [
              StatCard(
                label: '총 러닝 횟수',
                value: '${analysis.totalRuns}회',
                accent: Colors.black,
              ),
              StatCard(
                label: '총 러닝 시간',
                value: formatDuration(analysis.totalDuration),
              ),
              StatCard(
                label: '평균 페이스',
                value: formatPace(analysis.averagePace),
                accent: const Color(0xFF30D158),
              ),
              StatCard(
                label: '이번 주 거리',
                value: formatDistance(analysis.weekDistance),
                accent: const Color(0xFFFF2D55),
              ),
              StatCard(
                label: '가장 긴 러닝',
                value: analysis.longestRun == null
                    ? '0.0km'
                    : formatDistance(analysis.longestRun!.distanceKm),
              ),
              StatCard(
                label: '가장 빠른 페이스',
                value: analysis.fastestRun == null
                    ? '-\'--"/km'
                    : formatPace(analysis.fastestRun!.paceSecondsPerKm),
                accent: const Color(0xFF30D158),
              ),
              StatCard(
                label: '현재 streak',
                value: '${analysis.streak}일',
                accent: const Color(0xFFFF9500),
              ),
              StatCard(
                label: '수동 기록 수',
                value: '${analysis.manualCount}회',
                accent: const Color(0xFF0A84FF),
              ),
              StatCard(
                label: 'Mock Strava 기록 수',
                value: '${analysis.mockStravaCount}회',
                accent: const Color(0xFFFC5200),
              ),
              StatCard(
                label: 'Screenshot OCR 수',
                value: '${analysis.ocrCount}회',
                accent: const Color(0xFF00C7BE),
              ),
              StatCard(
                label: '총 칼로리 소모',
                value: '${analysis.totalCalories} kcal',
                accent: const Color(0xFFFF9500),
              ),
              StatCard(
                label: '총 고도 상승',
                value: '${analysis.totalElevationGain.toStringAsFixed(1)} m',
                accent: const Color(0xFFAF52DE),
              ),
              StatCard(
                label: '평균 심박수',
                value: analysis.averageHeartRate > 0 ? '${analysis.averageHeartRate} bpm' : '- bpm',
                accent: const Color(0xFFFF2D55),
              ),
              StatCard(
                label: '평균 케이던스',
                value: analysis.averageCadence > 0 ? '${analysis.averageCadence} spm' : '- spm',
                accent: const Color(0xFF5856D6),
              ),
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBEAFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '분석 코멘트',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                analysis.comment,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RecommendationCard(recommendation: recommendation),
      ],
    );
  }
}
