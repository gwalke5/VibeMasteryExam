import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads and persists the player's score data — a running total plus a
/// history of individual round scores — using on-device local storage
/// (SharedPreferences), so it survives both new rounds and full app
/// restarts.
///
/// All public methods are resilient: if local storage is slow, missing,
/// or throws for any reason, they time out and fall back to a safe
/// default rather than propagating an error. This matters because the
/// game's round-ending flow must never get stuck waiting on persistence.
class ScoreStore {
  static const _totalScoreKey = 'total_score';
  static const _historyKey = 'score_history';
  static const _prefsTimeout = Duration(seconds: 3);

  /// Returns the current persisted total score (0 if none has been saved
  /// yet, e.g. on first launch).
  static Future<int> getTotalScore() => _safely(() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getInt(_totalScoreKey) ?? 0;
      }, fallback: 0);

  /// Returns every individual round score recorded so far, oldest first.
  static Future<List<int>> getScoreHistory() => _safely(() async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList(_historyKey) ?? [];
        return raw.map(int.parse).toList();
      }, fallback: const <int>[]);

  /// Records the result of a completed round: adds [roundScore] to the
  /// running total and appends it to the score history. Returns the new
  /// total (or, if storage fails, a best-effort in-memory total that
  /// simply assumes a starting total of 0 — the round can still proceed
  /// even though nothing was actually saved).
  static Future<int> recordRoundScore(int roundScore) => _safely(() async {
        final prefs = await SharedPreferences.getInstance();

        final newTotal = (prefs.getInt(_totalScoreKey) ?? 0) + roundScore;
        await prefs.setInt(_totalScoreKey, newTotal);

        final history = prefs.getStringList(_historyKey) ?? [];
        history.add(roundScore.toString());
        await prefs.setStringList(_historyKey, history);

        return newTotal;
      }, fallback: roundScore);

  static Future<T> _safely<T>(
    Future<T> Function() action, {
    required T fallback,
  }) async {
    try {
      return await action().timeout(_prefsTimeout);
    } catch (error) {
      debugPrint('ScoreStore operation failed, using fallback: $error');
      return fallback;
    }
  }
}
