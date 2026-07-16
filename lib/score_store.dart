import 'package:shared_preferences/shared_preferences.dart';

/// Reads and persists the player's cumulative score using on-device local
/// storage (SharedPreferences), so the total survives both new rounds and
/// full app restarts.
class ScoreStore {
  static const _totalScoreKey = 'total_score';

  /// Returns the current persisted total score (0 if none has been saved
  /// yet, e.g. on first launch).
  static Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalScoreKey) ?? 0;
  }

  /// Adds [roundScore] to the persisted total and returns the new total.
  static Future<int> addToTotalScore(int roundScore) async {
    final prefs = await SharedPreferences.getInstance();
    final newTotal = (prefs.getInt(_totalScoreKey) ?? 0) + roundScore;
    await prefs.setInt(_totalScoreKey, newTotal);
    return newTotal;
  }
}
