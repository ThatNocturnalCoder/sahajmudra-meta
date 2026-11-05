import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool goToLogin;
  const WelcomeScreen({super.key, this.goToLogin = false});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _random = math.Random(42);

  static const List<String> _floatingItems = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    '🤟','✋','👋','🤙','👌','✌️','🤞','👍','☝️','🖐️','🤘','👏',
  ];

  late List<_FloatingItemData> _items;

  @override
  void initState() {
    super.initState();
    _items = List.generate(_floatingItems.length, (i) {
      if (widget.goToLogin) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(startOnLogin: true),
      ),
    );
  });
}
      return _FloatingItemData(
        text: _floatingItems[i],
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 13.0 + _random.nextDouble() * 10,
        opacity: 0.08 + _random.nextDouble() * 0.14,
        rotation: (_random.nextDouble() - 0.5) * 0.6,
      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scattered background items
          ..._items.map((item) => Positioned(
            left: item.x * size.width,
            top: item.y * size.height,
            child: Transform.rotate(
              angle: item.rotation,
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: item.size,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withOpacity(item.opacity),
                ),
              ),
            ),
          )),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SM',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, duration: 600.ms),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Welcome to\nSahajMudra',
                  textAlign: TextAlign.center,
                  style: AppText.heading1.copyWith(
                    height: 1.15,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms),

                const SizedBox(height: 16),

                Text(
                  'Learn Indian Sign Language.\nBridge the silent divide.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(icon: '🤟', label: '26 Signs'),
                    const SizedBox(width: 12),
                    _StatChip(icon: '🧠', label: 'AI Tutor'),
                    const SizedBox(width: 12),
                    _StatChip(icon: '🇮🇳', label: 'ISL'),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms),

                const Spacer(),

                // Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const AuthScreen(),
                            transitionsBuilder:
                                (_, animation, __, child) =>
                                    SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      child: const Text('Start Learning'),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, delay: 700.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(startOnLogin: true),
                      ),
                    );
                  },
                  child: Text(
                    'Already have an account? Log in',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 400.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingItemData {
  final String text;
  final double x, y, size, opacity, rotation;
  _FloatingItemData({
    required this.text,
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.rotation,
  });
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}