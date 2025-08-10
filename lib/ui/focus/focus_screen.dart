import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uptodo/ui/theme/app_theme.dart';

enum TimerKind { stopwatch, countdown }

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // ====== state ======
  TimerKind _kind = TimerKind.stopwatch;
  bool _running = false;

  DateTime? _startAt; // để tránh lệch khi app vào background
  Duration _elapsed = Duration.zero;

  // countdown
  Duration _target = const Duration(minutes: 25);

  Timer? _ticker;

  // Lịch sử trong phiên (không lưu DB)
  final List<_Session> _history = [];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ------ actions ------
  void _start() {
    if (_running) return;
    _startAt = DateTime.now().subtract(_elapsed); // tiếp tục từ chỗ dừng
    _running = true;
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    setState(() {});
  }

  void _pause() {
    if (!_running) return;
    _onTick(force: true);
    _running = false;
    setState(() {});
  }

  void _resetAndSave() {
    if (_elapsed.inSeconds > 0) {
      _history.insert(
        0,
        _Session(
          kind: _kind,
          startAt: _startAt ?? DateTime.now().subtract(_elapsed),
          endAt: DateTime.now(),
          duration: _kind == TimerKind.countdown ? _target : _elapsed,
        ),
      );
    }
    _running = false;
    _startAt = null;
    _elapsed = Duration.zero;
    setState(() {});
  }

  void _onTick({bool force = false}) {
    if (!_running && !force) return;
    if (_startAt == null) return;

    final now = DateTime.now();
    final newElapsed = now.difference(_startAt!);
    _elapsed = newElapsed.isNegative ? Duration.zero : newElapsed;

    if (_kind == TimerKind.countdown && _elapsed >= _target) {
      // hoàn tất: tự lưu rồi reset
      _history.insert(
        0,
        _Session(
          kind: _kind,
          startAt: _startAt!,
          endAt: now,
          duration: _target,
        ),
      );
      _running = false;
      _startAt = null;
      _elapsed = Duration.zero;
    }
    if (mounted) setState(() {});
  }

  // ------ helpers ------
  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  // SDK cũ chưa có Duration.clamp
  Duration _clampDuration(Duration v, Duration min, Duration max) {
    if (v.compareTo(min) < 0) return min;
    if (v.compareTo(max) > 0) return max;
    return v;
  }

  double _progress() {
    if (_kind == TimerKind.stopwatch) return 0;
    final total = _target.inSeconds;
    if (total == 0) return 0;
    final left = (_target - _elapsed).inSeconds.clamp(0, total);
    return 1 - left / total;
  }

  Future<void> _pickCountdown() async {
    final picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Duration temp = _target;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Chọn thời lượng', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms,
                  initialTimerDuration: _target,
                  onTimerDurationChanged: (d) => temp = d,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('Chọn'))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _target = picked;
        if (_running && _kind == TimerKind.countdown) {
          _startAt = DateTime.now().subtract(_elapsed);
        }
      });
    }
  }

  Duration get _displayDuration {
    if (_kind == TimerKind.stopwatch) return _elapsed;
    final v = _target - _elapsed;
    return _clampDuration(v, Duration.zero, _target);
  }

  Duration get _todayTotal {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    var sum = Duration.zero;
    for (final s in _history) {
      if (s.endAt.isAfter(start) && s.endAt.isBefore(end)) sum += s.duration;
    }
    return sum;
  }

  // ------ UI ------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Bộ đếm giờ',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: cs.onSurface),
        actions: [
          IconButton(
            tooltip: 'Xoá lịch sử',
            icon: const Icon(Icons.delete_outline),
            color: cs.onSurface,
            onPressed: _history.isEmpty ? null : () => setState(() => _history.clear()),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(context)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ---- chọn chế độ ----
            Row(
              children: [
                Expanded(
                  child: _seg(
                    cs,
                    label: 'Bấm giờ',
                    selected: _kind == TimerKind.stopwatch,
                    onTap: () {
                      if (_running) _pause();
                      setState(() {
                        _kind = TimerKind.stopwatch;
                        _elapsed = Duration.zero;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _seg(
                    cs,
                    label: 'Đếm ngược',
                    selected: _kind == TimerKind.countdown,
                    onTap: () {
                      if (_running) _pause();
                      setState(() {
                        _kind = TimerKind.countdown;
                        _elapsed = Duration.zero;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- đồng hồ lớn ----
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _kind == TimerKind.stopwatch ? null : _progress(),
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmt(_displayDuration),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
                        ),
                        if (_kind == TimerKind.countdown) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _running ? null : _pickCountdown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Mục tiêu: ${_fmt(_target)}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- nút điều khiển ----
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _running ? _pause : _start,
                    child: Text(_running ? 'Tạm dừng' : 'Bắt đầu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_elapsed.inSeconds > 0 || _running) ? _resetAndSave : null,
                    child: const Text('Đặt lại & lưu'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ---- tổng hôm nay ----
            Row(
              children: [
                Icon(Icons.analytics_outlined, size: 18, color: cs.onSurface),
                const SizedBox(width: 8),
                Text('Tổng hôm nay: ${_fmt(_todayTotal)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface)),
              ],
            ),

            const SizedBox(height: 12),

            // ---- lịch sử ----
            Text('Lịch sử (chỉ trong phiên)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              Text('Chưa có phiên nào', style: TextStyle(color: cs.onSurfaceVariant))
            else
              ..._history.map((s) => _historyTile(s, cs)),
          ],
        ),
      ),

      // ❌ Không còn FloatingActionButton
    );
  }

  Widget _historyTile(_Session s, ColorScheme cs) {
    final icon = s.kind == TimerKind.stopwatch ? Icons.av_timer : Icons.timer_outlined;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: const Text('Phiên tập trung', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_fmt(s.duration)} • ${_ddMMyyyyHHmm(s.startAt)} → ${_ddMMyyyyHHmm(s.endAt)}',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _seg(
      ColorScheme cs, {
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.15) : cs.surfaceVariant,
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }

  String _ddMMyyyyHHmm(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _Session {
  final TimerKind kind;
  final DateTime startAt;
  final DateTime endAt;
  final Duration duration;

  _Session({
    required this.kind,
    required this.startAt,
    required this.endAt,
    required this.duration,
  });
}
