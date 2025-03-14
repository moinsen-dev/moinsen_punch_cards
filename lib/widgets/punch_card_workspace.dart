import 'package:flutter/material.dart';

import '../punchcard_generator.dart';

class PunchCardWorkspace extends StatefulWidget {
  final PunchCardProgram? initialProgram;
  final Function(PunchCardProgram)? onProgramChanged;
  final bool showAiAnalysis;
  final bool readOnly;
  final bool showPreview;
  final bool showTitle;

  const PunchCardWorkspace({
    super.key,
    this.initialProgram,
    this.onProgramChanged,
    this.showAiAnalysis = true,
    this.readOnly = false,
    this.showPreview = true,
    this.showTitle = true,
  });

  @override
  State<PunchCardWorkspace> createState() => _PunchCardWorkspaceState();
}

class _PunchCardWorkspaceState extends State<PunchCardWorkspace> {
  late PunchCardProgram _currentProgram;
  final TextEditingController _titleController = TextEditingController();
  final PunchCardSvgGenerator _svgGenerator = PunchCardSvgGenerator();
  bool _isPreviewExpanded = false;
  final bool _isAnalyzing = false;

  // For direct punch mode
  final List<List<bool>> _punchedHoles = List.generate(
    12, // 12 rows (Y, X, 0-9)
    (i) => List.generate(80, (j) => false), // 80 columns
  );

  @override
  void initState() {
    super.initState();
    _currentProgram = widget.initialProgram ??
        PunchCardProgram(
          title: 'New Program',
          instructions: [],
        );
    _titleController.text = _currentProgram.title;
    _updatePunchedHoles();
  }

  void _updatePunchedHoles() {
    // Reset holes
    for (var row in _punchedHoles) {
      row.fillRange(0, row.length, false);
    }
    // Set holes based on instructions
    for (var instruction in _currentProgram.instructions) {
      for (var row in instruction.rows) {
        _punchedHoles[row][instruction.column - 1] = true;
      }
    }
  }

  void _toggleHole(int row, int column) {
    if (widget.readOnly) return;

    setState(() {
      _punchedHoles[row][column] = !_punchedHoles[row][column];
      _updateProgramFromHoles();
    });
  }

  void _updateProgramFromHoles() {
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

    widget.onProgramChanged?.call(_currentProgram);
  }

  Widget _buildDirectPunchEditor() {
    // Calculate the row height based on the hole size and padding
    const double holeSize = 24.0;
    const double rowHeight = holeSize + 8.0; // 4px padding top and bottom
    const double headerHeight = 32.0;
    const double labelWidth = 50.0;
    const double totalWidth = 80 * holeSize; // Width for all 80 columns

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6), // Light yellow background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE6B800).withOpacity(0.5), // Darker yellow border
        ),
      ),
      child: Column(
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Program Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _currentProgram = PunchCardProgram(
                    title: value,
                    instructions: _currentProgram.instructions,
                  );
                  widget.onProgramChanged?.call(_currentProgram);
                },
                readOnly: widget.readOnly,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF7CC), // Lighter yellow for grid background
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE680), // Yellow header
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Row',
                          style: TextStyle(
                            color: Color(0xFF806600), // Dark yellow text
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Fixed row labels
                      ...List.generate(
                        12,
                        (row) => Container(
                          height: rowHeight,
                          color: row % 2 == 0
                              ? const Color(
                                  0xFFFFF7CC) // Alternating row colors
                              : const Color(0xFFFFF2B3),
                          alignment: Alignment.center,
                          child: Text(
                            row <= 1 ? (row == 0 ? 'Y' : 'X') : '${row - 2}',
                            style: const TextStyle(
                              color: Color(0xFF806600), // Dark yellow text
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
                          Container(
                            height: headerHeight,
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Row(
                              children: List.generate(
                                80,
                                (col) => SizedBox(
                                  width: holeSize,
                                  child: Center(
                                    child: Text(
                                      '${col + 1}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          // Punch holes grid
                          ...List.generate(
                            12,
                            (row) => StatefulBuilder(
                              builder: (context, setPunchState) => Container(
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  color: row % 2 == 0
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.1)
                                      : Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.2),
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
                                                  ? const Color(
                                                      0xFFFFCC00) // Punched hole color
                                                  : Colors.white,
                                              border: Border.all(
                                                color: const Color(
                                                    0xFFE6B800), // Hole border color
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
          ),
          if (widget.showPreview && _currentProgram.instructions.isNotEmpty)
            _buildPreviewPanel(),
        ],
      ),
    );
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
                                      _currentProgram,
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
                svgString: _svgGenerator.generateSvg(_currentProgram),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDirectPunchEditor(),
        if (widget.showPreview && _currentProgram.instructions.isNotEmpty)
          _buildPreviewPanel(),
      ],
    );
  }
}
