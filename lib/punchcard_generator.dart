import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

/// Domain model for a punch card instruction
class PunchCardInstruction {
  final int column;
  final List<int> rows;
  final String operation;
  final Map<String, dynamic> parameters;

  PunchCardInstruction({
    required this.column,
    required this.rows,
    required this.operation,
    required this.parameters,
  });

  @override
  String toString() {
    return '$operation at column $column (rows: ${rows.join(", ")})';
  }
}

/// Domain model for a punch card program
class PunchCardProgram {
  final String id;
  final String title;
  final List<PunchCardInstruction> instructions;
  final int maxColumns;
  final int maxRows;

  PunchCardProgram({
    String? id,
    required this.title,
    required this.instructions,
    this.maxColumns = 80,
    this.maxRows = 12,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}';

  List<String> getOperations() {
    return instructions.map((instruction) {
      final rowsStr = instruction.rows.join(', ');
      final paramsStr = instruction.parameters.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return 'Column ${instruction.column}: ${instruction.operation} (Rows: $rowsStr, $paramsStr)';
    }).toList();
  }
}

/// Service for generating SVG punch cards
class PunchCardSvgGenerator {
  /// Generates an SVG string for a punch card program
  String generateSvg(PunchCardProgram program) {
    final buffer = StringBuffer();

    // SVG header
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 300">',
    );

    // Card background
    buffer.writeln('  <!-- Card background -->');
    buffer.writeln(
      '  <rect width="800" height="300" fill="#f0e6d2" stroke="#937f5d" stroke-width="2"/>',
    );

    // Card title
    buffer.writeln('  <!-- Card title -->');
    buffer.writeln(
      '  <text x="400" y="30" font-family="Courier New" font-size="20" text-anchor="middle" fill="#333">${program.title}</text>',
    );

    // Column headers
    buffer.writeln('  <!-- Column headers -->');
    buffer.writeln(
      '  <text x="50" y="55" font-family="Courier New" font-size="10" fill="#666">1         10        20        30        40        50        60        70        80</text>',
    );

    // Row labels
    buffer.writeln('  <!-- Row labels -->');
    _addRowLabels(buffer);

    // Card grid
    buffer.writeln('  <!-- Card grid -->');
    _addCardGrid(buffer);

    // Punch holes for instructions
    buffer.writeln('  <!-- Punch holes -->');
    for (final instruction in program.instructions) {
      buffer.writeln(
        '  <!-- ${instruction.operation}: ${instruction.parameters} -->',
      );
      for (final row in instruction.rows) {
        final x = 40 + (instruction.column * 9);
        final y = 80 + (row * 20);
        buffer.writeln('  <circle cx="$x" cy="$y" r="7" fill="#000"/>');
      }
    }

    // Vertical indicators for columns
    buffer.writeln('  <!-- Column indicators -->');
    for (int i = 1; i <= 8; i++) {
      final x = i * 100;
      final label = i * 10;
      buffer.writeln(
        '  <text x="$x" y="60" font-family="Courier New" font-size="8" text-anchor="middle" fill="#666">$label</text>',
      );
    }

    // SVG footer
    buffer.writeln('</svg>');

    return buffer.toString();
  }

  void _addRowLabels(StringBuffer buffer) {
    final rowLabels = ['Y', 'X', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < rowLabels.length; i++) {
      final y = 80 + (i * 20);
      buffer.writeln(
        '  <text x="25" y="$y" font-family="Courier New" font-size="10" text-anchor="end" fill="#666">${rowLabels[i]}</text>',
      );
    }
  }

  void _addCardGrid(StringBuffer buffer) {
    buffer.writeln('  <g stroke="#ccc" stroke-width="0.5">');
    for (int i = 0; i < 12; i++) {
      final y = 70 + (i * 20);
      buffer.writeln('    <line x1="40" y1="$y" x2="760" y2="$y"/>');
    }
    buffer.writeln('  </g>');
  }

  /// Saves the SVG to a file and returns the file path
  Future<String> saveSvgToFile(String svg, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename.svg';
    final file = File(path);
    await file.writeAsString(svg);
    return path;
  }
}

/// Widget to display a punch card SVG
class PunchCardSvgViewer extends StatelessWidget {
  final String svgString;

  const PunchCardSvgViewer({super.key, required this.svgString});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(svgString, width: 800, height: 300);
  }
}

/// Extracts JSON from LLM response text (handles markdown code blocks)
Map<String, dynamic> extractJsonFromText(String text) {
  var jsonStr = text;

  final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  if (codeBlockMatch != null) {
    jsonStr = codeBlockMatch.group(1)!.trim();
  }

  final jsonRegExp = RegExp(r'{[\s\S]*}');
  final match = jsonRegExp.firstMatch(jsonStr);

  if (match != null) {
    try {
      return jsonDecode(match.group(0)!);
    } catch (e) {
      throw Exception('Failed to parse JSON from response: $e');
    }
  } else {
    throw Exception('No JSON found in response');
  }
}

/// Parses the JSON response into a PunchCardProgram
PunchCardProgram parseProgramJson(Map<String, dynamic> json) {
  final instructions = <PunchCardInstruction>[];

  for (final instructionJson in json['instructions']) {
    instructions.add(
      PunchCardInstruction(
        column: instructionJson['column'],
        rows: List<int>.from(instructionJson['rows']),
        operation: instructionJson['operation'],
        parameters: instructionJson['parameters'],
      ),
    );
  }

  return PunchCardProgram(title: json['title'], instructions: instructions);
}
