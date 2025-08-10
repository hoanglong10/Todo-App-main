import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uptodo/ui/onboarding/onboarding_page_view.dart';
import 'package:uptodo/ui/onboarding/onboarding_child_page.dart';
import 'package:uptodo/ui/auth/start_screen.dart';

void main() {
  testWidgets('Onboarding: next pages and finish to StartScreen', (tester) async {
    // Tăng size để tránh overflow
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.byType(OnboardingChildPage), findsOneWidget);

    // Nhấn "TIẾP THEO"
    final nextBtn = find.widgetWithText(ElevatedButton, 'TIẾP THEO');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Nhấn tiếp cho đến trang cuối (nếu còn)
    if (nextBtn.evaluate().isNotEmpty) {
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
    }

    // Trang cuối: nút "BẮT ĐẦU"
    final startBtn = find.widgetWithText(ElevatedButton, 'BẮT ĐẦU');
    if (startBtn.evaluate().isNotEmpty) {
      await tester.tap(startBtn);
      await tester.pumpAndSettle();
    }

    expect(find.byType(StartScreen), findsOneWidget);
  });
}
