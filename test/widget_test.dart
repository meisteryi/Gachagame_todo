// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gacha_todo/main.dart';

void main() {
  testWidgets('Gacha Todo smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GachaTodoApp());

    // 앱이 정상적으로 빌드되고 메인 타이틀과 수조 영역이 화면에 보이는지 확인합니다.
    expect(find.text('가챠 투두 🎲'), findsOneWidget);
    expect(find.text('🐟 수조 영역 🐠'), findsOneWidget);
  });
}
