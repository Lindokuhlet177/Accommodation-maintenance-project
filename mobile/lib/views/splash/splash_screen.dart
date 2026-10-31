import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Frames 1–3: gradient, then logo fades in, then go to Login or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return; // screen was closed while waiting

    // Ask the ViewModel, not Supabase, whether someone is logged in
    final isLoggedIn = context.read<AuthViewModel>().isLoggedIn;
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // free the animation when the screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // Frame 1: steel blue fading to white
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.white],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/logo_full.png',
                width: 280,
                // Until the logo is added (Step 1.3), show a text version
                errorBuilder: (_, __, ___) => const _FallbackLogo(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text logo used until logo_full.png is added.
class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home_repair_service, size: 96, color: AppColors.navy),
        SizedBox(height: 12),
        Text(
          'StudentStayFix',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Report • Track • Fix',
          style: TextStyle(color: AppColors.navy, fontSize: 16),
        ),
      ],
    );
  }
}