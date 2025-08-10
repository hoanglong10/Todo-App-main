import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uptodo/ui/home/widgets/empty_state.dart';

void main() {
  testWidgets('HomeEmptyState shows CTA text and icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeEmptyState())));

    expect(find.text('Bạn muốn làm gì hôm nay?'), findsOneWidget);
    expect(find.byIcon(Icons.task_alt), findsOneWidget);

    // Đúng với code hiện tại của bạn
    expect(find.text('Nhấn + để thêm công việc'), findsOneWidget);
  });
}
