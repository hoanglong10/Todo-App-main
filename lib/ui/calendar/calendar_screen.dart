import 'package:flutter/material.dart';
import 'package:uptodo/models/task.dart';
import 'package:uptodo/data/task_dao.dart';
import 'package:uptodo/ui/home/add_task_dialog.dart';
import 'package:uptodo/ui/home/widgets/edit_task_dialog.dart';
import '../../data/settings_controller.dart';

enum CalSort { timeAsc, timeDesc, priority }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final _dao = TaskDao();

  DateTime _selected = DateTime.now();
  List<Task> _items = [];
  bool _loading = true;
  bool _showCompleted = false;
  CalSort _sort = CalSort.timeAsc;

  // đếm số task theo ngày trong tuần đang xem
  Map<DateTime, int> _weekCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Cho HomeScreen gọi khi chuyển tab hoặc vừa thêm/sửa task
  void reload({DateTime? date}) {
    if (date != null) {
      _selected = DateTime(date.year, date.month, date.day);
    }
    _load();
  }

  // ---------- helpers ----------
  DateTime _onlyDay(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _sameDay(DateTime a, DateTime b) => _onlyDay(a) == _onlyDay(b);
  DateTime _weekStart(DateTime d) => d.subtract(Duration(days: d.weekday % 7)); // CN..T7
  List<DateTime> _weekDays(DateTime d) =>
      List.generate(7, (i) => _weekStart(d).add(Duration(days: i)));

  // tải: list của ngày, + đếm số việc từng ngày trong tuần
  Future<void> _load() async {
    setState(() => _loading = true);

    final all = await _dao.getAll();

    // lọc theo selected
    final list = all.where((t) => _sameDay(t.date, _selected)).toList();

    // sắp xếp
    list.sort((a, b) {
      int timeOf(Task t) => t.time.isEmpty ? -1 : int.tryParse(t.time.replaceAll(':', '')) ?? -1;
      if (_sort == CalSort.priority) {
        int rank(TaskPriority p) => p == TaskPriority.high ? 0 : (p == TaskPriority.medium ? 1 : 2);
        final rp = rank(a.priority).compareTo(rank(b.priority));
        if (rp != 0) return rp;
        return timeOf(a).compareTo(timeOf(b));
      }
      if (_sort == CalSort.timeAsc) {
        return timeOf(a).compareTo(timeOf(b));
      } else {
        return timeOf(b).compareTo(timeOf(a));
      }
    });

    // đếm theo tuần
    final week = _weekDays(_selected).map(_onlyDay).toList();
    final counts = <DateTime, int>{for (final d in week) d: 0};
    for (final t in all) {
      final d = _onlyDay(t.date);
      if (counts.containsKey(d)) {
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _items = list;
      _weekCounts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final use24h = settingsController.state.use24hTime;

    final active = _items.where((e) => !e.isCompleted).toList();
    final done   = _items.where((e) =>  e.isCompleted).toList();
    final showing = _showCompleted ? done : active;

    return Scaffold(
      // dùng theme thay vì màu cứng
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Lịch', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: cs.onSurface),
        actions: [
          // chọn sắp xếp
          PopupMenuButton<CalSort>(
            icon: const Icon(Icons.sort),
            onSelected: (v) {
              setState(() => _sort = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: CalSort.timeAsc,  child: Text('Sắp xếp: Giờ ↑')),
              PopupMenuItem(value: CalSort.timeDesc, child: Text('Sắp xếp: Giờ ↓')),
              PopupMenuItem(value: CalSort.priority, child: Text('Sắp xếp: Ưu tiên')),
            ],
          ),
          IconButton(
            tooltip: 'Hôm nay',
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() => _selected = _onlyDay(DateTime.now()));
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _monthBar(cs),        // mũi tên ở đây chuyển tuần ±7 ngày
          const SizedBox(height: 8),
          _weekStrip(cs),       // chỉ hiển thị ngày + badge số việc
          const SizedBox(height: 10),
          _segment(cs),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : showing.isEmpty
                ? Center(child: Text('Không có công việc', style: TextStyle(color: cs.onSurfaceVariant)))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                itemCount: showing.length,
                itemBuilder: (_, i) => _taskTile(showing[i], use24h, cs),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () async {
          final t = await showModalBottomSheet<Task>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTaskDialog(),
          );
          if (t != null) {
            await _dao.insert(t);
            reload(date: t.date); // nhảy tới ngày mới thêm
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _monthBar(ColorScheme cs) {
    final text = 'Tháng ${_selected.month} ${_selected.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            // ➜ LÙI 1 TUẦN
            onPressed: () {
              setState(() => _selected = _onlyDay(_selected.subtract(const Duration(days: 7))));
              _load();
            },
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selected,
                firstDate: DateTime(2015),
                lastDate: DateTime(2100),
                helpText: 'Chọn ngày',
                builder: (ctx, child) {
                  // đảm bảo date picker cũng ăn theme
                  return Theme(data: Theme.of(ctx), child: child!);
                },
              );
              if (picked != null) {
                setState(() => _selected = _onlyDay(picked));
                _load();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Text(text, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Icon(Icons.calendar_month, size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // ➜ TIẾN 1 TUẦN
            onPressed: () {
              setState(() => _selected = _onlyDay(_selected.add(const Duration(days: 7))));
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _weekStrip(ColorScheme cs) {
    final days = _weekDays(_selected);
    String wd(int d) => ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][d % 7];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((d) {
          final sel = _sameDay(d, _selected);
          final key = _onlyDay(d);
          final count = _weekCounts[key] ?? 0;

          return GestureDetector(
            onTap: () { setState(() => _selected = key); _load(); },
            onLongPress: () async {
              final t = await showModalBottomSheet<Task>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddTaskDialog(),
              );
              if (t != null) {
                await _dao.insert(t);
                reload(date: t.date);
              }
            },
            child: Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? cs.primary.withOpacity(.15) : cs.surfaceVariant.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? cs.primary : cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    wd(d.weekday),
                    style: TextStyle(
                      color: sel ? cs.primary : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: sel ? cs.primary : Colors.transparent,
                    child: Text('${d.day}',
                        style: TextStyle(
                            color: sel ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: sel ? cs.primary : cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 10,
                              color: sel ? cs.onPrimary : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _segment(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _segBtn(
              cs,
              label: 'Chưa hoàn thành',
              selected: !_showCompleted,
              onTap: () => setState(() => _showCompleted = false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _segBtn(
              cs,
              label: 'Đã hoàn thành',
              selected: _showCompleted,
              onTap: () => setState(() => _showCompleted = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segBtn(ColorScheme cs, {required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.15) : cs.surfaceVariant,
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: selected ? cs.primary : cs.onSurface, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _taskTile(Task t, bool use24h, ColorScheme cs) {
    String fmtTime(String s) {
      if (s.trim().isEmpty) return '';
      try {
        final p = s.split(':');
        final tod = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        return MaterialLocalizations.of(context).formatTimeOfDay(tod, alwaysUse24HourFormat: use24h);
      } catch (_) {
        return s;
      }
    }

    final stripe = t.priority == TaskPriority.high
        ? Colors.red
        : (t.priority == TaskPriority.medium ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: stripe, width: 3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // checkbox toggle nhanh
            GestureDetector(
              onTap: () async {
                if (t.id != null) {
                  await _dao.toggleCompleted(t.id!, !t.isCompleted);
                  _load();
                }
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: t.isCompleted ? cs.primary : Colors.transparent,
                  border: Border.all(color: t.isCompleted ? cs.primary : cs.outline, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: t.isCompleted ? Icon(Icons.check, size: 16, color: cs.onPrimary) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final updated = await showModalBottomSheet<Task>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EditTaskDialog(initial: t),
                  );
                  if (updated != null) {
                    await _dao.update(updated.copyWith(id: t.id));
                    _load();
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(fmtTime(t.time), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.label, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(t.category, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  final up = await showModalBottomSheet<Task>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EditTaskDialog(initial: t),
                  );
                  if (up != null) {
                    await _dao.update(up.copyWith(id: t.id));
                    _load();
                  }
                } else if (v == 'delete') {
                  if (t.id != null) {
                    await _dao.delete(t.id!);
                    _load();
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xoá')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
