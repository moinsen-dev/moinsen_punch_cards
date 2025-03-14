import 'package:flutter/material.dart';

import '../punchcard_generator.dart';
import '../services/settings_service.dart';
import '../widgets/segmented_number.dart';

enum EditorMode { instructions, directPunch, aiText, savedCards }

class PunchCardEditor extends StatefulWidget {
  final SettingsService settingsService;

  const PunchCardEditor({super.key, required this.settingsService});

  @override
  State<PunchCardEditor> createState() => _PunchCardEditorState();
}

class _PunchCardEditorState extends State<PunchCardEditor> {
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

  @override
  void dispose() {
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
                      const SizedBox(height: 16),
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
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: PunchCardSvgViewer(
                              svgString: _svgGenerator.generateSvg(
                                _currentProgram!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                FilledButton.icon(
                  onPressed: () => _showEditorBottomSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Card'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _savedPrograms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(50),
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
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _savedPrograms.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _savedPrograms.removeAt(oldIndex);
                        _savedPrograms.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final program = _savedPrograms[index];
                      return Dismissible(
                        key: ValueKey(program),
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16.0),
                          child:
                              const Icon(Icons.copy_all, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
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
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
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
                        child: StatefulBuilder(
                          builder: (context, setCardState) {
                            bool isSpinning = false;
                            return Draggable(
                              maxSimultaneousDrags: 1,
                              onDragStarted: () =>
                                  setCardState(() => isSpinning = true),
                              onDragEnd: (_) =>
                                  setCardState(() => isSpinning = false),
                              onDraggableCanceled: (_, __) =>
                                  setCardState(() => isSpinning = false),
                              feedback: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width - 32,
                                  child: _buildCardContent(
                                    context,
                                    program,
                                    index,
                                    isSpinning: true,
                                    isDragging: true,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildCardContent(
                                  context,
                                  program,
                                  index,
                                  isSpinning: isSpinning,
                                  isDragging: false,
                                ),
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
                    // Card number
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: SegmentedNumber(
                        number: index + 1,
                        size: 32,
                        isSpinning: isSpinning,
                        activeColor: Theme.of(context).colorScheme.primary,
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
    return Scaffold(body: _buildSavedCardsView());
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
