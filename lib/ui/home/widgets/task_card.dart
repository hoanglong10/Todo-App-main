import 'package:flutter/material.dart';
import 'package:uptodo/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  const TaskCard({super.key, required this.task, required this.onToggleComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[700]!,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleComplete,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(color: task.isCompleted ? Colors.green : Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: task.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Hôm Nay Lúc ${task.time}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Chỉ hiển thị Priority tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _priorityColor(task.priority).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'P${_priorityNumber(task.priority)}',
                        style: TextStyle(
                          color: _priorityColor(task.priority),
                          fontSize: 12, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }

  int _priorityNumber(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 1;
      case TaskPriority.medium: return 2;
      case TaskPriority.low: return 3;
    }
  }
}
