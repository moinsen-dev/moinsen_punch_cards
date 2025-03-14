import 'dart:async';
import 'dart:ui';

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

  Timer? _timer;

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

    // Initialize timer controller
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _questionController.forward();
  }

  void _startTimer() {
    // Reset and start the timer
    _timerController.stop();
    _timerController.reset();
    _timerController.repeat();

    // Start the countdown
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && !_isInTutorial) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _showTimeUp();
        }
      }
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    _questionController.dispose();
    _timerController.dispose();
    _timer?.cancel();
    super.dispose();
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

    // Start the timer
    _startTimer();
  }

  void _showTimeUp() {
    _timerController.stop(); // Stop the timer animation
    _timer?.cancel(); // Stop the countdown
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

    late final OverlayEntry overlayEntry;

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

    // Show the overlay
    overlayEntry = OverlayEntry(
      builder: (context) => _AnswerOverlay(
        isCorrect: _isCorrect!,
        explanation: _questions[_currentQuestionIndex].explanation,
        onFinished: () {
          overlayEntry.remove();
          if (_consecutiveCorrect >= 5) {
            _showGameComplete();
          } else {
            _nextQuestion();
          }
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
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
        backgroundColor: const Color(0xFF000B2C),
        actions: [
          if (!_isInTutorial) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white70),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 30
                          ? Colors.red.withAlpha(48)
                          : Colors.blue.withAlpha(48),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _remainingSeconds < 30
                            ? Colors.red.withAlpha(128)
                            : Colors.blue.withAlpha(128),
                      ),
                    ),
                    child: SegmentedNumber(
                      number: _remainingSeconds,
                      size: 24,
                      activeColor: _remainingSeconds < 30
                          ? Colors.red
                          : Colors.blue[300]!,
                      inactiveColor: _remainingSeconds < 30
                          ? Colors.red.withAlpha(32)
                          : Colors.blue.withAlpha(32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white70),
                  const SizedBox(width: 8),
                  ScaleTransition(
                    scale: _scoreAnimation,
                    child: SegmentedNumber(
                      number: _currentScore,
                      size: 24,
                      activeColor: Colors.blue[300]!,
                      inactiveColor: Colors.blue.withAlpha(32),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF000B2C),
            const Color(0xFF000B2C).withBlue(80),
          ],
        ),
      ),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _consecutiveCorrect / 5,
            backgroundColor: Colors.white24,
            color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Question card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1545),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withAlpha(128),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(48),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(48),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(128),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    size: 16,
                                    color: Colors.blue[300],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Question ${_currentQuestionIndex + 1}',
                                    style: TextStyle(
                                      color: Colors.blue[300],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Difficulty: ${question.difficulty}',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          question.question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Answer options
                  ...List.generate(
                    question.options.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: _MillionaireButton(
                        text: question.options[index],
                        letter: String.fromCharCode(65 + index),
                        onPressed:
                            _hasAnswered ? null : () => _checkAnswer(index),
                        isCorrect:
                            _hasAnswered && index == question.correctIndex,
                        isSelected: _hasAnswered && index == _selectedAnswer,
                        isWrong: _hasAnswered &&
                            index == _selectedAnswer &&
                            !_isCorrect!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MillionaireButton extends StatelessWidget {
  final String text;
  final String letter;
  final VoidCallback? onPressed;
  final bool isCorrect;
  final bool isSelected;
  final bool isWrong;

  const _MillionaireButton({
    required this.text,
    required this.letter,
    required this.onPressed,
    this.isCorrect = false,
    this.isSelected = false,
    this.isWrong = false,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor = const Color(0xFF0A1545);
    Color borderColor = Colors.blue.withAlpha(128);
    Color textColor = Colors.white;

    if (isCorrect) {
      baseColor = Colors.green.withAlpha(32);
      borderColor = Colors.green;
      textColor = Colors.green[100]!;
    } else if (isWrong) {
      baseColor = Colors.red.withAlpha(32);
      borderColor = Colors.red;
      textColor = Colors.red[100]!;
    } else if (isSelected) {
      baseColor = Colors.orange.withAlpha(32);
      borderColor = Colors.orange;
      textColor = Colors.orange[100]!;
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(128),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isCorrect)
                  Icon(Icons.check_circle, color: Colors.green[300])
                else if (isWrong)
                  Icon(Icons.cancel, color: Colors.red[300]),
              ],
            ),
          ),
        ),
      ),
    );
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

class _AnswerOverlay extends StatefulWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onFinished;

  const _AnswerOverlay({
    required this.isCorrect,
    required this.explanation,
    required this.onFinished,
  });

  @override
  State<_AnswerOverlay> createState() => _AnswerOverlayState();
}

class _AnswerOverlayState extends State<_AnswerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    ));

    _controller.forward();

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      _controller.reverse().then((_) {
        widget.onFinished();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Blur effect
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 32,
              right: 32,
              top: MediaQuery.of(context).size.height *
                  0.3, // Position in the middle section
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                      0, _slideAnimation.value), // Slide down instead of up
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.isCorrect
                          ? const Color(0xFF0A4515)
                          : const Color(0xFF450A0A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isCorrect
                            ? Colors.green.withAlpha(128)
                            : Colors.red.withAlpha(128),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isCorrect ? Colors.green : Colors.red)
                              .withAlpha(32),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: widget.isCorrect
                                  ? Colors.green[300]
                                  : Colors.red[300],
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              widget.isCorrect ? 'Correct!' : 'Not quite right',
                              style: TextStyle(
                                color: widget.isCorrect
                                    ? Colors.green[300]
                                    : Colors.red[300],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.explanation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
