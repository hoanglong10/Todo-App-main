import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

class Task {
  int? id;                 // <-- thêm id
  String title;
  String description;
  bool isCompleted;
  String category;
  TaskPriority priority;
  DateTime date;
  String time;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.category,
    required this.priority,
    required this.date,
    required this.time,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? category,
    TaskPriority? priority,
    DateTime? date,
    String? time,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'is_completed': isCompleted ? 1 : 0,
    'category': category,
    'priority': priority.index, // high=0, medium=1, low=2
    'due_date': date.millisecondsSinceEpoch,
    'time': time,
  };

  factory Task.fromMap(Map<String, Object?> m) => Task(
    id: m['id'] as int?,
    title: (m['title'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    isCompleted: (m['is_completed'] as int) == 1,
    category: (m['category'] ?? '') as String,
    priority: TaskPriority.values[(m['priority'] as int)],
    date: DateTime.fromMillisecondsSinceEpoch((m['due_date'] ?? 0) as int),
    time: (m['time'] ?? '') as String,
  );
}
