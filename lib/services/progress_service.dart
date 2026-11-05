import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import '../constants/isl_data.dart';

class ProgressService {
    /// Screens listen to this and reload when progress changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static Future<UserProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ISLData.progressKey);
    if (raw == null) return UserProgress.empty();

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final scores = Map<String, int>.from(map['scores'] ?? {});
      final streak = map['streak'] as int? ?? 0;
      final lastActive = DateTime.tryParse(map['lastActive'] ?? '') ?? DateTime.now();
      final total = map['total'] as int? ?? 0;
      return UserProgress(
        letterScores: scores,
        streakDays: streak,
        lastActive: lastActive,
        totalPracticed: total,
      );
    } catch (_) {
      return UserProgress.empty();
    }
  }

  static Future<void> save(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'scores': progress.letterScores,
      'streak': progress.streakDays,
      'lastActive': progress.lastActive.toIso8601String(),
      'total': progress.totalPracticed,
    };
    await prefs.setString(ISLData.progressKey, jsonEncode(map));
    changes.value++;
  }

  static Future<UserProgress> recordAttempt(
    String letter,
    int score,
  ) async {
    final progress = await load();
    final newScores = Map<String, int>.from(progress.letterScores);
    final existing = newScores[letter] ?? 0;
    if (score > existing) newScores[letter] = score;

        final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final last = DateTime.utc(progress.lastActive.year,
        progress.lastActive.month, progress.lastActive.day);
    final daysSince = today.difference(last).inDays;
    final newStreak = progress.totalPracticed == 0
        ? 1
        : daysSince == 0
            ? (progress.streakDays < 1 ? 1 : progress.streakDays)
            : daysSince == 1
                ? progress.streakDays + 1
                : 1;

    final updated = progress.copyWith(
      letterScores: newScores,
      streakDays: newStreak,
      lastActive: now,
      totalPracticed: progress.totalPracticed + 1,
    );
    await save(updated);
    return updated;
  }
}