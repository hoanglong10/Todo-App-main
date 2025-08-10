import 'package:flutter/material.dart';
import 'package:uptodo/models/task.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task task) onToggleComplete;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final todayTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search (UI thôi, chưa lọc)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filter mẫu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Text('Hôm Nay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                if (todayTasks.isNotEmpty) ...[
                  _sectionHeader('Hôm Nay'),
                  ...todayTasks.map((t) => TaskCard(task: t, onToggleComplete: () => onToggleComplete(t))),
                ],
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionHeader('Đã Hoàn Thành'),
                  ...completedTasks.map((t) => TaskCard(task: t, onToggleComplete: () => onToggleComplete(t))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
