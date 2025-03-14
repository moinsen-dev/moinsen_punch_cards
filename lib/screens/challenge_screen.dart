import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../services/challenge_service.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeService>(
      builder: (context, challengeService, _) {
        if (challengeService.currentChallenge != null) {
          return _buildActiveChallenge(context, challengeService);
        }
        return _buildChallengeSelection(context, challengeService);
      },
    );
  }

  Widget _buildChallengeSelection(
    BuildContext context,
    ChallengeService challengeService,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Mode'),
        actions: [
          TextButton.icon(
            onPressed: challengeService.resetProgress,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Points: ${challengeService.totalPoints}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Consecutive Wins: ${challengeService.consecutiveWins}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            for (final difficulty in ChallengeDifficulty.values)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => challengeService.startChallenge(difficulty),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(200, 60),
                  ),
                  child: Text(
                    '${difficulty.name.toUpperCase()} DIFFICULTY',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChallenge(
    BuildContext context,
    ChallengeService challengeService,
  ) {
    final challenge = challengeService.currentChallenge!;
    final remainingTime = challengeService.remainingTime ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Time: ${remainingTime}s',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty: ${challenge.difficulty.name.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Points: ${challenge.points}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Required Operations:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final pattern in challenge.requiredPatterns)
                  Chip(label: Text(pattern)),
              ],
            ),
            if (challenge.forbiddenPatterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Forbidden Operations:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final pattern in challenge.forbiddenPatterns)
                    Chip(
                      label: Text(pattern),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: challengeService.resetChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('GIVE UP'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Open punch card editor with current challenge
                  },
                  child: const Text('START CODING'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
