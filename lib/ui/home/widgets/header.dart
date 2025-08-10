import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const Spacer(),
          const Text(
            'Trang Chủ',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
