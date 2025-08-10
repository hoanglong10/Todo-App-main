import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uptodo/models/task.dart';
import 'package:uptodo/ui/home/widgets/task_card.dart';

void main() {
  testWidgets('TaskCard shows title and toggles on tap', (tester) async {
    var toggled = false;

    final task = Task(
      id: 1,
      title: 'Demo task',
      description: 'desc',
      isCompleted: false,
      category: 'Home',
      priority: TaskPriority.medium,
      date: DateTime(2025, 8, 10),
      time: '12:00',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskCard(task: task, onToggleComplete: () { toggled = true; }),
      ),
    ));

    expect(find.text('Demo task'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(toggled, isTrue);
  });
}
