import 'package:flutter_test/flutter_test.dart';
import 'package:runcoach/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RunCoach shows the main tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RunCoachApp());
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsWidgets);
    expect(find.text('활동'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('분석'), findsOneWidget);
    expect(find.text('오늘의 러닝 상태를 확인해 보세요.'), findsOneWidget);
  });
}
