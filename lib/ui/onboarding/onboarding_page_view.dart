import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../auth/start_screen.dart';          // <— đổi sang StartScreen
import 'onboarding_child_page.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Quản Lý Công Việc',
      description: 'Tổ chức và theo dõi tất cả công việc của bạn một cách hiệu quả',
      icon: Icons.task_alt,
    ),
    OnboardingPage(
      title: 'Tạo Danh Mục',
      description: 'Phân loại công việc theo danh mục để dễ dàng quản lý',
      icon: Icons.category,
    ),
    OnboardingPage(
      title: 'Theo Dõi Tiến Độ',
      description: 'Xem tiến độ hoàn thành và thống kê hiệu suất của bạn',
      icon: Icons.analytics,
    ),
  ];

  void _goToStart() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StartScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToStart(); // hết trang -> Start
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460), Color(0xFF533483)],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // SKIP
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _goToStart, // skip -> Start
                      child: const Text('BỎ QUA', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),

              // PAGE VIEW
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => OnboardingChildPage(page: _pages[i]),
                ),
              ),

              // DOTS + BUTTONS
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: const WormEffect(
                        dotColor: Colors.grey,
                        activeDotColor: Colors.purple,
                        dotHeight: 8,
                        dotWidth: 8,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _currentPage > 0
                            ? TextButton(
                          onPressed: _previousPage,
                          child: const Text('QUAY LẠI', style: TextStyle(color: Colors.grey)),
                        )
                            : const SizedBox(width: 60),
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text(
                            _currentPage < _pages.length - 1 ? 'TIẾP THEO' : 'BẮT ĐẦU',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
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
}
