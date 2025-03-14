import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../punchcard_generator.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../widgets/segmented_number.dart';

enum EditorMode { instructions, directPunch, aiText, savedCards }

class PunchCardEditor extends StatefulWidget {
  final SettingsService settingsService;

  const PunchCardEditor({super.key, required this.settingsService});

  @override
  State<PunchCardEditor> createState() => _PunchCardEditorState();
}

class _PunchCardEditorState extends State<PunchCardEditor>
    with TickerProviderStateMixin {
  final List<PunchCardProgram> _savedPrograms = [];
  PunchCardProgram? _currentProgram;
  final TextEditingController _titleController = TextEditingController();
  final PunchCardSvgGenerator _svgGenerator = PunchCardSvgGenerator();
  EditorMode _currentMode = EditorMode.directPunch;
  final TextEditingController _aiInputController = TextEditingController();

  // For direct punch mode
  final List<List<bool>> _punchedHoles = List.generate(
    12, // 12 rows (Y, X, 0-9)
    (i) => List.generate(80, (j) => false), // 80 columns
  );

  String? _aiAnalysis;
  bool _isAnalyzing = false;
  bool _isPreviewExpanded = false;

  late AudioPlayer audioPlayer;
  final List<GlobalKey> _cardKeys = [];
  late AnimationController _shakeController;
  bool _isShuffling = false;
  final math.Random _random = math.Random();

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  DateTime? _lastShake;
  final double _shakeThreshold = 20.0;
  final Duration _shakeCooldown = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _initShakeDetection();
    _initAudio();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  void _initShakeDetection() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      final double acceleration = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final now = DateTime.now();
      if (_lastShake == null || now.difference(_lastShake!) > _shakeCooldown) {
        if (acceleration > _shakeThreshold &&
            !_isShuffling &&
            _savedPrograms.length > 1) {
          _lastShake = now;
          _shuffleCards();
          HapticFeedback.mediumImpact();
        }
      }
    });
  }

  void _initAudio() {
    audioPlayer = AudioPlayer();
  }

  Future<void> _playShuffleSound() async {
    await audioPlayer.play(AssetSource('sounds/shuffle.mp3'));
  }

  Future<void> _shuffleCards() async {
    if (_isShuffling) return;

    setState(() {
      _isShuffling = true;
      // Clear and reinitialize card keys
      _cardKeys.clear();
      for (int i = 0; i < _savedPrograms.length; i++) {
        _cardKeys.add(GlobalKey());
      }
    });

    // Play shuffle sound
    await _playShuffleSound();

    // Start shake animation
    _shakeController.forward(from: 0);

    // Wait for cards to "fall"
    await Future.delayed(const Duration(milliseconds: 500));

    // Shuffle the saved programs
    setState(() {
      _savedPrograms.shuffle();
    });

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isShuffling = false;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    audioPlayer.dispose();
    _shakeController.dispose();
    _aiInputController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _createNewProgram() {
    setState(() {
      _titleController.text = 'New Punch Card';
      _currentProgram = PunchCardProgram(
        title: _titleController.text,
        instructions: [],
      );
      // Reset punched holes for direct mode
      for (var row in _punchedHoles) {
        row.fillRange(0, row.length, false);
      }
      // Switch to instruction mode when creating a new card
      _currentMode = EditorMode.instructions;
    });
  }

  void _toggleHole(int row, int column) {
    setState(() {
      _punchedHoles[row][column] = !_punchedHoles[row][column];

      // Convert punched holes to instructions
      List<PunchCardInstruction> instructions = [];
      for (int col = 0; col < 80; col++) {
        List<int> punchedRows = [];
        for (int row = 0; row < 12; row++) {
          if (_punchedHoles[row][col]) {
            punchedRows.add(row);
          }
        }
        if (punchedRows.isNotEmpty) {
          instructions.add(
            PunchCardInstruction(
              column: col + 1,
              rows: punchedRows,
              operation: 'DATA',
              parameters: {'value': ''},
            ),
          );
        }
      }

      _currentProgram = PunchCardProgram(
        title: _titleController.text,
        instructions: instructions,
      );
    });
  }

  void _saveProgram() {
    if (_currentProgram != null) {
      setState(() {
        // Update the title
        _currentProgram = PunchCardProgram(
          title: _titleController.text,
          instructions: _currentProgram!.instructions,
        );

        // Add to saved programs if it's not already there
        if (!_savedPrograms.contains(_currentProgram)) {
          _savedPrograms.add(_currentProgram!);
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Punch card saved')));
    }
  }

  void _addInstruction() {
    if (_currentProgram == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Instruction'),
        content: AddInstructionDialog(
          onAdd: (instruction) {
            setState(() {
              _currentProgram = PunchCardProgram(
                title: _currentProgram!.title,
                instructions: [
                  ..._currentProgram!.instructions,
                  instruction,
                ],
              );
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _deleteInstruction(int index) {
    if (_currentProgram == null) return;

    setState(() {
      final newInstructions = List<PunchCardInstruction>.from(
        _currentProgram!.instructions,
      );
      newInstructions.removeAt(index);
      _currentProgram = PunchCardProgram(
        title: _currentProgram!.title,
        instructions: newInstructions,
      );
    });
  }

  void _editInstruction(int index) {
    if (_currentProgram == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Instruction'),
        content: AddInstructionDialog(
          initialInstruction: _currentProgram!.instructions[index],
          onAdd: (instruction) {
            setState(() {
              final newInstructions = List<PunchCardInstruction>.from(
                _currentProgram!.instructions,
              );
              newInstructions[index] = instruction;
              _currentProgram = PunchCardProgram(
                title: _currentProgram!.title,
                instructions: newInstructions,
              );
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _deleteSavedProgram(int index) {
    setState(() {
      _savedPrograms.removeAt(index);
      if (_currentProgram == _savedPrograms[index]) {
        _currentProgram = null;
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card deleted')));
  }

  void _duplicateProgram(PunchCardProgram program) {
    setState(() {
      final newProgram = PunchCardProgram(
        title: '${program.title} (Copy)',
        instructions: List.from(program.instructions),
      );
      _savedPrograms.add(newProgram);
      _currentProgram = newProgram;
      _titleController.text = newProgram.title;
      // Update punched holes for direct mode
      for (var row in _punchedHoles) {
        row.fillRange(0, row.length, false);
      }
      for (var instruction in newProgram.instructions) {
        for (var row in instruction.rows) {
          _punchedHoles[row][instruction.column - 1] = true;
        }
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card duplicated')));
  }

  Future<void> _processAiInput() async {
    // TODO: Implement AI processing
    // This would convert natural language to punch card instructions
    final String input = _aiInputController.text;
    if (input.isEmpty) return;

    // For now, we'll just create a dummy instruction
    setState(() {
      _currentProgram = PunchCardProgram(
        title: _titleController.text,
        instructions: [
          ..._currentProgram!.instructions,
          PunchCardInstruction(
            column: 1,
            rows: [0, 1],
            operation: 'DATA',
            parameters: {'value': input},
          ),
        ],
      );
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text processed into punch card instructions'),
      ),
    );
  }

  Widget _buildAiInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Natural Language Input',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Describe what you want the punch card to do, and AI will convert it to instructions.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _aiInputController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Add the numbers in columns 1 and 2, then store the result in column 3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _processAiInput,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Process Text'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditorBottomSheet(
    BuildContext context, {
    PunchCardProgram? program,
  }) {
    setState(() {
      if (program != null) {
        _currentProgram = program;
        _titleController.text = program.title;
        // Update punched holes for direct mode
        for (var row in _punchedHoles) {
          row.fillRange(0, row.length, false);
        }
        for (var instruction in program.instructions) {
          for (var row in instruction.rows) {
            _punchedHoles[row][instruction.column - 1] = true;
          }
        }
      } else {
        _titleController.text = 'New Punch Card';
        _currentProgram = PunchCardProgram(
          title: _titleController.text,
          instructions: [],
        );
        // Reset punched holes for direct mode
        for (var row in _punchedHoles) {
          row.fillRange(0, row.length, false);
        }
      }
      _currentMode = EditorMode.directPunch;
      _aiInputController.clear();
      _isPreviewExpanded = false;
    });

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => Dialog.fullscreen(
        child: StatefulBuilder(
          builder: (context, setDialogState) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                program != null ? 'Edit Punch Card' : 'New Punch Card',
              ),
              actions: [
                // Clear Card button
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Card'),
                        content: const Text(
                          'Are you sure you want to clear this card? '
                          'This will remove all punched holes and instructions.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              setDialogState(() {
                                // Reset punched holes
                                for (var row in _punchedHoles) {
                                  row.fillRange(0, row.length, false);
                                }
                                // Reset instructions
                                _currentProgram = PunchCardProgram(
                                  title: _titleController.text,
                                  instructions: [],
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Card cleared')),
                              );
                            },
                            style: FilledButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                // Delete Card button (only show for existing cards)
                if (program != null) ...[
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Card'),
                          content: Text(
                            'Are you sure you want to delete "${program.title}"? '
                            'This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                final index = _savedPrograms.indexOf(program);
                                if (index != -1) {
                                  Navigator.pop(context); // Close editor
                                  _deleteSavedProgram(index);
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Save Card button
                FilledButton.icon(
                  onPressed: () {
                    _saveProgram();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Card Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<EditorMode>(
                        segments: const [
                          ButtonSegment<EditorMode>(
                            value: EditorMode.directPunch,
                            label: Text('Direct Punch'),
                            icon: Icon(Icons.grid_on),
                          ),
                          ButtonSegment<EditorMode>(
                            value: EditorMode.instructions,
                            label: Text('Instructions'),
                            icon: Icon(Icons.code),
                          ),
                          ButtonSegment<EditorMode>(
                            value: EditorMode.aiText,
                            label: Text('AI Input'),
                            icon: Icon(Icons.auto_awesome),
                          ),
                        ],
                        selected: {_currentMode},
                        onSelectionChanged: (Set<EditorMode> newSelection) {
                          setDialogState(() {
                            _currentMode = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => _analyzeWithAI(setDialogState),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.psychology),
                        label: Text(
                            _isAnalyzing ? 'Analyzing...' : 'Analyze by AI'),
                      ),
                      if (_currentMode == EditorMode.instructions)
                        FilledButton.icon(
                          onPressed: _addInstruction,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Instruction'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildEditorContent(ScrollController()),
                ),
                if (_currentProgram!.instructions.isNotEmpty)
                  _buildPreviewPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorContent(ScrollController scrollController) {
    switch (_currentMode) {
      case EditorMode.instructions:
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          itemCount: _currentProgram!.instructions.length,
          itemBuilder: (context, index) {
            final instruction = _currentProgram!.instructions[index];
            return Card(
              child: ListTile(
                title: Text('Column ${instruction.column}'),
                subtitle: Text(
                  'Operation: ${instruction.operation}\n'
                  'Rows: ${instruction.rows.join(", ")}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editInstruction(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteInstruction(index),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case EditorMode.directPunch:
        return _buildDirectPunchEditor();
      case EditorMode.aiText:
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: _buildAiInputView(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDirectPunchEditor() {
    // Calculate the row height based on the hole size and padding
    const double holeSize = 24.0;
    const double rowHeight = holeSize + 8.0; // 4px padding top and bottom
    const double headerHeight = 32.0;
    const double labelWidth = 50.0;
    const double totalWidth = 80 * holeSize; // Width for all 80 columns

    return Container(
      color: Colors.yellow[50],
      child: Row(
        children: [
          // Fixed row labels column
          SizedBox(
            width: labelWidth,
            child: Column(
              children: [
                // Fixed "Row" header
                Container(
                  height: headerHeight,
                  color: Colors.yellow[200],
                  alignment: Alignment.center,
                  child: const Text(
                    'Row',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.black26),
                // Fixed row labels
                ...List.generate(
                  12,
                  (row) => Container(
                    height: rowHeight,
                    color: Colors.yellow[200],
                    alignment: Alignment.center,
                    child: Text(
                      row <= 1 ? (row == 0 ? 'Y' : 'X') : '${row - 2}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Column(
                  children: [
                    // Column numbers header
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: List.generate(
                          80,
                          (col) => SizedBox(
                            width: holeSize,
                            child: Center(
                              child: Text(
                                '${col + 1}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black26),
                    // Punch holes grid
                    ...List.generate(
                      12,
                      (row) => StatefulBuilder(
                        builder: (context, setPunchState) => Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: row % 2 == 0
                                ? Colors.yellow[50]
                                : Colors.yellow[100],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.yellow[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: List.generate(
                              80,
                              (col) => SizedBox(
                                width: holeSize,
                                height: holeSize,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setPunchState(() {
                                        _toggleHole(row, col);
                                      });
                                    },
                                    child: Container(
                                      width: holeSize - 8,
                                      height: holeSize - 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _punchedHoles[row][col]
                                            ? Colors.black87
                                            : Colors.white,
                                        border: Border.all(
                                          color: Colors.black54,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardsView() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Punch Cards',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    if (_savedPrograms.length > 1)
                      Tooltip(
                        message: 'Shake your device to shuffle cards!',
                        child: IconButton.filled(
                          onPressed: _shuffleCards,
                          icon: const Icon(Icons.shuffle),
                        ),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _showEditorBottomSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Card'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _savedPrograms.isEmpty
                ? _buildEmptyState()
                : AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateZ(_isShuffling
                              ? math.sin(_shakeController.value * math.pi * 4) *
                                  0.02
                              : 0),
                        alignment: Alignment.center,
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _savedPrograms.length,
                          onReorder: _handleReorder,
                          itemBuilder: (context, index) {
                            final program = _savedPrograms[index];
                            return Dismissible(
                              key: ValueKey(program),
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 16.0),
                                child: const Icon(Icons.copy_all,
                                    color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16.0),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  // Delete action
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Card'),
                                      content: Text(
                                        'Are you sure you want to delete "${program.title}"? '
                                        'This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Duplicate action
                                  _duplicateProgram(program);
                                  return false;
                                }
                              },
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  _deleteSavedProgram(index);
                                }
                              },
                              child: _buildCardContent(
                                context,
                                program,
                                index,
                                isSpinning: _isShuffling,
                                isDragging: false,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    PunchCardProgram program,
    int index, {
    bool isSpinning = false,
    bool isDragging = false,
  }) {
    if (_isShuffling) {
      // During shuffling, apply random rotations and translations
      final rotation = _random.nextDouble() * 0.3 - 0.15;
      final offsetX = _random.nextDouble() * 100 - 50;
      final offsetY = _random.nextDouble() * 50;

      return TweenAnimationBuilder(
        key: _cardKeys.length > index ? _cardKeys[index] : null,
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 1000 + _random.nextInt(500)),
        curve: Curves.bounceOut,
        builder: (context, double value, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateZ(rotation * value)
              ..translate(offsetX * value, offsetY * value),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: _buildBaseCard(context, program, index, isSpinning, isDragging),
      );
    }

    return _buildBaseCard(context, program, index, isSpinning, isDragging);
  }

  Widget _buildBaseCard(
    BuildContext context,
    PunchCardProgram program,
    int index,
    bool isSpinning,
    bool isDragging,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isDragging ? 0 : 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEditorBottomSheet(context, program: program),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Card number with shake effect during shuffling
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: _isShuffling
                          ? TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: math.sin(value * math.pi * 4) * 0.1,
                                  child: child,
                                );
                              },
                              child: SegmentedNumber(
                                number: index + 1,
                                size: 32,
                                isSpinning: isSpinning,
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                                inactiveColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(128),
                              ),
                            )
                          : SegmentedNumber(
                              number: index + 1,
                              size: 32,
                              isSpinning: isSpinning,
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(128),
                            ),
                    ),
                    // Mini preview
                    Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PunchCardSvgViewer(
                          svgString: _svgGenerator.generateSvg(program),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Card info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${program.instructions.length} instructions',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    if (!isDragging) ...[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditorBottomSheet(context, program: program),
                        tooltip: 'Edit Card',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Card'),
                              content: Text(
                                'Are you sure you want to delete "${program.title}"? '
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteSavedProgram(index);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete Card',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildSavedCardsView(),
          ),
          if (_currentProgram != null &&
              _currentProgram!.instructions.isNotEmpty)
            _buildPreviewPanel(),
        ],
      ),
    );
  }

  Future<void> _analyzeWithAI(StateSetter setState) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Convert current punch card state to operations
      final operations = _currentProgram?.getOperations() ?? [];

      // Call AI service for analysis
      final analysis = await AiService().analyzePunchCard(
        title: _currentProgram?.title ?? 'Untitled',
        operations: operations,
        context: context,
      );

      // Show analysis in dialog
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
                          Icons.psychology,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Analysis',
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
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.copyWith(
                                bodyMedium:
                                    Theme.of(context).textTheme.bodyLarge,
                              ),
                        ),
                        child: Markdown(
                          data: analysis,
                          selectable: true,
                          onTapLink: (text, href, title) async {
                            if (href != null) {
                              final uri = Uri.parse(href);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          styleSheet: MarkdownStyleSheet(
                            h1: Theme.of(context).textTheme.headlineMedium,
                            h2: Theme.of(context).textTheme.headlineSmall,
                            h3: Theme.of(context).textTheme.titleLarge,
                            h4: Theme.of(context).textTheme.titleMedium,
                            h5: Theme.of(context).textTheme.titleSmall,
                            h6: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            p: Theme.of(context).textTheme.bodyLarge,
                            code: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(128),
                                ),
                            codeblockDecoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(128),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            blockquote:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Copy to clipboard
                            Clipboard.setData(ClipboardData(text: analysis));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analysis copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
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

      setState(() {
        _aiAnalysis = analysis;
      });
    } catch (e) {
      setState(() {
        _aiAnalysis = 'Error during analysis: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Widget _buildPreviewPanel() {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.zero,
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) => ListTile(
            leading: const Icon(Icons.preview),
            title: const Text('Preview'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Punch Card Preview',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: PunchCardSvgViewer(
                                    svgString: _svgGenerator.generateSvg(
                                      _currentProgram!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PunchCardSvgViewer(
                svgString: _svgGenerator.generateSvg(_currentProgram!),
              ),
            ),
          ),
          isExpanded: _isPreviewExpanded,
          canTapOnHeader: true,
        ),
      ],
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {
          _isPreviewExpanded = !isExpanded;
        });
      },
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (!_isShuffling) {
      setState(() {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = _savedPrograms.removeAt(oldIndex);
        _savedPrograms.insert(newIndex, item);
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved cards yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new card to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AddInstructionDialog extends StatefulWidget {
  final Function(PunchCardInstruction) onAdd;
  final PunchCardInstruction? initialInstruction;

  const AddInstructionDialog({
    super.key,
    required this.onAdd,
    this.initialInstruction,
  });

  @override
  State<AddInstructionDialog> createState() => _AddInstructionDialogState();
}

class _AddInstructionDialogState extends State<AddInstructionDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _column;
  final List<int> _selectedRows = [];
  String _operation = 'PRINT';
  final Map<String, dynamic> _parameters = {'value': ''};

  final List<String> _operations = [
    'PRINT',
    'LOAD',
    'STORE',
    'ADD',
    'SUB',
    'MUL',
    'DIV',
    'JMP',
    'JZ',
    'JN',
    'DATA',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialInstruction != null) {
      _column = widget.initialInstruction!.column;
      _selectedRows.addAll(widget.initialInstruction!.rows);
      _operation = widget.initialInstruction!.operation;
      _parameters.addAll(widget.initialInstruction!.parameters);
    } else {
      _column = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column number
            TextFormField(
              initialValue: _column.toString(),
              decoration: const InputDecoration(
                labelText: 'Column (1-80)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a column number';
                }
                final number = int.tryParse(value);
                if (number == null || number < 1 || number > 80) {
                  return 'Please enter a number between 1 and 80';
                }
                return null;
              },
              onSaved: (value) {
                _column = int.parse(value!);
              },
            ),
            const SizedBox(height: 16),
            // Operation dropdown
            DropdownButtonFormField<String>(
              value: _operation,
              decoration: const InputDecoration(
                labelText: 'Operation',
                border: OutlineInputBorder(),
              ),
              items: _operations.map((String operation) {
                return DropdownMenuItem<String>(
                  value: operation,
                  child: Text(operation),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _operation = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Rows selection
            const Text('Select Rows (Y=0, X=1, 0-9=2-11)'),
            Wrap(
              spacing: 8,
              children: List.generate(12, (index) {
                final label =
                    index <= 1 ? (index == 0 ? 'Y' : 'X') : '${index - 2}';
                return FilterChip(
                  label: Text(label),
                  selected: _selectedRows.contains(index),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedRows.add(index);
                      } else {
                        _selectedRows.remove(index);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            // Parameters
            TextFormField(
              initialValue: _parameters['value'].toString(),
              decoration: const InputDecoration(
                labelText: 'Parameter Value',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) {
                _parameters['value'] = value ?? '';
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _selectedRows.isNotEmpty) {
                      _formKey.currentState!.save();
                      widget.onAdd(
                        PunchCardInstruction(
                          column: _column,
                          rows: _selectedRows,
                          operation: _operation,
                          parameters: _parameters,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
