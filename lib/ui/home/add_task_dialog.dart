import 'package:flutter/material.dart';
import 'package:uptodo/models/task.dart';
import 'package:uptodo/ui/category/category_screen.dart';
import 'package:uptodo/data/settings_service.dart';

import '../../data/settings_controller.dart'; // settingsController để đọc 24h

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 15, minute: 45);
  String _category = 'Mới';
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final card = cs.surfaceVariant;
    final accent = cs.primary;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          height: MediaQuery.of(context).size.height * .9,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
                child: Row(
                  children: [
                    Text('Thêm Công Việc',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _section(context, 'Chi tiết'),
                      const SizedBox(height: 8),
                      _textField(
                        context,
                        controller: _titleCtrl,
                        hint: 'Tiêu đề (ví dụ: Làm bài tập Toán)',
                        prefix: Icons.edit_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                        fill: card,
                      ),
                      const SizedBox(height: 10),
                      _textField(
                        context,
                        controller: _descCtrl,
                        hint: 'Mô tả',
                        prefix: Icons.notes_rounded,
                        maxLines: 3,
                        fill: card,
                      ),

                      const SizedBox(height: 18),
                      _section(context, 'Lịch & thuộc tính'),
                      const SizedBox(height: 8),

                      Row(children: [
                        Expanded(child: _fieldTile(
                          context,
                          icon: Icons.event,
                          label: 'Ngày',
                          value: _formatDate(_date),
                          onTap: _pickDate,
                          fill: card,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _fieldTile(
                          context,
                          icon: Icons.access_time,
                          label: 'Giờ',
                          value: _formatTimeOfDay(_time),
                          onTap: _pickTime,
                          fill: card,
                        )),
                      ]),
                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(child: _fieldTile(
                          context,
                          icon: Icons.flag,
                          label: 'Ưu tiên',
                          value: _priorityLabel(_priority),
                          onTap: _pickPriority,
                          valueColor: _priorityColor(_priority),
                          fill: card,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _fieldTile(
                          context,
                          icon: Icons.label,
                          label: 'Danh mục',
                          value: _category,
                          valueColor: _categoryColor(_category),
                          onTap: _pickCategory,
                          fill: card,
                        )),
                      ]),

                      const SizedBox(height: 18),
                      _section(context, 'Tóm tắt'),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _infoChip(context, Icons.event, _formatDate(_date), fill: card),
                        _infoChip(context, Icons.access_time, _formatTimeOfDay(_time), fill: card),
                        _infoChip(context, Icons.flag, _priorityLabel(_priority),
                            color: _priorityColor(_priority), fill: card),
                        _infoChip(context, Icons.label, _category,
                            color: _categoryColor(_category), fill: card),
                      ]),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 12, offset: const Offset(0, -4))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('LƯU CÔNG VIỆC',
                        style: theme.textTheme.titleSmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700, letterSpacing: .3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _section(BuildContext context, String title) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: cs.onSurfaceVariant, fontWeight: FontWeight.w700,
        ));
  }

  Widget _textField(
      BuildContext context, {
        required TextEditingController controller,
        required String hint,
        required Color fill,
        IconData? prefix,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        prefixIcon: prefix == null ? null : Icon(prefix, color: cs.onSurfaceVariant),
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _fieldTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required VoidCallback onTap,
        required Color fill,
        Color? valueColor,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          Icon(icon, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? cs.onSurface, fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text, {Color? color, required Color fill}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: fill, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color ?? cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color ?? cs.onSurfaceVariant, fontSize: 12)),
      ]),
    );
  }

  // ---------- pickers ----------
  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (c, child) => Theme(data: theme, child: child!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final theme = Theme.of(context);
    final use24 = settingsController.state.use24hTime;
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (c, child) => Theme(
        data: theme,
        child: MediaQuery( // ép 24h nếu bật trong cài đặt
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24),
          child: child!,
        ),
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickPriority() async {
    final result = await showModalBottomSheet<TaskPriority>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        TaskPriority temp = _priority;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return StatefulBuilder(
          builder: (ctx, setModal) => SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Chọn độ ưu tiên', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _priorityChoice('Cao', TaskPriority.high, temp, (p) => setModal(() => temp = p), theme),
                  _priorityChoice('Trung bình', TaskPriority.medium, temp, (p) => setModal(() => temp = p), theme),
                  _priorityChoice('Thấp', TaskPriority.low, temp, (p) => setModal(() => temp = p), theme),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Đang chọn: ${_priorityLabel(temp)}', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('Lưu')),
                ]),
              ]),
            ),
          ),
        );
      },
    );
    if (result != null && mounted) setState(() => _priority = result);
  }

  Widget _priorityChoice(
      String label,
      TaskPriority value,
      TaskPriority current,
      void Function(TaskPriority) onPick,
      ThemeData theme,
      ) {
    final cs = theme.colorScheme;
    final selected = value == current;
    final color = _priorityColor(value);
    return ChoiceChip(
      label: Text(label),
      showCheckmark: false,
      selected: selected,
      selectedColor: color.withOpacity(.22),
      backgroundColor: cs.surfaceVariant,
      side: BorderSide(color: selected ? color : cs.outlineVariant),
      labelStyle: TextStyle(color: selected ? color : cs.onSurfaceVariant, fontWeight: FontWeight.w700),
      onSelected: (_) => onPick(value),
    );
  }

  Future<void> _pickCategory() async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(selectedCategory: _category, onCategorySelected: (_) {}),
      ),
    );
    if (name != null && name.isNotEmpty) setState(() => _category = name);
  }

  // ---------- save ----------
  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final task = Task(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isCompleted: false,
      category: _category,
      priority: _priority,
      date: _date,
      time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
    );
    Navigator.pop(context, task);
  }

  // ---------- utils ----------
  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _priorityLabel(TaskPriority p) =>
      switch (p) { TaskPriority.high => 'Cao', TaskPriority.medium => 'Trung bình', TaskPriority.low => 'Thấp' };

  Color _priorityColor(TaskPriority p) =>
      switch (p) { TaskPriority.high => Colors.red, TaskPriority.medium => Colors.orange, TaskPriority.low => Colors.green };

  Color _categoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'đại học': return Colors.blue;
      case 'công việc': return Colors.orange;
      case 'cá nhân': return Colors.green;
      case 'mới': return Theme.of(context).colorScheme.primary;
      default:
        final n = name.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
        final hue = (n * 37) % 360;
        return HSLColor.fromAHSL(1, hue.toDouble(), .60, .52).toColor();
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final use24 = settingsController.state.use24hTime;
    return MaterialLocalizations.of(context).formatTimeOfDay(t, alwaysUse24HourFormat: use24);
  }
}
