import 'package:flutter_test/flutter_test.dart';
import 'package:uptodo/models/task.dart';

void main() {
  group('Task model', () {
    test('toMap -> fromMap roundtrip keeps data', () {
      final original = Task(
        id: 1,
        title: 'Write tests',
        description: 'Cover models and widgets',
        isCompleted: false,
        category: 'Work',
        priority: TaskPriority.high,
        date: DateTime(2025, 8, 10, 9, 0, 0),
        time: '09:00',
      );

      final map = original.toMap();
      final restored = Task.fromMap({
        ...map,
        'is_completed': original.isCompleted ? 1 : 0,
        'due_date': original.date.millisecondsSinceEpoch,
        'priority': original.priority.index,
      });

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.category, original.category);
      expect(restored.priority, original.priority);
      expect(restored.date, original.date);
      expect(restored.time, original.time);
    });
  });
}
