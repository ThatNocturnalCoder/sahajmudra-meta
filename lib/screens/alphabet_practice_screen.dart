import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/isl_data.dart';
import 'tutor_screen.dart';

class AlphabetPracticeScreen extends StatefulWidget {
  final List<String> letters;
  final String title;
  final bool isNumbers;
  final bool isGreetings;

  const AlphabetPracticeScreen({
    super.key,
    required this.letters,
    required this.title,
    this.isNumbers = false,
    this.isGreetings = false,
  });

  @override
  State<AlphabetPracticeScreen> createState() =>
      _AlphabetPracticeScreenState();
}

class _AlphabetPracticeScreenState
    extends State<AlphabetPracticeScreen> {
  int _currentIndex = 0;
  int _completedCount = 0;

  void _onCorrect() {
    if (_currentIndex < widget.letters.length - 1) {
      setState(() {
        _completedCount++;
        _currentIndex++;
      });
    } else {
      setState(() => _completedCount++);
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('🏆 Amazing!',
            style: TextStyle(fontSize: 24)),
        content: Text(
          'You completed all ${widget.letters.length} signs in ${widget.title}!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  String _getDescription(String item) {
    if (widget.isNumbers) {
      return ISLData.numberDescriptions[item] ?? '';
    } else if (widget.isGreetings) {
      return ISLData.greetingDescriptions[item] ?? '';
    }
    return ISLData.letterDescriptions[item] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.letters[_currentIndex];
    final progress = _currentIndex / widget.letters.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header with progress ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
                            child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Sign $item',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12)),
                              Text(
                                '${_currentIndex + 1} / ${widget.letters.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_completedCount ✓',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── Item selector strip ──
          Container(
            height: 48,
            color: AppColors.primary.withValues(alpha: 0.05),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.letters.length,
              itemBuilder: (_, i) {
                final done = i < _currentIndex;
                final current = i == _currentIndex;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _currentIndex = i),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 8),
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.success
                          : current
                              ? AppColors.primary
                              : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: current
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.letters[i],
                        style: TextStyle(
                          fontSize: widget.isGreetings ? 9 : 13,
                          fontWeight: FontWeight.w800,
                          color: (done || current)
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Tutor embedded ──
          Expanded(
            child: TutorScreen(
              key: ValueKey(item),
              letter: item,
              autoAdvance: true,
              onCorrect: _onCorrect,
              customDescription: _getDescription(item),
              isGreeting: widget.isGreetings,
              isNumber: widget.isNumbers,
            ),
          ),
        ],
      ),
    );
  }
}