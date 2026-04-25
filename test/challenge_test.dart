import 'package:flutter_test/flutter_test.dart';
import 'package:moinsen_punch_cards/models/challenge.dart';

void main() {
  group('ChallengeDifficulty', () {
    test('displayName returns correct labels', () {
      expect(ChallengeDifficulty.low.displayName, 'Beginner');
      expect(ChallengeDifficulty.medium.displayName, 'Intermediate');
      expect(ChallengeDifficulty.high.displayName, 'Advanced');
    });
  });

  group('Challenge', () {
    final challenge = Challenge(
      id: 'test-1',
      title: 'Test Challenge',
      description: 'A test',
      difficulty: ChallengeDifficulty.low,
      requiredPatterns: ['LOAD', 'ADD'],
      forbiddenPatterns: ['JMP'],
      timeLimit: 5,
      points: 100,
    );

    test('fromJson creates correct Challenge', () {
      final json = {
        'id': 'test-1',
        'title': 'Test Challenge',
        'description': 'A test',
        'difficulty': 'low',
        'requiredPatterns': ['LOAD', 'ADD'],
        'forbiddenPatterns': ['JMP'],
        'timeLimit': 5,
        'points': 100,
      };

      final result = Challenge.fromJson(json);

      expect(result.id, 'test-1');
      expect(result.title, 'Test Challenge');
      expect(result.difficulty, ChallengeDifficulty.low);
      expect(result.requiredPatterns, ['LOAD', 'ADD']);
      expect(result.forbiddenPatterns, ['JMP']);
      expect(result.timeLimit, 5);
      expect(result.points, 100);
    });

    test('toJson produces correct map', () {
      final json = challenge.toJson();

      expect(json['id'], 'test-1');
      expect(json['title'], 'Test Challenge');
      expect(json['difficulty'], 'low');
      expect(json['requiredPatterns'], ['LOAD', 'ADD']);
      expect(json['forbiddenPatterns'], ['JMP']);
      expect(json['timeLimit'], 5);
      expect(json['points'], 100);
    });

    test('toJson and fromJson round-trip', () {
      final roundTrip = Challenge.fromJson(challenge.toJson());
      expect(roundTrip.id, challenge.id);
      expect(roundTrip.title, challenge.title);
      expect(roundTrip.difficulty, challenge.difficulty);
      expect(roundTrip.requiredPatterns, challenge.requiredPatterns);
      expect(roundTrip.forbiddenPatterns, challenge.forbiddenPatterns);
      expect(roundTrip.timeLimit, challenge.timeLimit);
      expect(roundTrip.points, challenge.points);
    });

    test('sampleChallenges returns 3 challenges', () {
      expect(Challenge.sampleChallenges.length, 3);
      expect(
        Challenge.sampleChallenges.map((c) => c.difficulty).toSet(),
        {
          ChallengeDifficulty.low,
          ChallengeDifficulty.medium,
          ChallengeDifficulty.high,
        },
      );
    });
  });
}
