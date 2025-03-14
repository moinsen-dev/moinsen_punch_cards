import 'package:flutter/material.dart';

import '../punchcard_generator.dart';
import '../services/ai_service.dart';
import '../widgets/challenge_question.dart';
import '../widgets/punch_card_workspace.dart';
import '../widgets/segmented_number.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  PunchCardProgram? _currentProgram;
  bool _isSubmitting = false;
  String? _validationResult;

  Future<void> _validateSolution() async {
    if (_currentProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a program before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AiService().validateChallengeSolution(
        challengeTitle: 'Simple Addition',
        challengeDescription:
            'Create a program that adds two numbers (5 and 3) and stores the result.',
        requiredOperations: const ['LOAD', 'ADD', 'STORE'],
        programOperations: _currentProgram!.getOperations(),
        context: context,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result['correct'] == true
                              ? Icons.check_circle
                              : Icons.warning,
                          color: result['correct'] == true
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Solution Review',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Score: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${result['score']}/100',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'What You Did Well:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List<String>.from(result['correctPoints'])
                                .map((point) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(point)),
                                        ],
                                      ),
                                    )),
                            const SizedBox(height: 16),
                            const Text(
                              'Areas for Improvement:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List<String>.from(result['improvementPoints'])
                                .map((point) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(point)),
                                        ],
                                      ),
                                    )),
                            const SizedBox(height: 16),
                            const Text(
                              'Advice:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(result['advice'] as String),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating solution: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Mode'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // End challenge
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('End Challenge'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChallengeQuestion(
              title: 'Simple Addition',
              difficulty: 'LOW',
              points: 100,
              description:
                  'Create a program that adds two numbers (5 and 3) and stores the result.',
              requiredOperations: const ['LOAD', 'ADD', 'STORE'],
              timer: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    SegmentedNumber(
                      number: 300,
                      size: 24,
                      activeColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                      inactiveColor: Theme.of(context)
                          .colorScheme
                          .onErrorContainer
                          .withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PunchCardWorkspace(
                initialProgram: _currentProgram,
                onProgramChanged: (program) {
                  setState(() {
                    _currentProgram = program;
                  });
                },
                showAiAnalysis: false,
                readOnly: false,
                showPreview: true,
                showTitle: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentProgram = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _validateSolution,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_isSubmitting ? 'Validating...' : 'Submit Solution'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
