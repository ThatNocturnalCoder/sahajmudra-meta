import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState
    extends State<LevelSelectionScreen> {
  int? _selectedLevel;
  String _userName = '';

  static const _levels = [
    _LevelData(
      index: 0,
      title: 'Beginner',
      subtitle: 'I am new to sign language',
      description:
          'Start from A–Z basics with guided AI feedback. Perfect for complete beginners.',
      emoji: '🌱',
      color: Color(0xFF2E7D32),
    ),
    _LevelData(
      index: 1,
      title: 'Intermediate',
      subtitle: 'I know some signs already',
      description:
          'All 26 alphabets + numbers unlocked. Practice speed and accuracy.',
      emoji: '⚡',
      color: Color(0xFFE65100),
    ),
    _LevelData(
      index: 2,
      title: 'Expert',
      subtitle: 'I want to master ISL',
      description:
          'Full alphabet, greetings and phrases. Speed tests and challenges.',
      emoji: '🏆',
      color: Color(0xFF6A1B9A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
        () => _userName = prefs.getString('user_name') ?? 'Learner');
  }

  Future<void> _confirmLevel() async {
    if (_selectedLevel == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_level', _selectedLevel!);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            MainShell(level: _selectedLevel!),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.03),

                  // Logo
                  Image.asset(
                    'assets/images/sahajmudra.png',
                    width: 80,
                    height: 80,
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $_userName! 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose your learning path',
                              style: AppText.body.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.025),

                  // Level cards — all visible, no scroll
                  Expanded(
                    child: Column(
                      children: [
                        ..._levels.map((level) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10),
                                child: _LevelCard(
                                  data: level,
                                  selected:
                                      _selectedLevel == level.index,
                                  onTap: () => setState(() =>
                                      _selectedLevel = level.index),
                                ),
                              ),
                            )),

                        // Let's Go button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedLevel != null
                                ? _confirmLevel
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedLevel != null
                                  ? AppColors.primary
                                  : AppColors.divider,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            child: Text(
                              "Let's Go →",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selectedLevel != null
                                    ? Colors.white
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final _LevelData data;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? data.color
                : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            // Emoji icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(data.emoji,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        data.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: data.color,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle,
                            color: data.color, size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: AppText.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: AppText.bodySmall
                        .copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelData {
  final int index;
  final String title;
  final String subtitle;
  final String description;
  final String emoji;
  final Color color;

  const _LevelData({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
    required this.color,
  });
}