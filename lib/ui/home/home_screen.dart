import 'package:flutter/material.dart';
import 'package:uptodo/models/task.dart';
import 'package:uptodo/data/task_dao.dart';

import 'package:uptodo/ui/home/add_task_dialog.dart';
import 'package:uptodo/ui/home/widgets/edit_task_dialog.dart';

import 'package:uptodo/ui/category/category_screen.dart';
import 'package:uptodo/ui/settings/settings_screen.dart';
import 'package:uptodo/ui/theme/app_theme.dart';

import 'package:uptodo/ui/calendar/calendar_screen.dart';
import 'package:uptodo/ui/focus/focus_screen.dart';
import 'package:uptodo/ui/profile/profile_screen.dart';

import 'package:uptodo/data/settings_controller.dart';

import '../../data/settings_service.dart';

enum SortMode { priority, newest }
enum ViewMode { both, active, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // DB
  final TaskDao _taskDao = TaskDao();
  List<Task> _tasks = [];
  bool _loading = true;

  // Filter UI
  SortMode _sortMode = SortMode.newest;
  ViewMode _viewMode = ViewMode.both;

  // KEY cho Calendar
  final _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _applyDefaultsFromSettings();
  }

  Future<void> _applyDefaultsFromSettings() async {
    final s = settingsController.state;
    setState(() {
      _sortMode =
      s.defaultSort == DefaultSort.priority ? SortMode.priority : SortMode.newest;
      _viewMode = s.showCompleted ? ViewMode.both : ViewMode.active;
    });
  }

  Future<void> _loadTasks() async {
    final data = await _taskDao.getAll();
    if (!mounted) return;
    setState(() {
      _tasks = data;
      _loading = false;
    });
  }

  // ===== Helpers cho Drawer =====
  void _goToTab(int index) {
    Navigator.pop(context); // đóng drawer
    setState(() => _selectedIndex = index);
    if (index == 1) _calendarKey.currentState?.reload(); // nếu sang Lịch thì refresh
  }

  Future<void> _deleteCompleted() async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Xoá tất cả đã hoàn thành', style: TextStyle(color: cs.onSurface)),
        content: Text('Bạn chắc chắn muốn xoá mọi công việc đã hoàn thành?',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Xoá', style: TextStyle(color: cs.error))),
        ],
      ),
    );

    if (ok == true) {
      final done = _tasks.where((t) => t.isCompleted && t.id != null).toList();
      for (final t in done) {
        await _taskDao.delete(t.id!);
      }
      setState(() => _tasks.removeWhere((t) => t.isCompleted));
      _calendarKey.currentState?.reload(); // cập nhật badge Lịch
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (_, __) {
        final cs = Theme.of(context).colorScheme;
        final accent = cs.primary;

        return Scaffold(
          drawer: _buildDrawer(),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _homeTab(),
              CalendarScreen(key: _calendarKey),
              const SizedBox.shrink(), // slot cho nút +
              const FocusScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(accent),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            backgroundColor: accent,
            child: Icon(Icons.add, color: cs.onPrimary, size: 30),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  // ================== HOME TAB ==================
  Widget _homeTab() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = cs.primary;
    final use24h = settingsController.state.use24hTime;
    final showCompletedSetting = settingsController.state.showCompleted;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(context)),
      child: Column(
        children: [
          _buildHeader(accent),
          _buildControlsRow(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? _buildEmptyState(accent)
                : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _buildTaskList(use24h, showCompletedSetting),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Header + Drawer =====
  Widget _buildHeader(Color accent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 10),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
              icon: Icon(Icons.menu, color: cs.onBackground, size: 24),
            ),
          ),
          const Spacer(),
          Text(
            'Trang Chủ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cs.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.person, color: cs.onPrimary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final width = MediaQuery.of(context).size.width * .86;

    bool showCompletedNow = _viewMode != ViewMode.active;

    return Drawer(
      width: width,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 18,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _drawerHeader(context, cs, accent),
                const SizedBox(height: 8),

                _drawerItem(
                  cs: cs,
                  icon: Icons.category_outlined,
                  text: 'Danh mục',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CategoryScreen()));
                  },
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.settings_outlined,
                  text: 'Cài đặt',
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.event_note_outlined,
                  text: 'Lịch',
                  onTap: () => _goToTab(1),
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.timer_outlined,
                  text: 'Tập trung',
                  onTap: () => _goToTab(3),
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.person_outline,
                  text: 'Hồ sơ',
                  onTap: () => _goToTab(4),
                ),

                // Công tắc hiện việc đã hoàn thành
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.visibility_outlined, color: cs.onSurface),
                  ),
                  title: Text('Hiện việc đã hoàn thành',
                      style:
                      TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
                  trailing: Switch(
                    value: showCompletedNow,
                    onChanged: (v) {
                      setState(() {
                        _viewMode = v ? ViewMode.both : ViewMode.active;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.cleaning_services_outlined,
                  text: 'Xoá tất cả đã hoàn thành',
                  onTap: _deleteCompleted,
                ),

                _drawerItem(
                  cs: cs,
                  icon: Icons.close,
                  text: 'Đóng',
                  onTap: () => Navigator.pop(context),
                ),

                const Spacer(),
                const Divider(height: 1),
                _drawerFooter(cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerHeader(BuildContext context, ColorScheme cs, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(.16), accent.withOpacity(.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent,
            child: Icon(Icons.checklist_rounded, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UpTodo',
                    style: TextStyle(
                        color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Tổ chức công việc',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required ColorScheme cs,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: cs.onSurface),
      ),
      title: Text(text,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _drawerFooter(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('v1.0.0', style: TextStyle(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text('© 2025', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ===== Controls row =====
  Widget _buildControlsRow() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text('Hiển thị:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(width: 8),
          _dropdownShell(
            DropdownButton<ViewMode>(
              value: _viewMode,
              dropdownColor: cs.surface,
              style: TextStyle(color: cs.onSurface),
              items: const [
                DropdownMenuItem(value: ViewMode.both, child: Text('Tất cả')),
                DropdownMenuItem(value: ViewMode.active, child: Text('Đang làm')),
                DropdownMenuItem(value: ViewMode.completed, child: Text('Hoàn thành')),
              ],
              onChanged: (v) => setState(() => _viewMode = v ?? _viewMode),
              underline: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 16),
          Text('Sắp xếp:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(width: 8),
          _dropdownShell(
            DropdownButton<SortMode>(
              value: _sortMode,
              dropdownColor: cs.surface,
              style: TextStyle(color: cs.onSurface),
              items: const [
                DropdownMenuItem(value: SortMode.priority, child: Text('Ưu tiên')),
                DropdownMenuItem(value: SortMode.newest, child: Text('Mới nhất')),
              ],
              onChanged: (v) => setState(() => _sortMode = v ?? _sortMode),
              underline: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownShell(Widget child) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: child),
    );
  }

  // ===== Empty =====
  Widget _buildEmptyState(Color accent) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(Icons.task_alt, size: 100, color: accent),
          ),
          const SizedBox(height: 40),
          Text('Bạn muốn làm gì hôm nay?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: cs.onBackground,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 16),
          Text('Nhấn + để thêm công việc',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ===== List =====
  Widget _buildTaskList(bool use24h, bool showCompletedSetting) {
    final active = _tasks.where((t) => !t.isCompleted).toList();
    final done = _tasks.where((t) => t.isCompleted).toList();

    final activeSorted = _sortedCopy(active);
    final doneSorted = _sortedCopy(done);

    final sortLbl = _sortMode == SortMode.priority ? 'Ưu tiên' : 'Mới nhất';
    final showDone =
        _viewMode == ViewMode.completed || (_viewMode == ViewMode.both && showCompletedSetting);

    List<Widget> children = [];

    if (_viewMode == ViewMode.both || _viewMode == ViewMode.active) {
      if (activeSorted.isNotEmpty) {
        children.add(_sectionHeader('Đang làm · $sortLbl'));
        children.addAll(List.generate(activeSorted.length, (i) {
          final index = _tasks.indexOf(activeSorted[i]);
          return _buildTaskItem(index, use24h);
        }));
      }
    }
    if (showDone) {
      if (doneSorted.isNotEmpty) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 20));
        children.add(_sectionHeader('Hoàn thành · $sortLbl'));
        children.addAll(List.generate(doneSorted.length, (i) {
          final index = _tasks.indexOf(doneSorted[i]);
          return _buildTaskItem(index, use24h);
        }));
      }
    }
    if (children.isEmpty) {
      children = [
        const SizedBox(height: 24),
        Center(
          child: Text('Không có công việc',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(children: [...children, const SizedBox(height: 80)]),
    );
  }

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: cs.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  // ===== Item =====
  Widget _buildTaskItem(int idx, bool use24h) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final task = _tasks[idx];
    final stripe = _getPriorityColor(task.priority);
    final bg = task.isCompleted ? cs.primary.withOpacity(.14) : cs.surface;

    return Dismissible(
      key: ValueKey('task_${task.id ?? idx}_${task.title}'),
      background: _swipeBg(alignLeft: true),
      secondaryBackground: _swipeBg(alignLeft: false),
      confirmDismiss: (_) async => await _confirmDelete(idx),
      child: InkWell(
        onTap: () => _viewTask(idx),
        onLongPress: () => _showTaskMenu(idx),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: stripe, width: 3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // checkbox
              GestureDetector(
                onTap: () async {
                  final t = _tasks[idx];
                  final newVal = !t.isCompleted;
                  if (t.id != null) await _taskDao.toggleCompleted(t.id!, newVal);
                  setState(() => _tasks[idx] = t.copyWith(isCompleted: newVal));
                  _calendarKey.currentState?.reload(date: t.date); // cập nhật Lịch
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? cs.primary : Colors.transparent,
                    border:
                    Border.all(color: task.isCompleted ? cs.primary : cs.outline, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                  task.isCompleted ? Icon(Icons.check, size: 16, color: cs.onPrimary) : null,
                ),
              ),
              const SizedBox(width: 12),

              // content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        _priorityPill(task.priority),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (task.description).trim().isEmpty
                          ? 'Không có mô tả'
                          : task.description,
                      style:
                      theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _categoryChipReadonly(task.category),
                        const SizedBox(width: 8),
                        _dateChip(task.date),
                        const SizedBox(width: 8),
                        _timeChip(task.time, use24h),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Xem chi tiết ======
  Future<void> _viewTask(int index) async {
    final cs = Theme.of(context).colorScheme;
    final use24h = settingsController.state.use24hTime;
    final t = _tasks[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
            EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: t.isCompleted ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (t.description.trim().isNotEmpty)
                    Text(t.description, style: TextStyle(color: cs.onSurfaceVariant)),
                  if (t.description.trim().isNotEmpty) const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _categoryChipReadonly(t.category),
                      _dateChip(t.date),
                      _timeChip(t.time, use24h),
                      _priorityPill(t.priority),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Sửa'),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _editTask(index);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Đóng'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // chips + helpers
  String _formatTime(String time, bool use24h) {
    try {
      final parts = time.split(':');
      final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(tod, alwaysUse24HourFormat: use24h);
    } catch (_) {
      return time;
    }
  }

  Widget _timeChip(String time, bool use24h) {
    if (time.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final text = _formatTime(time, use24h);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _weekdayVN(int wd) {
    switch (wd) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  Widget _dateChip(DateTime d) {
    final cs = Theme.of(context).colorScheme;
    final label =
        '${_weekdayVN(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _priorityPill(TaskPriority p) {
    final c = _getPriorityColor(p);
    final label =
    switch (p) { TaskPriority.high => 'Cao', TaskPriority.medium => 'TrB', TaskPriority.low => 'Thấp' };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
      BoxDecoration(color: c.withOpacity(.18), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _categoryChipReadonly(String name) {
    final color = _getCategoryColor(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.9)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.label, size: 14, color: color),
        const SizedBox(width: 4),
        Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _categoryChip(String name, {VoidCallback? onTap}) {
    final color = _getCategoryColor(name);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label, size: 14, color: color),
            const SizedBox(width: 4),
            Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg({required bool alignLeft}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(12)),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(Icons.delete, color: cs.onError),
    );
  }

  // ===== Actions =====
  Future<void> _showAddTaskDialog() async {
    final task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskDialog(),
    );
    if (task != null) {
      final id = await _taskDao.insert(task);
      setState(() => _tasks.insert(0, task.copyWith(id: id)));
      _calendarKey.currentState?.reload(date: task.date); // update lịch
    }
  }

  Future<void> _editTask(int index) async {
    final updated = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTaskDialog(initial: _tasks[index]),
    );
    if (updated != null) {
      final withId = updated.copyWith(id: _tasks[index].id);
      await _taskDao.update(withId);
      setState(() => _tasks[index] = withId);
      _calendarKey.currentState?.reload(date: withId.date); // update lịch
    }
  }

  Future<void> _changeCategory(int index) async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          selectedCategory: _tasks[index].category,
          onCategorySelected: (_) {},
        ),
      ),
    );
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      final t = _tasks[index].copyWith(category: name);
      if (t.id != null) await _taskDao.update(t);
      setState(() => _tasks[index] = t);
      _calendarKey.currentState?.reload(date: t.date);
    }
  }

  Future<bool> _confirmDelete(int index) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Xoá công việc', style: TextStyle(color: cs.onSurface)),
        content: Text('Bạn có chắc muốn xoá "${_tasks[index].title}"?',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Xoá', style: TextStyle(color: cs.error))),
        ],
      ),
    );
    if (ok == true) {
      final id = _tasks[index].id;
      final date = _tasks[index].date;
      if (id != null) await _taskDao.delete(id);
      setState(() => _tasks.removeAt(index));
      _calendarKey.currentState?.reload(date: date);
    }
    return ok ?? false;
  }

  void _showTaskMenu(int index) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: cs.onSurfaceVariant),
              title: Text('Sửa', style: TextStyle(color: cs.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _editTask(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: cs.error),
              title: Text('Xoá', style: TextStyle(color: cs.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== Sort helpers =====
  int _priorityRank(TaskPriority p) =>
      p == TaskPriority.high ? 0 : (p == TaskPriority.medium ? 1 : 2);

  DateTime _comparableDate(Task t) {
    try {
      final parts = (t.time).split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateTime(t.date.year, t.date.month, t.date.day, h, m);
    } catch (_) {
      return t.date;
    }
  }

  List<Task> _sortedCopy(List<Task> list) {
    final copy = [...list];
    copy.sort((a, b) {
      if (_sortMode == SortMode.priority) {
        final pa = _priorityRank(a.priority);
        final pb = _priorityRank(b.priority);
        if (pa != pb) return pa.compareTo(pb);
        final tByTime = _comparableDate(b).compareTo(_comparableDate(a));
        if (tByTime != 0) return tByTime;
        final ida = a.id ?? -1, idb = b.id ?? -1;
        return idb.compareTo(ida);
      } else {
        final tByTime = _comparableDate(b).compareTo(_comparableDate(a));
        if (tByTime != 0) return tByTime;
        final ida = a.id ?? -1, idb = b.id ?? -1;
        return idb.compareTo(ida);
      }
    });
    return copy;
  }

  // ===== Colors =====
  Color _getCategoryColor(String category) {
    final cs = Theme.of(context).colorScheme;
    switch (category.toLowerCase()) {
      case 'đại học':
        return Colors.blue;
      case 'công việc':
        return Colors.orange;
      case 'cá nhân':
        return Colors.green;
      case 'mới':
        return cs.primary;
      default:
        return _colorFromName(category);
    }
  }

  Color _colorFromName(String name) {
    final n = name.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (n * 37) % 360;
    final hsl = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.60, 0.52);
    return hsl.toColor();
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Widget _buildBottomNavigationBar(Color accent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            _showAddTaskDialog();
            return;
          }
          setState(() => _selectedIndex = i);
          if (i == 1) _calendarKey.currentState?.reload(); // sang lịch thì refresh
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: accent,
        unselectedItemColor: cs.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Tập Trung'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ Sơ'),
        ],
      ),
    );
  }
}
