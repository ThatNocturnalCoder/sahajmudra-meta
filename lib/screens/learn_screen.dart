import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/isl_data.dart';
import '../services/progress_service.dart';
import 'tutor_screen.dart';

class LearnScreen extends StatefulWidget {
  final int level;
  const LearnScreen({super.key, required this.level});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Map<String, int> _scores = {};

  static const _unlockedLetters = [
    ['A','B','C','D','E','F','G','H','I','J'],
    ['A','B','C','D','E','F','G','H','I','J','K','L','M',
     'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
    ['A','B','C','D','E','F','G','H','I','J','K','L','M',
     'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  ];

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final p = await ProgressService.load();
    if (mounted) setState(() => _scores = p.letterScores);
  }

  List<String> get _letters => _unlockedLetters[widget.level];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ISL Alphabet',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Tap a letter to learn and practise',
                          style: AppText.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _letters.length,
                    itemBuilder: (_, i) {
                      final letter = _letters[i];
                      final score = _scores[letter] ?? 0;
                      final mastered = score >= 80;
                      final attempted = score > 0;
                      final bgColor = mastered
                          ? AppColors.success.withValues(alpha: 0.1)
                          : attempted
                              ? AppColors.accent.withValues(alpha: 0.08)
                              : AppColors.surface;
                      final borderColor = mastered
                          ? AppColors.success.withValues(alpha: 0.5)
                          : attempted
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.divider;
                      final textColor = mastered
                          ? AppColors.success
                          : attempted
                              ? AppColors.accent
                              : AppColors.textPrimary;

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    TutorScreen(letter: letter)),
                          );
                          _loadScores();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(letter,
                                  style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: textColor)),
                              const SizedBox(height: 6),
                              if (mastered)
                                Icon(Icons.check_circle,
                                    color: AppColors.success,
                                    size: 16)
                              else if (attempted)
                                Text('$score%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent))
                              else
                                Icon(Icons.play_circle_outline,
                                    color: AppColors.textHint,
                                    size: 16),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius:
                                      BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: score / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: mastered
                                          ? AppColors.success
                                          : AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}