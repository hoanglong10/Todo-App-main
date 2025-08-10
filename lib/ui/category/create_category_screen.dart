import 'package:flutter/material.dart';
import '../../data/category_dao.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _nameCtrl = TextEditingController();
  IconData? _pickedIcon;
  Color _pickedColor = const Color(0xFF8E7CFF);
  final _dao = CategoryDao();

  final List<Color> _palette = const [
    Color(0xFF8E7CFF), Color(0xFF56CCF2), Color(0xFF2D9CDB),
    Color(0xFF6FCF97), Color(0xFFF2C94C), Color(0xFFF2994A),
    Color(0xFFEB5757), Color(0xFFBB6BD9), Color(0xFF828282),
    Color(0xFF27AE60),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<IconData>(
      context: context,
      builder: (_) => const _IconPickerDialog(),
    );
    if (result != null) setState(() => _pickedIcon = result);
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _pickedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên và chọn icon nhé')),
      );
      return;
    }

    await _dao.insert(
      CategoryEntity(
        name: name,
        iconCodePoint: _pickedIcon!.codePoint,
        bgColor: _pickedColor.value,
        iconColor: Colors.white.value,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tạo danh mục mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên danh mục', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Gia đình',
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                filled: true,
                fillColor: cs.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Icon danh mục', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _pickedColor.withOpacity(.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Icon(_pickedIcon ?? Icons.category_outlined, color: _pickedColor),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: _pickIcon, child: const Text('Chọn icon từ thư viện')),
              ],
            ),

            const SizedBox(height: 20),
            Text('Màu danh mục', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _palette.map((c) {
                final selected = c.value == _pickedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _pickedColor = c),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: Border.all(color: selected ? cs.onSurface : Colors.transparent, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.outline),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tạo Danh Mục'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog();

  static const _icons = <IconData>[
    Icons.work, Icons.school, Icons.sports_soccer, Icons.palette, Icons.shopping_bag,
    Icons.home, Icons.favorite, Icons.movie, Icons.music_note, Icons.fastfood,
    Icons.pets, Icons.directions_car, Icons.computer, Icons.phone_iphone,
    Icons.flight_takeoff, Icons.book, Icons.camera_alt, Icons.spa,
    Icons.health_and_safety, Icons.fitness_center,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surface,
      title: const Text('Chọn icon'),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemCount: _icons.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => Navigator.pop(context, _icons[i]),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(_icons[i], color: cs.onSurface),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}
