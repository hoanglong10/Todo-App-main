import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uptodo/data/settings_service.dart';
import 'package:uptodo/providers/auth_provider.dart';
import 'package:uptodo/ui/auth/start_screen.dart';

import '../../data/settings_controller.dart'; // settingsController

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _palette = [
    Color(0xFF8E7CFF), Color(0xFF56CCF2), Color(0xFF2D9CDB),
    Color(0xFF6FCF97), Color(0xFFF2C94C), Color(0xFFF2994A),
    Color(0xFFEB5757), Color(0xFFBB6BD9), Color(0xFF27AE60),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (_, __) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final s = settingsController.state;

        return Scaffold(
          // KHÔNG set backgroundColor cứng → dùng màu theo theme
          appBar: AppBar(title: const Text('Cài đặt')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              // User Info Section
              _buildUserInfoSection(context),

              _section(context, 'Giao diện'),
              // Màu nhấn
              _tile(
                context,
                leading: Icons.color_lens,
                title: 'Màu nhấn',
                trailing: Wrap(
                  spacing: 8,
                  children: _palette.map((c) {
                    final sel = s.accentColor == c.value;
                    return GestureDetector(
                      onTap: () => settingsController.update((st) => st.accentColor = c.value),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? cs.onSurface : cs.outlineVariant,
                            width: sel ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Chủ đề
              _dropdown<ThemeChoice>(
                context,
                icon: Icons.brightness_6,
                title: 'Chủ đề',
                value: s.theme,
                items: const {
                  ThemeChoice.system: 'Theo hệ thống',
                  ThemeChoice.light : 'Sáng',
                  ThemeChoice.dark  : 'Tối',
                },
                onChanged: (v) => settingsController.update((st) => st.theme = v),
              ),

              _section(context, 'Hiển thị & sắp xếp'),
              _dropdown<DefaultSort>(
                context,
                icon: Icons.sort,
                title: 'Sắp xếp mặc định',
                value: s.defaultSort,
                items: const {
                  DefaultSort.newest  : 'Mới nhất',
                  DefaultSort.priority: 'Ưu tiên',
                },
                onChanged: (v) => settingsController.update((st) => st.defaultSort = v),
              ),
              _switch(
                context,
                icon: Icons.done_all,
                title: 'Hiện việc đã hoàn thành',
                value: s.showCompleted,
                onChanged: (v) => settingsController.update((st) => st.showCompleted = v),
              ),
              _switch(
                context,
                icon: Icons.schedule,
                title: 'Định dạng 24 giờ',
                value: s.use24hTime,
                onChanged: (v) => settingsController.update((st) => st.use24hTime = v),
              ),

              // Account Section
              _section(context, 'Tài khoản'),
              _buildLogoutButton(context),

              _section(context, 'Giới thiệu'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info, color: cs.onSurface),
                title: Text('UpTodo (bản demo)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    )),
                subtitle: Text('v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build User Info Section
  Widget _buildUserInfoSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        if (user == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primary,
                child: Text(
                  (user.displayName?.isNotEmpty == true
                      ? user.displayName![0]
                      : user.email![0]).toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email?.split('@').first ?? 'User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Provider badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: user.providerData.map((provider) {
                  IconData icon;
                  Color color;
                  switch (provider.providerId) {
                    case 'google.com':
                      icon = Icons.g_mobiledata;
                      color = Colors.red;
                      break;
                    case 'password':
                      icon = Icons.email;
                      color = cs.primary;
                      break;
                    default:
                      icon = Icons.account_circle;
                      color = cs.onSurfaceVariant;
                  }
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build Logout Button
  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text(
            'Đăng xuất',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: authProvider.isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          onTap: authProvider.isLoading ? null : () => _showLogoutDialog(context),
        );
      },
    );
  }

  // Show Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Đăng xuất',
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          backgroundColor: cs.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _handleLogout(context),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Handle Logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Close dialog first
      Navigator.of(context).pop();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang đăng xuất...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Perform logout
      await authProvider.signOut();

      // Clear user settings (optional - keeps settings for when user logs back in)
      // await AppSettings.clearUserSettings();

      // Navigate to start screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StartScreen()),
              (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== Helpers (theo theme) =====
  Widget _section(BuildContext context, String t) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        t,
        style: theme.textTheme.titleSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context, {
        required IconData leading,
        required String title,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(leading, color: cs.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _switch(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: cs.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      activeColor: cs.primary,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _dropdown<T>(
      BuildContext context, {
        required IconData icon,
        required String title,
        required T value,
        required Map<T, String> items,
        required ValueChanged<T> onChanged,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: cs.surface,
          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}