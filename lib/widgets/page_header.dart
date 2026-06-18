// page_header.dart: 각 탭 화면 상단의 뒤로가기 버튼과 제목을 표시합니다.
import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onBack,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new),
          color: const Color(0xFF111111),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF2F3F5),
            fixedSize: const Size(46, 46),
          ),
          tooltip: '뒤로가기',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(icon, size: 34, color: const Color(0xFF111111)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
