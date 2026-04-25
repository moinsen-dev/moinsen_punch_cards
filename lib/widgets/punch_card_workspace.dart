import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _PunchCardWorkspaceState extends State<PunchCardWorkspace>
    with TickerProviderStateMixin {
  late PunchCardProgram _currentProgram;
  final TextEditingController _titleController = TextEditingController();
  final PunchCardSvgGenerator _svgGenerator = PunchCardSvgGenerator();
  bool _isPreviewExpanded = false;

  final List<List<bool>> _punchedHoles = List.generate(
    12,
    (i) => List.generate(80, (j) => false),
  );

  final List<List<double>> _holeScales = List.generate(
    12,
    (i) => List.generate(80, (j) => 1.0),
  );

  final List<List<Color?>> _holeFlashColors = List.generate(
    12,
    (i) => List.generate(80, (j) => null),
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
    for (var row in _punchedHoles) {
      row.fillRange(0, row.length, false);
    }
    for (var instruction in _currentProgram.instructions) {
      for (var row in instruction.rows) {
        _punchedHoles[row][instruction.column - 1] = true;
      }
    }
  }

  void _toggleHole(int row, int column) {
    if (widget.readOnly) return;

    final wasPunched = _punchedHoles[row][column];
    HapticFeedback.lightImpact();

    setState(() {
      _punchedHoles[row][column] = !wasPunched;
      _updateProgramFromHoles();
    });

    _animatePunch(row, column, wasPunched);
  }

  void _animatePunch(int row, int col, bool wasPunched) {
    setState(() {
      _holeScales[row][col] = 0.0;
      _holeFlashColors[row][col] =
          wasPunched ? Colors.white.withAlpha(100) : Colors.black.withAlpha(60);
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() {
        _holeScales[row][col] = 1.15;
      });
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _holeScales[row][col] = 1.0;
        _holeFlashColors[row][col] = null;
      });
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
    const double holeSize = 24.0;
    const double rowHeight = holeSize + 8.0;
    const double headerHeight = 32.0;
    const double labelWidth = 50.0;
    const double totalWidth = 80 * holeSize;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2518) : const Color(0xFFFFFBE6);
    final gridBg =
        isDark ? const Color(0xFF1E1A12) : const Color(0xFFFFF7CC);
    final headerBg =
        isDark ? const Color(0xFF3D3522) : const Color(0xFFFFE680);
    final rowEven = isDark ? const Color(0xFF252015) : const Color(0xFFFFF7CC);
    final rowOdd = isDark ? const Color(0xFF302A1C) : const Color(0xFFFFF2B3);
    final labelText =
        isDark ? const Color(0xFFD4C48A) : const Color(0xFF806600);
    final borderColor =
        isDark ? const Color(0xFF5A4E30) : const Color(0xFFE6B800);
    final holePunched =
        isDark ? const Color(0xFFFFCC00) : const Color(0xFFFFCC00);
    final holeUnpunched = isDark ? const Color(0xFF1A1610) : Colors.white;
    final holeBorder =
        isDark ? const Color(0xFF6B5F3A) : const Color(0xFFE6B800);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
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
              color: gridBg,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: headerBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Row',
                          style: TextStyle(
                            color: labelText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ...List.generate(
                        12,
                        (row) => Container(
                          height: rowHeight,
                          color: row % 2 == 0 ? rowEven : rowOdd,
                          alignment: Alignment.center,
                          child: Text(
                            row <= 1 ? (row == 0 ? 'Y' : 'X') : '${row - 2}',
                            style: TextStyle(
                              color: labelText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: Column(
                        children: [
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
                          ...List.generate(
                            12,
                            (row) => StatefulBuilder(
                              builder: (context, setPunchState) => Container(
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  color: row % 2 == 0 ? rowEven : rowOdd,
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
                                          child: MouseRegion(
                                            cursor: widget.readOnly
                                                ? MouseCursor.defer
                                                : SystemMouseCursors.click,
                                            child: AnimatedScale(
                                              scale: _holeScales[row][col],
                                              duration: const Duration(
                                                  milliseconds: 120),
                                              curve: Curves.easeOutCubic,
                                              child: Container(
                                                width: holeSize - 8,
                                                height: holeSize - 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _punchedHoles[row][col]
                                                      ? holePunched
                                                      : holeUnpunched,
                                                  border: Border.all(
                                                    color: holeBorder,
                                                    width: 1,
                                                  ),
                                                  boxShadow:
                                                      _holeFlashColors[row]
                                                                  [col] !=
                                                              null
                                                          ? [
                                                              BoxShadow(
                                                                color: _holeFlashColors[
                                                                        row]
                                                                    [col]!,
                                                                blurRadius: 4,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : null,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDirectPunchEditor(),
          if (widget.showPreview && _currentProgram.instructions.isNotEmpty)
            _buildPreviewPanel(),
        ],
      ),
    );
  }
}
