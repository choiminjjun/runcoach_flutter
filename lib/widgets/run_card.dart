// run_card.dart: 러닝 기록 1건을 카드 형태로 보여주는 공통 위젯입니다.
import 'package:flutter/material.dart';
import '../models/run_activity.dart';
import '../utils/pace_utils.dart';

class RunCard extends StatelessWidget {
  const RunCard({
    super.key,
    required this.run,
    this.onDelete,
    this.compact = false,
  });

  final RunActivity run;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isMockStrava = run.source == 'mock_strava';
    final isOcr = run.source == 'screenshot_ocr';

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFECEEF0);
    double borderWidth = 1.0;
    Color shadowColor = const Color(0x0A000000);

    Color badgeBgColor = const Color(0xFFE8F5E9);
    Color badgeTextColor = const Color(0xFF2E7D32);
    String badgeText = 'Manual';

    if (isMockStrava) {
      bgColor = const Color(0xFFFFF5F0);
      borderColor = const Color(0xFFFFD4C2);
      borderWidth = 1.5;
      shadowColor = const Color(0x0FCE3A00);
      badgeBgColor = const Color(0xFFFFEBE1);
      badgeTextColor = const Color(0xFFE65100);
      badgeText = 'Mock Strava';
    } else if (isOcr) {
      bgColor = const Color(0xFFF0F5FF);
      borderColor = const Color(0xFFC2D9FF);
      borderWidth = 1.5;
      shadowColor = const Color(0x0F0056B3);
      badgeBgColor = const Color(0xFFDEEBFF);
      badgeTextColor = const Color(0xFF0056B3);
      badgeText = 'Screenshot OCR';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          run.dateText,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatDistance(run.distanceKm)} / ${formatDuration(run.durationSeconds)} / ${formatPace(run.paceSecondsPerKm)}',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFFF3B30),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Text(
            '컨디션: ${run.condition.isEmpty ? '미입력' : run.condition}',
            style: _detailStyle,
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              '메모: ${run.note.isEmpty ? '메모 없음' : run.note}',
              style: _detailStyle,
            ),
          ],
          // Optional Health/Fitness Metrics Section
          if (run.calories != null ||
              run.elevationGainM != null ||
              run.averageHeartRate != null ||
              run.cadence != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (run.calories != null)
                  _MetricLabel(icon: Icons.local_fire_department, label: '칼로리', value: '${run.calories} kcal'),
                if (run.elevationGainM != null)
                  _MetricLabel(icon: Icons.filter_hdr, label: '고도 상승', value: '${run.elevationGainM!.toStringAsFixed(1)} m'),
                if (run.averageHeartRate != null)
                  _MetricLabel(icon: Icons.favorite, label: '심박수', value: '${run.averageHeartRate} bpm'),
                if (run.cadence != null)
                  _MetricLabel(icon: Icons.directions_walk, label: '케이던스', value: '${run.cadence} spm'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF777777)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

const _detailStyle = TextStyle(
  color: Color(0xFF555555),
  fontSize: 14,
  height: 1.4,
  fontWeight: FontWeight.w700,
);
