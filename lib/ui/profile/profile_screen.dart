import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uptodo/models/profile.dart';
import 'package:uptodo/data/profile_dao.dart';
import 'package:uptodo/data/task_dao.dart';
import 'package:uptodo/models/task.dart';
import 'package:uptodo/ui/theme/app_theme.dart';
import 'package:uptodo/helpers/image_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileDao _profileDao = ProfileDao();
  final TaskDao _taskDao = TaskDao();

  Profile? _profile;
  List<Task> _tasks = [];
  bool _loading = true;

  // Thống kê
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _todayTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final profile = await _profileDao.getProfile();
      final tasks = await _taskDao.getAll();

      // Tính toán thống kê
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final completed = tasks.where((t) => t.isCompleted).length;
      final todayCount = tasks.where((t) {
        final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
        return taskDate.isAtSameMomentAs(today);
      }).length;

      if (mounted) {
        setState(() {
          _profile = profile;
          _tasks = tasks;
          _totalTasks = tasks.length;
          _completedTasks = completed;
          _pendingTasks = tasks.length - completed;
          _todayTasks = todayCount;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(context)),
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              _buildHeader(cs),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileCard(cs),
                      const SizedBox(height: 16),
                      _buildStatsGrid(cs),
                      const SizedBox(height: 16),
                      _buildSettingsSection(cs),
                      const SizedBox(height: 100), // để tránh bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false, // Ẩn nút back
      title: Text(
        'Hồ Sơ',
        style: TextStyle(
          color: cs.onBackground,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.edit, color: cs.onBackground),
          onPressed: _showEditProfileDialog,
        ),
      ],
    );
  }

  Widget _buildProfileCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(cs),
          const SizedBox(height: 16),
          Text(
            _profile?.name ?? 'Chưa có tên',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _profile?.email ?? 'Chưa có email',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _profile!.bio!,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    return GestureDetector(
      onTap: _changeAvatar,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _profile?.avatarPath != null
                  ? FutureBuilder<bool>(
                future: ImageHelper.imageExists(_profile!.avatarPath),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Image.file(
                      File(_profile!.avatarPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(cs),
                    );
                  }
                  return _defaultAvatar(cs);
                },
              )
                  : _defaultAvatar(cs),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: cs.onPrimary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(ColorScheme cs) {
    return Container(
      color: cs.primary.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: cs.primary,
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống Kê Công Việc',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                cs,
                Icons.task_alt,
                'Tổng số',
                _totalTasks.toString(),
                Colors.blue,
              ),
              _buildStatCard(
                cs,
                Icons.check_circle,
                'Hoàn thành',
                _completedTasks.toString(),
                Colors.green,
              ),
              _buildStatCard(
                cs,
                Icons.pending,
                'Đang làm',
                _pendingTasks.toString(),
                Colors.orange,
              ),
              _buildStatCard(
                cs,
                Icons.today,
                'Hôm nay',
                _todayTasks.toString(),
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(cs),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      ColorScheme cs,
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs) {
    final progress = _totalTasks > 0 ? _completedTasks / _totalTasks : 0.0;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ hoàn thành',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành Động',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            cs,
            Icons.edit,
            'Chỉnh sửa hồ sơ',
            'Cập nhật thông tin cá nhân',
                () => _showEditProfileDialog(),
          ),
          _buildActionTile(
            cs,
            Icons.camera_alt,
            'Đổi ảnh đại diện',
            'Chọn ảnh mới từ thư viện',
                () => _changeAvatar(),
          ),
          _buildActionTile(
            cs,
            Icons.refresh,
            'Làm mới dữ liệu',
            'Cập nhật thống kê mới nhất',
                () => _loadData(),
          ),
          if (_profile?.avatarPath != null)
            _buildActionTile(
              cs,
              Icons.delete_outline,
              'Xóa ảnh đại diện',
              'Loại bỏ ảnh hiện tại',
                  () => _deleteAvatar(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      ColorScheme cs,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final result = await showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileDialog(profile: _profile),
    );

    if (result != null) {
      try {
        if (_profile == null) {
          await _profileDao.insert(result);
        } else {
          await _profileDao.update(result.copyWith(id: _profile!.id));
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cập nhật hồ sơ thành công!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeAvatar() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chọn ảnh đại diện',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Sử dụng camera để chụp ảnh mới'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn ảnh có sẵn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang xử lý ảnh...')),
          );
        }

        // Sử dụng ImageHelper để pick và save ảnh
        final newPath = await ImageHelper.pickAndSaveImage(source: result);

        if (newPath != null) {
          // Xóa ảnh cũ nếu có
          if (_profile?.avatarPath != null) {
            await ImageHelper.deleteImageFile(_profile!.avatarPath);
          }

          // Cập nhật profile
          final updatedProfile = (_profile ?? Profile(name: '', email: ''))
              .copyWith(avatarPath: newPath);

          if (_profile == null) {
            await _profileDao.insert(updatedProfile);
          } else {
            await _profileDao.update(updatedProfile.copyWith(id: _profile!.id));
          }

          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cập nhật ảnh đại diện thành công!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật ảnh: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh đại diện'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh đại diện hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xóa',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _profile != null) {
      try {
        // Xóa file ảnh
        if (_profile!.avatarPath != null) {
          await ImageHelper.deleteImageFile(_profile!.avatarPath);
        }

        // Cập nhật profile
        final updatedProfile = _profile!.copyWith(avatarPath: null);
        await _profileDao.update(updatedProfile);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã xóa ảnh đại diện'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa ảnh: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class EditProfileDialog extends StatefulWidget {
  final Profile? profile;

  const EditProfileDialog({super.key, this.profile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _emailController = TextEditingController(text: widget.profile?.email ?? '');
    _bioController = TextEditingController(text: widget.profile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chỉnh sửa hồ sơ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Giới thiệu (tùy chọn)',
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                    hintText: 'Viết vài dòng về bản thân...',
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final profile = Profile(
        id: widget.profile?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        avatarPath: widget.profile?.avatarPath,
      );
      Navigator.pop(context, profile);
    }
  }
}