import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../pages/home_page.dart';

/// Màn hình splash — khởi tạo app rồi chuyển sang HomePage.
class SplashScreen extends StatefulWidget {
  /// Khởi tạo [SplashScreen].
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _initAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    // Firebase đã init trong main() — chỉ cần đợi animation
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Fade out rồi navigate
    await _controller.reverse();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.background,
                const Color(0xFF0A1628),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.cyanBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.videocam_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tên app
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: const Text(
                            'Pro Video Editor',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: const Text(
                            'Chỉnh sửa video chuyên nghiệp',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading indicator + version ở dưới
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'TDMU · 2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
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
}