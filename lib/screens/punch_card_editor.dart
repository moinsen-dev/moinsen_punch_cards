import 'package:flutter/material.dart';

import '../punchcard_generator.dart';
import '../services/settings_service.dart';

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
  EditorMode _currentMode = EditorMode.instructions;
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
      builder:
          (context) => AlertDialog(
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
      builder:
          (context) => AlertDialog(
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
      _currentMode = EditorMode.instructions;
      _aiInputController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder:
                      (context, scrollController) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  program != null
                                      ? 'Edit Punch Card'
                                      : 'New Punch Card',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
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
                                      value: EditorMode.instructions,
                                      label: Text('Instructions'),
                                      icon: Icon(Icons.code),
                                    ),
                                    ButtonSegment<EditorMode>(
                                      value: EditorMode.directPunch,
                                      label: Text('Direct Punch'),
                                      icon: Icon(Icons.grid_on),
                                    ),
                                    ButtonSegment<EditorMode>(
                                      value: EditorMode.aiText,
                                      label: Text('AI Input'),
                                      icon: Icon(Icons.auto_awesome),
                                    ),
                                  ],
                                  selected: {_currentMode},
                                  onSelectionChanged: (
                                    Set<EditorMode> newSelection,
                                  ) {
                                    setModalState(() {
                                      setState(() {
                                        _currentMode = newSelection.first;
                                      });
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
                            child: _buildEditorContent(scrollController),
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () {
                                      _saveProgram();
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text('Save Card'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
        return SingleChildScrollView(
          controller: scrollController,
          child: _buildDirectPunchEditor(),
        );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1600, // Allows for good visibility of the 80 columns
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Column numbers
            Row(
              children: [
                const SizedBox(width: 50), // Space for row labels
                ...List.generate(
                  80,
                  (col) => Expanded(
                    child: Text(
                      '${col + 1}',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Punch grid
            Expanded(
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, row) {
                  String rowLabel =
                      row <= 1 ? (row == 0 ? 'Y' : 'X') : '${row - 2}';
                  return Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          rowLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...List.generate(
                        80,
                        (col) => Expanded(
                          child: InkWell(
                            onTap: () => _toggleHole(row, col),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _punchedHoles[row][col]
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
            child:
                _savedPrograms.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
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
                    : ListView.builder(
                      itemCount: _savedPrograms.length,
                      itemBuilder: (context, index) {
                        final program = _savedPrograms[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.view_column_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(program.title),
                            subtitle: Text(
                              '${program.instructions.length} instructions',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Duplicate',
                                  onPressed: () {
                                    _duplicateProgram(program);
                                    _showEditorBottomSheet(
                                      context,
                                      program: _currentProgram,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed:
                                      () => _showEditorBottomSheet(
                                        context,
                                        program: program,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteSavedProgram(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
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
              items:
                  _operations.map((String operation) {
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
            Text('Select Rows (Y=0, X=1, 0-9=2-11)'),
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
