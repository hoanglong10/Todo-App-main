import 'package:flutter/material.dart';
import '../../data/category_dao.dart';
import 'create_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  const CategoryScreen({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _dao = CategoryDao();
  List<CategoryEntity> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _dao.getAll();
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  void _select(String name) {
    widget.onCategorySelected?.call(name);
    Navigator.pop(context, name);
  }

  Future<void> _addCategory() async {
    final createdName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCategoryScreen()),
    );
    if (!mounted) return;
    if (createdName != null) {
      await _load();
      _select(createdName);
    }
  }

  Future<void> _confirmDelete(CategoryEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá danh mục'),
        content: Text('Bạn có chắc muốn xoá “${e.name}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && e.id != null) {
      await _dao.delete(e.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xoá “${e.name}”')));
      _load();
    }
  }

  // ---- header chip đang chọn
  Widget _currentSelectedChip(ColorScheme cs) {
    if (widget.selectedCategory == null || _items.isEmpty) {
      return const SizedBox.shrink();
    }
    final e = _items.firstWhere(
          (x) => x.name == widget.selectedCategory,
      orElse: () => CategoryEntity(name: widget.selectedCategory!),
    );
    final icon = IconData(
      e.iconCodePoint ?? Icons.category_outlined.codePoint,
      fontFamily: 'MaterialIcons',
    );
    final color = Color(e.bgColor ?? cs.primary.value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('Đang chọn:', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(e.name, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('Nhấn giữ để xoá', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
        ? _EmptyState(onAdd: _addCategory)
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: .78,
        ),
        itemBuilder: (_, i) {
          final e = _items[i];
          final icon = IconData(
            e.iconCodePoint ?? Icons.category_outlined.codePoint,
            fontFamily: 'MaterialIcons',
          );
          final color = Color(e.bgColor ?? cs.primary.value);
          final selected = widget.selectedCategory == e.name;

          return _CategoryTile(
            name: e.name,
            icon: icon,
            color: color,
            isSelected: selected,
            onTap: () => _select(e.name),
            onLongPress: () => _confirmDelete(e),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: _GradientTitle(
          'Chọn danh mục',
          gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _currentSelectedChip(cs),
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Thêm danh mục', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTitle extends StatelessWidget {
  final String text;
  final Gradient gradient;
  const _GradientTitle(this.text, {required this.gradient});

  @override
  Widget build(BuildContext context) {
    // ShaderMask cần chữ màu trắng để blend ra gradient đẹp ở cả light/dark
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      child: const Text(
        'Chọn danh mục',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: .2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Chưa có danh mục nào',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tạo danh mục đầu tiên để sắp xếp công việc dễ hơn.',
                style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tạo danh mục'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card danh mục: viền gradient khi chọn + shadow + ✓
class _CategoryTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseBg = cs.surfaceVariant;

    final inner = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: baseBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    final border = isSelected
        ? Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    )
        : Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: isSelected ? 1.06 : 1.0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            border,
            Positioned.fill(child: inner),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
