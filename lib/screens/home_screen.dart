import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/isl_data.dart';
import '../services/progress_service.dart';
import '../models/user_progress.dart';
import 'tutor_screen.dart';
import 'alphabet_practice_screen.dart';

class HomeScreen extends StatefulWidget {
  final int level;
  final String userName;
  const HomeScreen({super.key, required this.level, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProgress _progress = UserProgress.empty();
  bool _loaded = false;

  static const _levelNames = ['Beginner', 'Intermediate', 'Expert'];
  static const _levelColors = [
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
  ];
  static const _levelEmojis = ['🌱', '⚡', '🏆'];
  static const _unlockedLetters = [
  // Beginner — full A-Z
  ['A','B','C','D','E','F','G','H','I','J','K','L','M',
   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  // Intermediate — full A-Z
  ['A','B','C','D','E','F','G','H','I','J','K','L','M',
   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  // Expert — full A-Z
  ['A','B','C','D','E','F','G','H','I','J','K','L','M',
   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
];

    @override
  void initState() {
    super.initState();
    _loadProgress();
    ProgressService.changes.addListener(_loadProgress);
  }

  @override
  void dispose() {
    ProgressService.changes.removeListener(_loadProgress);
    super.dispose();
  }
  Future<void> _loadProgress() async {
    final p = await ProgressService.load();
    if (mounted) setState(() { _progress = p; _loaded = true; });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<String> get _unlocked => _unlockedLetters[widget.level];

  int get _masteredCount =>
      _unlocked.where((l) => (_progress.letterScores[l] ?? 0) >= 80).length;

  String get _nextLetter {
    for (final l in _unlocked) {
      if ((_progress.letterScores[l] ?? 0) < 80) return l;
    }
    return _unlocked.last;
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColors[widget.level];
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
            child: _loaded
                ? _buildContent(levelColor)
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color levelColor) {
    final total = _unlocked.length;
    final pct = total == 0 ? 0.0 : _masteredCount / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_greeting,',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    Text(widget.userName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: levelColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_levelEmojis[widget.level],
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(_levelNames[widget.level],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: levelColor)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stats row ──
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '🔥',
                  value: '${_progress.streakDays}',
                  label: 'Day Streak',
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  emoji: '✅',
                  value: '$_masteredCount',
                  label: 'Mastered',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  emoji: '📈',
                  value: '${(pct * 100).toInt()}%',
                  label: 'Complete',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Continue learning card ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TutorScreen(letter: _nextLetter)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Continue Learning',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Sign $_nextLetter',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          ISLData.letterDescriptions[_nextLetter]
                                  ?.split('.').first ??
                              '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Quick action cards ──
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildQuickActions(),

          const SizedBox(height: 20),

          // ── Your Letters grid ──
          const Text('Your Letters',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('$_masteredCount / ${_unlocked.length} mastered',
              style: AppText.bodySmall),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _unlocked.length,
            itemBuilder: (_, i) {
              final letter = _unlocked[i];
              final score = _progress.letterScores[letter] ?? 0;
              final mastered = score >= 80;
              final attempted = score > 0;
              final bg = mastered
                  ? AppColors.success.withValues(alpha: 0.15)
                  : attempted
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.cardBg;
              final textColor = mastered
                  ? AppColors.success
                  : attempted
                      ? AppColors.accent
                      : AppColors.textSecondary;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TutorScreen(letter: letter)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(
                    child: Text(letter,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
  if (widget.level == 0) {
    // Beginner
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '🔤',
                title: 'Alphabets',
                subtitle: 'A to Z',
                color: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.alphabet,
                    title: 'ISL Alphabets',
                  ),
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '🔢',
                title: 'Numbers',
                subtitle: '0 to 9',
                color: AppColors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.numbers,
                    title: 'ISL Numbers',
                    isNumbers: true,
                  ),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '👋',
                title: 'Greetings',
                subtitle: 'Hello, Thanks...',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.greetings,
                    title: 'ISL Greetings',
                    isGreetings: true,
                  ),
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '🤖',
                title: 'AI Tutor',
                subtitle: 'Free practice',
                color: const Color(0xFFE65100),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TutorScreen(letter: _nextLetter),
                )),
              ),
            ),
          ],
        ),
      ],
    );
  } else if (widget.level == 1) {
    // Intermediate
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '🔤',
                title: 'Full Alphabet',
                subtitle: 'A to Z',
                color: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.alphabet,
                    title: 'Full ISL Alphabet',
                  ),
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '📖',
                title: 'Basic Words',
                subtitle: 'Common signs',
                color: AppColors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.greetings,
                    title: 'Basic Words',
                    isGreetings: true,
                  ),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '⚡',
                title: 'Speed Round',
                subtitle: 'Random 10',
                color: const Color(0xFFE65100),
                onTap: () {
                  final shuffled = [...ISLData.alphabet]..shuffle();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AlphabetPracticeScreen(
                      letters: shuffled.take(10).toList(),
                      title: 'Speed Round',
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '🤖',
                title: 'AI Tutor',
                subtitle: 'Free practice',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TutorScreen(letter: _nextLetter),
                )),
              ),
            ),
          ],
        ),
      ],
    );
  } else {
    // Expert
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '🏆',
                title: 'Full Alphabet',
                subtitle: 'A to Z',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.alphabet,
                    title: 'Expert Alphabet',
                  ),
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '💬',
                title: 'Sentences',
                subtitle: 'Build phrases',
                color: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlphabetPracticeScreen(
                    letters: ISLData.greetings,
                    title: 'Sentence Practice',
                    isGreetings: true,
                  ),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashCard(
                icon: '🎯',
                title: 'Challenge',
                subtitle: 'All 26 shuffled',
                color: const Color(0xFFE65100),
                onTap: () {
                  final shuffled = [...ISLData.alphabet]..shuffle();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AlphabetPracticeScreen(
                      letters: shuffled,
                      title: 'Expert Challenge',
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashCard(
                icon: '🤖',
                title: 'AI Tutor',
                subtitle: 'Free practice',
                color: AppColors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TutorScreen(letter: _nextLetter),
                )),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String icon, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}