// mock_strava_service.dart: assets/mock_strava_runs.json에서 가짜 Strava 기록을 불러옵니다.
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/run_activity.dart';

class MockStravaService {
  // 나중에 실제 Strava API 연동으로 확장 시 이 클래스 인터페이스를 상속 또는 변경하여 사용할 수 있습니다.
  Future<List<RunActivity>> fetchMockRuns() async {
    try {
      final jsonString = await rootBundle.loadString('assets/mock_strava_runs.json');
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) {
        return RunActivity.fromMockStravaJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환 혹은 throw
      return [];
    }
  }
}
