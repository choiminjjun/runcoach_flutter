// mock_strava_card.dart: Strava 연동 및 가짜 데이터 가져오기 기능을 담당하는 카드 위젯입니다.
import 'package:flutter/material.dart';

class MockStravaCard extends StatelessWidget {
  const MockStravaCard({
    super.key,
    required this.onImport,
    required this.importedCount,
    required this.isLoading,
  });

  final VoidCallback onImport;
  final int importedCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0), // Strava orange-ish light tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFC5200), // Strava Orange color
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Strava 연동 (Mock)',
                style: TextStyle(
                  color: Color(0xFFD03B00),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '실제 Strava API를 시뮬레이션하여 로컬의 가짜 러닝 기록을 가져올 수 있습니다. 기기 로컬 데이터에 병합 저장됩니다.',
            style: TextStyle(
              color: Color(0xFF5A4A42),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '가져온 기록: $importedCount개',
                style: const TextStyle(
                  color: Color(0xFF7A6A62),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ElevatedButton.icon(
                onPressed: isLoading ? null : onImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC5200),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFFD4C2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: const Text(
                  '기록 가져오기',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
