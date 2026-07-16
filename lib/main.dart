import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'dolch_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sight Word Match',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LevelSelectScreen(),
    );
  }
}

/// The difficulty levels, in increasing order, and the Dolch category each
/// one draws its words from.
const List<String> difficultyLevels = [
  'Pre-Primer',
  'Primer',
  'First Grade',
  'Second Grade',
  'Third Grade',
];

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sight Word Match'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose a difficulty level',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            for (final level in difficultyLevels) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MatchGameScreen(
                        level: level,
                        words: dolchWordsByCategory[level]!,
                      ),
                    ),
                  );
                },
                child: Text(level, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single card in the memory game grid.
class _GameCard {
  _GameCard(this.word);

  final String word;
  bool faceUp = false;
  bool matched = false;
}

class MatchGameScreen extends StatefulWidget {
  const MatchGameScreen({super.key, required this.level, required this.words});

  final String level;
  final List<String> words;

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  static const int roundSeconds = 30;
  static const int pairCount = 8; // 8 pairs -> 16 cards -> 4x4 grid
  static const Duration mismatchDelay = Duration(milliseconds: 700);

  final Random _random = Random();

  late List<_GameCard> _cards;
  final List<int> _flippedIndices = [];

  Timer? _timer;
  int _secondsLeft = roundSeconds;
  int _matchesFound = 0;
  bool _roundActive = true;
  bool _inputLocked = false; // true while a mismatched pair is being shown

  @override
  void initState() {
    super.initState();
    _cards = [];
    _startNewRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewRound() {
    _timer?.cancel();

    // Pick pairCount unique random words from this level, then duplicate
    // and shuffle them into a fresh random table.
    final pool = List<String>.from(widget.words)..shuffle(_random);
    final chosenWords = pool.take(min(pairCount, pool.length)).toList();
    final pairedWords = [...chosenWords, ...chosenWords]..shuffle(_random);

    setState(() {
      _cards = pairedWords.map((w) => _GameCard(w)).toList();
      _flippedIndices.clear();
      _matchesFound = 0;
      _secondsLeft = roundSeconds;
      _roundActive = true;
      _inputLocked = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        _endRound(won: false);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _endRound({required bool won}) {
    _timer?.cancel();
    setState(() {
      _roundActive = false;
      _inputLocked = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showResultDialog(won));
  }

  void _showResultDialog(bool won) {
    if (!mounted) return;
    final totalPairs = _cards.length ~/ 2;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? "You matched them all! 🎉" : "Time's up!"),
        content: Text('You found $_matchesFound of $totalPairs pairs.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // back to level select
            },
            child: const Text('Change Level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewRound();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _onCardTap(int index) {
    final card = _cards[index];
    if (!_roundActive || _inputLocked || card.faceUp || card.matched) return;

    setState(() {
      card.faceUp = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length < 2) return;

    _inputLocked = true;
    final firstIndex = _flippedIndices[0];
    final secondIndex = _flippedIndices[1];
    final isMatch = _cards[firstIndex].word == _cards[secondIndex].word;

    if (isMatch) {
      // Keep both cards face up; briefly delay so the player can register
      // the match before the tiles lock in.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _cards[firstIndex].matched = true;
          _cards[secondIndex].matched = true;
          _matchesFound++;
          _flippedIndices.clear();
          _inputLocked = false;
        });
        if (_matchesFound == _cards.length ~/ 2) {
          _endRound(won: true);
        }
      });
    } else {
      Future.delayed(mismatchDelay, () {
        if (!mounted) return;
        setState(() {
          _cards[firstIndex].faceUp = false;
          _cards[secondIndex].faceUp = false;
          _flippedIndices.clear();
          _inputLocked = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowOnTime = _secondsLeft <= 10;
    final totalPairs = _cards.length ~/ 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sight Word Match — ${widget.level}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '⏱ $_secondsLeft s',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lowOnTime ? Colors.red : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              'Matches: $_matchesFound / $totalPairs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) => _CardTile(
                  card: _cards[index],
                  onTap: () => _onCardTap(index),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _startNewRound,
              icon: const Icon(Icons.refresh),
              label: const Text('New Round'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onTap});

  final _GameCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = card.faceUp || card.matched;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Container(
          key: ValueKey(revealed),
          decoration: BoxDecoration(
            color: card.matched
                ? colorScheme.primaryContainer
                : revealed
                    ? colorScheme.secondaryContainer
                    : colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            border: card.matched
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: revealed
              ? Text(
                  card.word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSecondaryContainer,
                  ),
                )
              : Icon(Icons.help_outline, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
