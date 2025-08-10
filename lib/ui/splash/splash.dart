import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uptodo/ui/onboarding/onboarding_page_view.dart';
import 'package:uptodo/ui/home/home_screen.dart';
import 'package:uptodo/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Hiển thị splash screen trong 1.2 giây
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Kiểm tra trạng thái đăng nhập
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      // User đã đăng nhập, chuyển đến HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // User chưa đăng nhập, chuyển đến OnboardingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(child: _BuildBodyPage()),
    );
  }
}

class _BuildBodyPage extends StatelessWidget {
  const _BuildBodyPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BuildIconSplash(),
          _BuildTextSplash(),
          SizedBox(height: 50),
          _BuildLoadingIndicator(),
        ],
      ),
    );
  }
}

class _BuildIconSplash extends StatelessWidget {
  const _BuildIconSplash();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/icon.png",
      width: 95,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}

class _BuildTextSplash extends StatelessWidget {
  const _BuildTextSplash();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        "UpTodo",
        style: TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: "Lato",
        ),
      ),
    );
  }
}

class _BuildLoadingIndicator extends StatelessWidget {
  const _BuildLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: Color(0xFF8875FF),
      strokeWidth: 2,
    );
  }
}