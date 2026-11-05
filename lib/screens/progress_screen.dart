import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../models/user_progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  UserProgress _progress = UserProgress.empty();

  static const _allLetters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
  ];
  static const _allNumbers = ['0','1','2','3','4','5','6','7','8','9'];

    @override
  void initState() {
    super.initState();
    _load();
    ProgressService.changes.addListener(_load);
  }

  @override
  void dispose() {
    ProgressService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final p = await ProgressService.load();
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final mastered = _allLetters
        .where((l) => (_progress.letterScores[l] ?? 0) >= 80)
        .length;
    final attempted = _allLetters
        .where((l) => (_progress.letterScores[l] ?? 0) > 0)
        .length;
    final pct = mastered / 26;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('My Progress',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _buildOverallCard(pct, mastered, attempted),
              const SizedBox(height: 16),
              _buildStreakCard(),
              const SizedBox(height: 20),
              const Text('Letter by Letter',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ..._allLetters.map((l) => _LetterProgressRow(
                    letter: l,
                    score: _progress.letterScores[l] ?? 0,
                  )),
                            const SizedBox(height: 20),
              const Text('Numbers',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ..._allNumbers.map((n) => _LetterProgressRow(
                    letter: n,
                    score: _progress.letterScores[n] ?? 0,
                  )),    
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCard(double pct, int mastered, int attempted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 7,
                  backgroundColor: AppColors.divider,
                  color: AppColors.primary,
                ),
                Center(
                  child: Text(
                    '${(pct * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$mastered / 26 mastered',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('$attempted attempted',
                    style: AppText.bodySmall),
                Text('${_progress.totalPracticed} sessions',
                    style: AppText.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_progress.streakDays} Day Streak',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Text('Keep practising daily!',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterProgressRow extends StatelessWidget {
  final String letter;
  final int score;
  const _LetterProgressRow({required this.letter, required this.score});

  @override
  Widget build(BuildContext context) {
    final mastered = score >= 80;
    final color = mastered ? AppColors.success : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(letter,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              score > 0 ? '$score%' : '--',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: score > 0 ? color : AppColors.textHint),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}