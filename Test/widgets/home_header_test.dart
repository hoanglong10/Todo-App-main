import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uptodo/ui/home/widgets/header.dart';

void main() {
  testWidgets('HomeHeader renders title and menu/profile buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeHeader())));

    expect(find.text('Trang Chủ'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
