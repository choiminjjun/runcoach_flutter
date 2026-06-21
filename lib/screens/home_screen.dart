// home_screen.dart: 앱 첫 화면으로 요약 통계, 추천 러닝, 최근 기록을 보여줍니다.
import 'package:flutter/material.dart';

import '../models/run_activity.dart';
import '../utils/run_analysis.dart';
import '../utils/pace_utils.dart';
import '../utils/recommendation.dart';
import '../widgets/page_header.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/run_card.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.runs, required this.onBack});

  final List<RunActivity> runs;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final analysis = buildAnalysis(runs);
    final recommendation = getRecommendation(runs);
    final sortedRuns = sortRuns(runs);
    final latestRun = sortedRuns.isEmpty ? null : sortedRuns.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
      children: [
        PageHeader(
          title: '홈',
          description: '오늘의 러닝 상태를 확인해 보세요.',
          icon: Icons.home_outlined,
          onBack: onBack,
        ),
        const SizedBox(height: 26),
        RecommendationCard(recommendation: recommendation),
        const SizedBox(height: 24),
        const Text(
          '이번 주 러닝 요약',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          children: [
            StatCard(
              label: '이번 주 누적 거리',
              value: formatDistance(analysis.weekDistance),
            ),
            StatCard(
              label: '총 러닝 횟수',
              value: '${analysis.totalRuns}회',
              accent: Colors.black,
            ),
            StatCard(
              label: '평균 페이스',
              value: formatPace(analysis.averagePace),
              accent: const Color(0xFF30D158),
            ),
            StatCard(
              label: '현재 streak',
              value: '${analysis.streak}일',
              accent: const Color(0xFFFF2D55),
            ),
            StatCard(
              label: '수동 기록 수',
              value: '${analysis.manualCount}회',
              accent: const Color(0xFF0A84FF),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          '최근 기록 미리보기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        if (latestRun == null)
          const _EmptyCard(
            title: '아직 러닝 기록이 없습니다.',
            text: '활동 탭에서 첫 러닝을 직접 입력하거나 실시간 러닝을 시작해 보세요.',
          )
        else
          RunCard(run: latestRun, compact: true),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
