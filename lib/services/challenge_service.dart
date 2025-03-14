import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/challenge.dart';

class ChallengeService extends ChangeNotifier {
  Challenge? _currentChallenge;
  ChallengeStatus _status = ChallengeStatus.notStarted;
  int _totalPoints = 0;
  int _consecutiveWins = 0;
  DateTime? _startTime;
  final List<String> _completedChallenges = [];
  Timer? _timer;

  // Getters
  Challenge? get currentChallenge => _currentChallenge;
  ChallengeStatus get status => _status;
  int get totalPoints => _totalPoints;
  int get consecutiveWins => _consecutiveWins;
  int? get remainingTime {
    if (_startTime == null || _currentChallenge == null) return null;
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    return max(0, _currentChallenge!.timeLimit - elapsed);
  }

  // Start a new challenge
  void startChallenge(ChallengeDifficulty difficulty) {
    // Filter challenges by difficulty and not completed
    final availableChallenges = Challenge.sampleChallenges
        .where((c) =>
            c.difficulty == difficulty && !_completedChallenges.contains(c.id))
        .toList();

    if (availableChallenges.isEmpty) {
      _status = ChallengeStatus.completed;
      notifyListeners();
      return;
    }

    // Randomly select a challenge
    final random = Random();
    _currentChallenge =
        availableChallenges[random.nextInt(availableChallenges.length)];
    _status = ChallengeStatus.inProgress;
    _startTime = DateTime.now();

    // Start the timer
    _startTimer();
    notifyListeners();
  }

  // Submit a solution for the current challenge
  void submitSolution(List<String> punchCardRows) {
    if (_currentChallenge == null || _status != ChallengeStatus.inProgress) {
      return;
    }

    bool isCorrect = _verifySolution(punchCardRows);

    if (isCorrect) {
      _completedChallenges.add(_currentChallenge!.id);
      _totalPoints += _currentChallenge!.points;
      _consecutiveWins++;
      _status = ChallengeStatus.completed;
    } else {
      _consecutiveWins = 0;
      _status = ChallengeStatus.failed;
    }

    _stopTimer();
    notifyListeners();
  }

  // Reset the current challenge
  void resetChallenge() {
    _currentChallenge = null;
    _status = ChallengeStatus.notStarted;
    _startTime = null;
    _stopTimer();
    notifyListeners();
  }

  // Reset all progress
  void resetProgress() {
    _totalPoints = 0;
    _consecutiveWins = 0;
    _completedChallenges.clear();
    resetChallenge();
  }

  bool _verifySolution(List<String> punchCardRows) {
    if (_currentChallenge == null) return false;

    // Check if all required patterns are present
    bool hasAllRequired = _currentChallenge!.requiredPatterns
        .every((pattern) => punchCardRows.any((row) => row.contains(pattern)));

    // Check if any forbidden patterns are present
    bool hasForbidden = _currentChallenge!.forbiddenPatterns
        .any((pattern) => punchCardRows.any((row) => row.contains(pattern)));

    return hasAllRequired && !hasForbidden;
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        _status = ChallengeStatus.failed;
        _consecutiveWins = 0;
        _stopTimer();
        notifyListeners();
      } else {
        notifyListeners(); // Update UI with new remaining time
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
