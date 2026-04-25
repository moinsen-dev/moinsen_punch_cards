import 'package:flutter_test/flutter_test.dart';
import 'package:moinsen_punch_cards/services/challenge_service.dart';
import 'package:moinsen_punch_cards/models/challenge.dart';

void main() {
  group('ChallengeService', () {
    late ChallengeService service;

    setUp(() {
      service = ChallengeService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is correct', () {
      expect(service.currentChallenge, isNull);
      expect(service.status, ChallengeStatus.notStarted);
      expect(service.totalPoints, 0);
      expect(service.consecutiveWins, 0);
      expect(service.remainingTime, isNull);
    });

    test('startChallenge sets status to inProgress', () {
      service.startChallenge(ChallengeDifficulty.low);

      expect(service.status, ChallengeStatus.inProgress);
      expect(service.currentChallenge, isNotNull);
      expect(service.currentChallenge!.difficulty, ChallengeDifficulty.low);
      expect(service.remainingTime, isNotNull);
      expect(service.remainingTime, greaterThan(0));
    });

    test('submitSolution with correct patterns completes challenge', () {
      service.startChallenge(ChallengeDifficulty.low);
      final challenge = service.currentChallenge!;

      final solution = challenge.requiredPatterns
          .map((p) => 'row with $p')
          .toList();

      service.submitSolution(solution);

      expect(service.status, ChallengeStatus.completed);
      expect(service.totalPoints, challenge.points);
      expect(service.consecutiveWins, 1);
    });

    test('submitSolution with missing patterns fails challenge', () {
      service.startChallenge(ChallengeDifficulty.low);

      service.submitSolution(['nothing relevant']);

      expect(service.status, ChallengeStatus.failed);
      expect(service.totalPoints, 0);
      expect(service.consecutiveWins, 0);
    });

    test('submitSolution ignores call when no challenge active', () {
      service.submitSolution(['LOAD', 'ADD']);

      expect(service.status, ChallengeStatus.notStarted);
      expect(service.totalPoints, 0);
    });

    test('resetChallenge returns to notStarted', () {
      service.startChallenge(ChallengeDifficulty.low);
      expect(service.status, ChallengeStatus.inProgress);

      service.resetChallenge();

      expect(service.currentChallenge, isNull);
      expect(service.status, ChallengeStatus.notStarted);
      expect(service.remainingTime, isNull);
    });

    test('resetProgress clears everything', () {
      service.startChallenge(ChallengeDifficulty.low);
      final challenge = service.currentChallenge!;
      service.submitSolution(
        challenge.requiredPatterns.map((p) => 'row with $p').toList(),
      );
      expect(service.totalPoints, greaterThan(0));

      service.resetProgress();

      expect(service.totalPoints, 0);
      expect(service.consecutiveWins, 0);
      expect(service.currentChallenge, isNull);
      expect(service.status, ChallengeStatus.notStarted);
    });

    test('consecutiveWins resets on failure', () {
      service.startChallenge(ChallengeDifficulty.low);
      final challenge = service.currentChallenge!;
      service.submitSolution(
        challenge.requiredPatterns.map((p) => 'row with $p').toList(),
      );
      expect(service.consecutiveWins, 1);

      service.resetChallenge();
      service.startChallenge(ChallengeDifficulty.medium);
      service.submitSolution(['wrong']);
      expect(service.consecutiveWins, 0);
    });

    test('completed challenge cannot be selected again', () {
      service.startChallenge(ChallengeDifficulty.low);
      final first = service.currentChallenge!;
      service.submitSolution(
        first.requiredPatterns.map((p) => 'row with $p').toList(),
      );

      service.resetChallenge();
      service.startChallenge(ChallengeDifficulty.low);

      if (service.status == ChallengeStatus.inProgress) {
        expect(service.currentChallenge!.id, isNot(equals(first.id)));
      }
    });

    test('all challenges completed sets status to completed', () {
      final lowChallenges = Challenge.sampleChallenges
          .where((c) => c.difficulty == ChallengeDifficulty.low)
          .toList();

      for (final _ in lowChallenges) {
        service.resetChallenge();
        service.startChallenge(ChallengeDifficulty.low);
        if (service.status == ChallengeStatus.inProgress) {
          final c = service.currentChallenge!;
          service.submitSolution(
            c.requiredPatterns.map((p) => 'row with $p').toList(),
          );
        }
      }

      service.resetChallenge();
      service.startChallenge(ChallengeDifficulty.low);
      expect(service.status, ChallengeStatus.completed);
    });
  });
}
