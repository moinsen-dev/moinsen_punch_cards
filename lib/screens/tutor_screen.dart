import 'package:flutter/material.dart';

import '../widgets/segmented_number.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _questionController;
  late Animation<double> _questionSlideAnimation;
  late Animation<double> _questionFadeAnimation;
  late AnimationController _timerController;

  bool _isInTutorial = true;
  int _currentScore = 0;
  int _consecutiveCorrect = 0;
  int _currentQuestionIndex = 0;
  bool _hasAnswered = false;
  int? _selectedAnswer;
  bool? _isCorrect;
  int _remainingSeconds = 180; // 3 minutes

  // Mock questions - In real app, these would come from an AI model
  final List<TutorQuestion> _questions = [
    const TutorQuestion(
      question: "What is the purpose of a punch card?",
      explanation:
          "Punch cards were one of the earliest forms of data storage and program input. Each hole in the card represents a piece of data or instruction that the computer can read.",
      options: [
        "To print documents",
        "To store and input data/programs",
        "To draw pictures",
        "To play music"
      ],
      correctIndex: 1,
      difficulty: 1,
    ),
    const TutorQuestion(
      question:
          "Which row is used for the 'Y' coordinate in our punch card system?",
      explanation:
          "In our punch card system, Row 0 (the first row) is designated for the 'Y' coordinate. This is a fundamental concept in punch card programming.",
      options: ["Row 0", "Row 1", "Row 2", "Row 3"],
      correctIndex: 0,
      difficulty: 1,
    ),
    const TutorQuestion(
      question: "How many columns does each punch card have?",
      explanation:
          "Each punch card has exactly 80 columns, numbered from 1 to 80. This was a standard format used in early computing systems.",
      options: ["40 columns", "60 columns", "80 columns", "100 columns"],
      correctIndex: 2,
      difficulty: 1,
    ),
    const TutorQuestion(
      question: "What does the 'LOAD' operation do in punch card programming?",
      explanation:
          "The LOAD operation reads a value from a specified column and stores it in the computer's memory for further processing.",
      options: [
        "Prints the value",
        "Reads a value into memory",
        "Saves a value to disk",
        "Deletes a value"
      ],
      correctIndex: 1,
      difficulty: 2,
    ),
    const TutorQuestion(
      question: "Which rows are used for numeric values (0-9) in our system?",
      explanation:
          "Rows 2-11 are used for numeric values 0-9. Row 2 represents 0, Row 3 represents 1, and so on up to Row 11 representing 9.",
      options: ["Rows 0-9", "Rows 1-10", "Rows 2-11", "Rows 3-12"],
      correctIndex: 2,
      difficulty: 2,
    ),
    const TutorQuestion(
      question:
          "What happens when multiple holes are punched in the same column?",
      explanation:
          "When multiple holes are punched in the same column, each hole represents a different part of the instruction or data. For example, one hole might indicate the operation type while others represent the value.",
      options: [
        "It causes an error",
        "Only the first hole is read",
        "Each hole has a specific meaning",
        "The column is skipped"
      ],
      correctIndex: 2,
      difficulty: 2,
    ),
    const TutorQuestion(
      question: "Which operation would you use to add two numbers together?",
      explanation:
          "The ADD operation takes values from two columns and adds them together, storing the result in a specified location.",
      options: ["LOAD", "STORE", "ADD", "PRINT"],
      correctIndex: 2,
      difficulty: 3,
    ),
    const TutorQuestion(
      question: "What is the purpose of the 'JMP' operation?",
      explanation:
          "The JMP (Jump) operation changes the program's execution flow by moving to a different column, allowing for loops and conditional execution.",
      options: [
        "To skip broken cards",
        "To control program flow",
        "To join two cards together",
        "To mark the end of data"
      ],
      correctIndex: 1,
      difficulty: 3,
    ),
    const TutorQuestion(
      question: "How would you store the result of a calculation?",
      explanation:
          "The STORE operation is used to save a value from memory into a specific column on the punch card, making it available for later use.",
      options: [
        "Use the PRINT operation",
        "Use the STORE operation",
        "Use the SAVE operation",
        "Use the WRITE operation"
      ],
      correctIndex: 1,
      difficulty: 2,
    ),
    const TutorQuestion(
      question: "What is the purpose of the 'JZ' operation?",
      explanation:
          "JZ (Jump if Zero) is a conditional jump that only occurs if the last operation resulted in zero, enabling decision-making in punch card programs.",
      options: [
        "Jump to the end of the card",
        "Jump if the result is zero",
        "Jump to zone zero",
        "Jump to the next card"
      ],
      correctIndex: 1,
      difficulty: 3,
    ),
    const TutorQuestion(
      question: "How can you create a loop in a punch card program?",
      explanation:
          "Loops are created using JMP operations to return to a previous column, often combined with conditional jumps (JZ, JN) to control when to exit the loop.",
      options: [
        "Punch holes in a circular pattern",
        "Use the LOOP operation",
        "Use JMP to return to an earlier column",
        "Physically connect multiple cards"
      ],
      correctIndex: 2,
      difficulty: 3,
    ),
    const TutorQuestion(
      question: "What is the 'X' row used for in our punch card system?",
      explanation:
          "Row 1 (X row) is used alongside the Y row for coordinate-based operations and special instructions, providing additional functionality beyond simple numeric values.",
      options: [
        "To mark the end of data",
        "For coordinate operations",
        "To indicate errors",
        "To separate cards"
      ],
      correctIndex: 1,
      difficulty: 2,
    ),
  ];

  final String _tutorialContent = """
Welcome to Punch Card Programming! 🚀

Punch cards were one of the earliest forms of computer programming, where holes punched in specific positions represented instructions and data. Let's learn how they work!

Key Concepts:
1. Each card has 80 columns and 12 rows
2. Rows 0-1 are used for coordinates (X, Y)
3. Rows 2-11 represent numbers 0-9
4. Multiple holes in a column create complex instructions

Basic Operations:
• LOAD - Read a value from a column
• STORE - Save a value to a column
• ADD - Add two values together
• JMP - Jump to another column
• JZ - Jump if the result is zero

Tips for Success:
• Pay attention to row numbers
• Understand how multiple holes work together
• Think about program flow with jumps
• Practice with simple operations first

Ready to test your knowledge? Click 'Start Quiz' when you're ready!
""";

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutBack),
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );

    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionSlideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutCubic),
    );
    _questionFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );

    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(_updateTimer);

    _questionController.forward();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    _questionController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    if (_remainingSeconds > 0 && !_isInTutorial) {
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds > 0) {
        _timerController.forward(from: 0);
      } else {
        _showTimeUp();
      }
    }
  }

  void _startQuiz() {
    setState(() {
      _isInTutorial = false;
      _currentQuestionIndex = 0;
      _currentScore = 0;
      _consecutiveCorrect = 0;
      _hasAnswered = false;
      _selectedAnswer = null;
      _isCorrect = null;
      _remainingSeconds = 180; // Reset to 3 minutes
    });

    // Start the timer immediately
    Future.microtask(() {
      _timerController.forward(from: 0);
    });
  }

  void _showTimeUp() {
    _timerController.stop(); // Stop the timer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up! ⏰'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You\'ve run out of time! Here\'s how you did:'),
            const SizedBox(height: 16),
            SegmentedNumber(
              number: _currentScore,
              size: 48,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isInTutorial = true;
                _remainingSeconds = 180;
              });
            },
            child: const Text('Back to Tutorial'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startQuiz();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    _questionController.forward(from: 0);
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1) % _questions.length;
      _hasAnswered = false;
      _selectedAnswer = null;
      _isCorrect = null;
    });
  }

  void _checkAnswer(int selectedIndex) {
    if (_hasAnswered) return;

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = selectedIndex;
      _isCorrect =
          selectedIndex == _questions[_currentQuestionIndex].correctIndex;

      if (_isCorrect!) {
        _currentScore += (_questions[_currentQuestionIndex].difficulty * 100);
        _consecutiveCorrect++;
        _scoreController.forward(from: 0);
      } else {
        _consecutiveCorrect = 0;
      }
    });

    _feedbackController.forward(from: 0);

    // Wait before showing next question or ending game
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (_consecutiveCorrect >= 5) {
        _showGameComplete();
      } else {
        _nextQuestion();
      }
    });
  }

  void _showGameComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'You\'ve mastered the basics of punch card programming!'),
            const SizedBox(height: 16),
            SegmentedNumber(
              number: _currentScore,
              size: 48,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentScore = 0;
                _consecutiveCorrect = 0;
                _currentQuestionIndex = 0;
                _hasAnswered = false;
                _selectedAnswer = null;
                _isCorrect = null;
              });
            },
            child: const Text('Play Again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch Card Tutor'),
        actions: [
          if (!_isInTutorial) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.timer),
                  const SizedBox(width: 8),
                  SegmentedNumber(
                    number: _remainingSeconds,
                    size: 24,
                    activeColor: _remainingSeconds < 30
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.star),
                  const SizedBox(width: 8),
                  ScaleTransition(
                    scale: _scoreAnimation,
                    child: SegmentedNumber(
                      number: _currentScore,
                      size: 24,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      body: _isInTutorial ? _buildTutorial() : _buildQuiz(),
    );
  }

  Widget _buildTutorial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 32,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tutorial',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Learn the basics of punch card programming',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _tutorialContent,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Quiz'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: _consecutiveCorrect / 5,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          color: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _questionController,
              builder: (context, child) => Transform.translate(
                offset: Offset(_questionSlideAnimation.value, 0),
                child: Opacity(
                  opacity: _questionFadeAnimation.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lightbulb,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Question ${_currentQuestionIndex + 1}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Difficulty: ${question.difficulty}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                question.question,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Answer options
                      ...List.generate(
                        question.options.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedScale(
                            scale: _hasAnswered && _selectedAnswer == index
                                ? 0.95
                                : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: FilledButton(
                              onPressed: _hasAnswered
                                  ? null
                                  : () => _checkAnswer(index),
                              style: FilledButton.styleFrom(
                                backgroundColor: _getOptionColor(index),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  if (_hasAnswered &&
                                      index == question.correctIndex)
                                    const Icon(Icons.check_circle),
                                  if (_hasAnswered &&
                                      index == _selectedAnswer &&
                                      !_isCorrect!)
                                    const Icon(Icons.cancel),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_hasAnswered)
                        FadeTransition(
                          opacity: _feedbackAnimation,
                          child: Card(
                            color: _isCorrect!
                                ? Colors.green.withAlpha(64)
                                : Colors.red.withAlpha(64),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isCorrect!
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: _isCorrect!
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isCorrect!
                                            ? 'Correct!'
                                            : 'Not quite right',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: _isCorrect!
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    question.explanation,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color? _getOptionColor(int index) {
    if (!_hasAnswered) return null;

    final currentQuestion = _questions[_currentQuestionIndex];
    if (index == currentQuestion.correctIndex) {
      return Colors.green.withAlpha(128);
    }
    if (index == _selectedAnswer && !_isCorrect!) {
      return Colors.red.withAlpha(128);
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}

class TutorQuestion {
  final String question;
  final String explanation;
  final List<String> options;
  final int correctIndex;
  final int difficulty;

  const TutorQuestion({
    required this.question,
    required this.explanation,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });
}
