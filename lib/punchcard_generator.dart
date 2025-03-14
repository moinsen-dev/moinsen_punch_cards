import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'services/settings_service.dart';

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
  final String title;
  final List<PunchCardInstruction> instructions;
  final int maxColumns;
  final int maxRows;

  PunchCardProgram({
    required this.title,
    required this.instructions,
    this.maxColumns = 80,
    this.maxRows = 12,
  });

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
        final x = 40 + (instruction.column * 9); // Adjust spacing as needed
        final y = 80 + (row * 20); // Adjust based on row spacing
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

  /// Helper to add row labels to the SVG
  void _addRowLabels(StringBuffer buffer) {
    final rowLabels = [
      'Y',
      'X',
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];
    for (int i = 0; i < rowLabels.length; i++) {
      final y = 80 + (i * 20); // Adjust spacing as needed
      buffer.writeln(
        '  <text x="25" y="$y" font-family="Courier New" font-size="10" text-anchor="end" fill="#666">${rowLabels[i]}</text>',
      );
    }
  }

  /// Helper to add card grid lines to the SVG
  void _addCardGrid(StringBuffer buffer) {
    buffer.writeln('  <g stroke="#ccc" stroke-width="0.5">');
    // Horizontal lines
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

  /// Converts an SVG string to a PNG image
  Future<Uint8List> svgToPng(
    String svgString, {
    int width = 800,
    int height = 300,
  }) async {
    // This would need a more complex implementation in a real app
    // For demonstration, we're showing the general approach

    // In a real implementation, you might use:
    // 1. A native plugin that supports SVG-to-PNG conversion
    // 2. A server-side API that handles the conversion
    // 3. A web-based approach using Flutter web capabilities

    // For simplicity, this is a placeholder that would need to be replaced
    // with a real implementation in a production app
    throw UnimplementedError(
      'SVG to PNG conversion needs platform-specific implementation',
    );
  }
}

/// Service for generating punch card programs using LLM
class PunchCardProgramGenerator {
  final String openAiApiKey;

  PunchCardProgramGenerator({required this.openAiApiKey});

  /// Generates a punch card program from text input using OpenAI
  Future<PunchCardProgram> generateProgramFromText(String text) async {
    // Create a prompt for the LLM
    final prompt = '''
    Convert the following text into a punch card program using the format:

    Each instruction should have:
    - A column number (1-80)
    - Row numbers to punch (0-11, where 0=Y row, 1=X row, 2-11=rows 0-9)
    - Operation name
    - Any relevant parameters

    Text to convert: "$text"

    Return the response in the following JSON format:
    {
      "title": "Program title",
      "instructions": [
        {
          "column": column_number,
          "rows": [row_numbers],
          "operation": "operation_name",
          "parameters": {"param_name": param_value}
        },
        ...more instructions...
      ]
    }
    ''';

    try {
      // Call OpenAI API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a punch card programming expert.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        // Parse response
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];

        // Extract JSON from the response
        final programJson = _extractJsonFromText(content);
        return _parseProgramJson(programJson);
      } else {
        throw Exception('Failed to generate program: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating program: $e');
    }
  }

  /// Extracts JSON from LLM response text
  Map<String, dynamic> _extractJsonFromText(String text) {
    // Find JSON in the response - the LLM might add explanation text
    final jsonRegExp = RegExp(r'{[\s\S]*}');
    final match = jsonRegExp.firstMatch(text);

    if (match != null) {
      final jsonStr = match.group(0);
      try {
        return jsonDecode(jsonStr!);
      } catch (e) {
        throw Exception('Failed to parse JSON from response: $e');
      }
    } else {
      throw Exception('No JSON found in response');
    }
  }

  /// Parses the JSON response into a PunchCardProgram
  PunchCardProgram _parseProgramJson(Map<String, dynamic> json) {
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
}

/// Service for batch-generating multiple punch card images
class PunchCardBatchGenerator {
  final PunchCardProgramGenerator programGenerator;
  final PunchCardSvgGenerator svgGenerator;

  PunchCardBatchGenerator({
    required this.programGenerator,
    required this.svgGenerator,
  });

  /// Generates multiple punch card SVGs from a list of input texts
  Future<List<String>> generateSvgBatch(List<String> inputTexts) async {
    final svgFiles = <String>[];

    for (int i = 0; i < inputTexts.length; i++) {
      final program = await programGenerator.generateProgramFromText(
        inputTexts[i],
      );
      final svg = svgGenerator.generateSvg(program);
      final filePath = await svgGenerator.saveSvgToFile(
        svg,
        'punchcard_${i + 1}',
      );
      svgFiles.add(filePath);
    }

    return svgFiles;
  }

  /// Generates multiple punch card PNGs from a list of input texts
  Future<List<Uint8List>> generatePngBatch(List<String> inputTexts) async {
    final pngImages = <Uint8List>[];

    for (final text in inputTexts) {
      final program = await programGenerator.generateProgramFromText(text);
      final svg = svgGenerator.generateSvg(program);
      final png = await svgGenerator.svgToPng(svg);
      pngImages.add(png);
    }

    return pngImages;
  }
}

/// Manual program builder for direct instruction creation
class PunchCardProgramBuilder {
  final String title;
  final List<PunchCardInstruction> instructions = [];

  PunchCardProgramBuilder(this.title);

  /// Helper for ASCII character punch card generation
  void addCharacter(int column, String char) {
    // Store character value (simplified encoding)
    instructions.add(
      PunchCardInstruction(
        column: column,
        rows: [10, 11], // Row 8 (DATA) and Row 9 (value encoding)
        operation: 'DATA',
        parameters: {'value': char.codeUnitAt(0)},
      ),
    );

    // Print the character
    instructions.add(
      PunchCardInstruction(
        column: column + 1,
        rows: [0, 11], // Row Y (PRINT) and Row 9 (address)
        operation: 'PRINT',
        parameters: {'address': column},
      ),
    );
  }

  /// Helper to add numeric operations
  void addOperation(int column, String operation, int address) {
    // Map operation name to row
    final Map<String, int> operationRows = {
      'PRINT': 0, // Y row
      'LOAD': 1, // X row
      'STORE': 2, // 0 row
      'ADD': 3, // 1 row
      'SUB': 4, // 2 row
      'MUL': 5, // 3 row
      'DIV': 6, // 4 row
      'JMP': 7, // 5 row
      'JZ': 8, // 6 row
      'JN': 9, // 7 row
    };

    if (!operationRows.containsKey(operation)) {
      throw ArgumentError('Unknown operation: $operation');
    }

    // Add the instruction
    instructions.add(
      PunchCardInstruction(
        column: column,
        rows: [
          operationRows[operation]!,
          11,
        ], // Operation row and address encoding
        operation: operation,
        parameters: {'address': address},
      ),
    );
  }

  /// Builds the punch card program
  PunchCardProgram build() {
    return PunchCardProgram(
      title: title,
      instructions: List.from(instructions), // Create a defensive copy
    );
  }
}

// Example usage for creating a "Hello World" program manually
PunchCardProgram createHelloWorldProgram() {
  final builder = PunchCardProgramBuilder('HELLO WORLD PROGRAM');

  // Add each character of "Hello World!" to the punch card
  const message = 'Hello World!';
  for (int i = 0; i < message.length; i++) {
    builder.addCharacter(i * 2 + 1, message[i]);
  }

  return builder.build();
}

// Example implementation of a Flutter widget to display a punch card SVG
class PunchCardSvgViewer extends StatelessWidget {
  final String svgString;

  const PunchCardSvgViewer({super.key, required this.svgString});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(svgString, width: 800, height: 300);
  }
}

// Example usage in a Flutter app
class PunchCardGeneratorApp extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const PunchCardGeneratorApp({super.key, this.onThemeChanged});

  @override
  State<PunchCardGeneratorApp> createState() => _PunchCardGeneratorAppState();
}

class _PunchCardGeneratorAppState extends State<PunchCardGeneratorApp> {
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;
  late SettingsService _settingsService;
  String? _generatedSvg;
  String? _savedFilePath;
  final GlobalKey _punchCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = await SettingsService.create();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generatePunchCard() async {
    if (_textController.text.isEmpty) return;

    final apiKey = _settingsService.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please set your Gemini API key in settings first';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedSvg = null;
    });

    try {
      // Initialize Gemini with Flash-Lite model
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      // Create the prompt for generating punch card instructions
      final prompt = '''
      Convert the following text into a punch card program using the format:
      Each instruction should have:
      - A column number (1-80)
      - Row numbers to punch (0-11, where 0=Y row, 1=X row, 2-11=rows 0-9)
      - Operation name
      - Any relevant parameters

      Important rules:
      1. Each character should use 2 columns: one for storing the character and one for the print operation
      2. Use rows Y (0) for PRINT operations
      3. Use rows X (1) for LOAD operations
      4. Use rows 0-9 (2-11) for data and parameters
      5. Keep track of column positions to avoid overlap

      Text to convert: "${_textController.text}"

      Return the response in the following JSON format:
      {
        "title": "Program title",
        "instructions": [
          {
            "column": column_number,
            "rows": [row_numbers],
            "operation": "operation_name",
            "parameters": {"param_name": param_value}
          }
        ]
      }
      ''';

      // Generate response using Gemini
      final content = await model.generateContent([Content.text(prompt)]);
      final response = content.text;

      if (response == null) {
        throw Exception('Failed to generate response');
      }

      // Parse the JSON response
      final programJson = _extractJsonFromText(response);
      final program = _parseProgramJson(programJson);

      // Generate SVG
      final generator = PunchCardSvgGenerator();
      final svg = generator.generateSvg(program);

      setState(() {
        _generatedSvg = svg;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating punch card: $e';
        _isGenerating = false;
      });
    }
  }

  Map<String, dynamic> _extractJsonFromText(String text) {
    final jsonRegExp = RegExp(r'{[\s\S]*}');
    final match = jsonRegExp.firstMatch(text);

    if (match != null) {
      final jsonStr = match.group(0);
      try {
        return jsonDecode(jsonStr!);
      } catch (e) {
        throw Exception('Failed to parse JSON from response: $e');
      }
    } else {
      throw Exception('No JSON found in response');
    }
  }

  PunchCardProgram _parseProgramJson(Map<String, dynamic> json) {
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

  Future<void> _copyToClipboard() async {
    if (_generatedSvg == null) return;

    try {
      Pasteboard.writeText(_generatedSvg!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SVG copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to copy: $e')));
      }
    }
  }

  Future<void> _copyAsImage() async {
    if (_generatedSvg == null) return;

    try {
      setState(() {
        _errorMessage = null;
      });

      // Get the RenderRepaintBoundary
      final boundary = _punchCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to find the punch card widget');
      }

      // Convert to image
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert to PNG');
      }

      // Copy to clipboard
      await Pasteboard.writeImage(byteData.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to copy image: $e';
        });
      }
    }
  }

  Future<void> _saveSvgFile() async {
    if (_generatedSvg == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'punchcard_$timestamp.svg';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(_generatedSvg!);
      _savedFilePath = file.path;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Punch card saved'),
            action: SnackBarAction(label: 'Share', onPressed: _shareSavedFile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _shareSavedFile() async {
    if (_savedFilePath == null) return;

    try {
      await Share.shareXFiles([XFile(_savedFilePath!)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch Card Generator'),
        actions: [
          if (_generatedSvg != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy SVG',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Copy as Image',
              onPressed: _copyAsImage,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save SVG',
              onPressed: _saveSvgFile,
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate a Punch Card',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter text to convert into punch card instructions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to generate punch card',
                border: OutlineInputBorder(),
                hintText: 'Example: HELLO WORLD',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePunchCard,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Punch Card',
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_generatedSvg != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy SVG'),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: _copyAsImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Copy as Image'),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: _saveSvgFile,
                            icon: const Icon(Icons.save),
                            label: const Text('Save SVG'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _punchCardKey,
                        child: PunchCardSvgViewer(svgString: _generatedSvg!),
                      ),
                    ],
                  ),
                ),
              ),
            if (_generatedSvg == null) const Spacer(),
          ],
        ),
      ),
    );
  }
}
