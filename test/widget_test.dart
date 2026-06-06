import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_english_app/screens/home_screen.dart';
import 'package:my_english_app/services/translation_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('홈 화면이 브랜드명과 시작 버튼을 렌더링한다', (tester) async {
    TranslationService.isKorean = true;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle(); // FutureBuilder + 애니메이션 타이머 정리

    expect(find.text('PronouncePro'), findsOneWidget);
    expect(find.text(TranslationService.get('home_start')), findsOneWidget);
    expect(find.text(TranslationService.get('home_tagline')), findsOneWidget);
  });

  testWidgets('언어 토글 버튼이 존재한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.translate), findsOneWidget);
  });
}
