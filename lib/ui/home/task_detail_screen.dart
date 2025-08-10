import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../category/category_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task; // bản copy để chỉnh

  @override
  void initState() {
    super.initState();
    _task = Task(
      title: widget.task.title,
      description: widget.task.description,
      isCompleted: widget.task.isCompleted,
      category: widget.task.category,
      priority: widget.task.priority,
      date: widget.task.date,
      time: widget.task.time,
    );
  }

  String get _dateLabel => DateFormat('EEE, d MMM', 'vi')
      .format(_task.date)
      .replaceAll('.', '');

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.greenAccent;
    }
  }

  Future<void> _editTitleDesc() async {
    final titleCtrl = TextEditingController(text: _task.title);
    final descCtrl = TextEditingController(text: _task.description);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sửa tiêu đề', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Mô tả',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              setState(() {
                _task.title = titleCtrl.text.trim().isEmpty ? _task.title : titleCtrl.text.trim();
                _task.description = descCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _task.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.purple,
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _task.date = picked);
  }

  Future<void> _editTime() async {
    final parts = _task.time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.last) ?? 0,
    );
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.purple,
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() => _task.time =
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _editCategory() async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          selectedCategory: _task.category,
          onCategorySelected: (name) {},
        ),
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _task.category = name);
    }
  }

  Future<void> _editPriority() async {
    final priorities = TaskPriority.values;
    TaskPriority picked = _task.priority;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Độ ưu tiên', style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: priorities.map((p) {
            final selected = p == picked;
            return ChoiceChip(
              label: Text(
                p == TaskPriority.high
                    ? 'P1'
                    : p == TaskPriority.medium
                    ? 'P2'
                    : 'P3',
              ),
              selected: selected,
              onSelected: (_) => picked = p,
              selectedColor: _priorityColor(p).withOpacity(.25),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _priorityColor(p)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              setState(() => _task.priority = picked);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Xoá công việc', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn chắc muốn xoá:\n“${_task.title}” ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    }
  }

  void _saveAndClose() {
    Navigator.pop(context, _task); // trả Task đã chỉnh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // Title + desc
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _task.isCompleted = !_task.isCompleted),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _task.isCompleted ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _task.isCompleted ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: _task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _task.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _task.description.isEmpty ? 'Không có mô tả' : _task.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editTitleDesc,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Time
          _Tile(
            icon: Icons.schedule,
            title: 'Thời gian',
            trailing: Text('$_dateLabel  •  ${_task.time}',
                style: const TextStyle(color: Colors.white70)),
            onTap: () async {
              await _editDate();
              await _editTime();
            },
          ),

          // Category
          _Tile(
            icon: Icons.label_outline,
            title: 'Danh mục',
            trailing: _Chip(text: _task.category),
            onTap: _editCategory,
          ),

          // Priority
          _Tile(
            icon: Icons.flag_outlined,
            title: 'Độ ưu tiên',
            trailing: _Chip(
              text: _task.priority == TaskPriority.high
                  ? 'P1'
                  : _task.priority == TaskPriority.medium
                  ? 'P2'
                  : 'P3',
              color: _priorityColor(_task.priority),
            ),
            onTap: _editPriority,
          ),

          const SizedBox(height: 28),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saveAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E7CFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lưu thay đổi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      tileColor: const Color(0xFF1A1A1A),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? color;

  const _Chip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c),
      ),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}
