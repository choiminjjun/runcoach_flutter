// screenshot_ocr_card.dart: 이미지 캡처를 업로드하여 OCR을 구동시키는 카드 위젯입니다.
import 'package:flutter/material.dart';

class ScreenshotOcrCard extends StatelessWidget {
  const ScreenshotOcrCard({
    super.key,
    required this.onPickAndParse,
    required this.isLoading,
  });

  final VoidCallback onPickAndParse;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF), // OCR용 밝은 파랑 배경
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2D9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A84FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '러닝 캡처 OCR 연동',
                style: TextStyle(
                  color: Color(0xFF0056B3),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '스마트워치나 러닝 앱의 스크린샷을 업로드하면 날짜, 거리, 시간, 심박수, 칼로리, 페이스, 케이던스 등을 텍스트 인식으로 자동 추출해 줍니다.',
            style: TextStyle(
              color: Color(0xFF424D5A),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ML Kit OCR 분석',
                style: TextStyle(
                  color: Color(0xFF5A6B7C),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ElevatedButton.icon(
                onPressed: isLoading ? null : onPickAndParse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFC2D9FF),
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
                    : const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text(
                  '러닝 캡처 불러오기',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
