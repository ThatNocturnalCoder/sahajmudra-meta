class UserProgress {
  final Map<String, int> letterScores; // letter -> best score 0-100
  final int streakDays;
  final DateTime lastActive;
  final int totalPracticed;

  const UserProgress({
    required this.letterScores,
    required this.streakDays,
    required this.lastActive,
    required this.totalPracticed,
  });

  factory UserProgress.empty() => UserProgress(
    letterScores: {},
    streakDays: 0,
    lastActive: DateTime.now(),
    totalPracticed: 0,
  );

    static bool _isLetter(String k) =>
      k.length == 1 && k.codeUnitAt(0) >= 65 && k.codeUnitAt(0) <= 90;

  int get masteredCount => letterScores.entries
      .where((e) => _isLetter(e.key) && e.value >= 80)
      .length;

  int get attemptedCount => letterScores.keys.where(_isLetter).length;

  double get overallProgress => masteredCount / 26;

  UserProgress copyWith({
    Map<String, int>? letterScores,
    int? streakDays,
    DateTime? lastActive,
    int? totalPracticed,
  }) => UserProgress(
    letterScores: letterScores ?? this.letterScores,
    streakDays: streakDays ?? this.streakDays,
    lastActive: lastActive ?? this.lastActive,
    totalPracticed: totalPracticed ?? this.totalPracticed,
  );
}