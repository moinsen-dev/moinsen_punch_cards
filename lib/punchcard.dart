// Punch Card Image Processor
// A Flutter application that processes punch card images and executes their instructions

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

// =============================================================================
// DOMAIN MODELS
// =============================================================================

/// Represents a punch card with its associated data and operations
class PunchCard {
  final Uint8List imageBytes;
  final List<List<bool>> holeMatrix;
  final List<Instruction> instructions;

  PunchCard({
    required this.imageBytes,
    required this.holeMatrix,
    required this.instructions,
  });

  // Factory constructor to create an empty punch card
  factory PunchCard.empty() {
    return PunchCard(
      imageBytes: Uint8List(0),
      holeMatrix: [],
      instructions: [],
    );
  }

  // Helper method to get dimensions of the hole matrix
  int get rows => holeMatrix.isNotEmpty ? holeMatrix.length : 0;
  int get columns => holeMatrix.isNotEmpty ? holeMatrix[0].length : 0;

  // Helper method to check if a hole exists at a specific position
  bool hasHoleAt(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) {
      return false;
    }
    return holeMatrix[row][col];
  }
}

/// Represents a single instruction derived from a punch card column
class Instruction {
  final String operation;
  final Map<String, dynamic> parameters;
  final int columnIndex;

  Instruction({
    required this.operation,
    required this.parameters,
    required this.columnIndex,
  });

  @override
  String toString() {
    String paramString =
        parameters.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$operation($paramString)';
  }
}

/// Represents the result of executing punch card instructions
class ExecutionResult {
  final List<String> output;
  final List<String> memoryDump;
  final bool success;
  final String? errorMessage;

  ExecutionResult({
    required this.output,
    required this.memoryDump,
    required this.success,
    this.errorMessage,
  });

  factory ExecutionResult.error(String message) {
    return ExecutionResult(
      output: [],
      memoryDump: [],
      success: false,
      errorMessage: message,
    );
  }
}

// =============================================================================
// SERVICES
// =============================================================================

/// Service responsible for processing punch card images
class ImageProcessingService {
  /// Processes an image file and returns a binary representation
  Future<Uint8List> processImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image if necessary to standardize dimensions
      final resizedImage = img.copyResize(
        image,
        width: 800,
        interpolation: img.Interpolation.average,
      );

      // Convert to grayscale
      final grayscale = img.grayscale(resizedImage);

      // Apply adaptive thresholding for better hole detection
      final binaryImage = _applyAdaptiveThreshold(grayscale);

      // Encode the processed image
      return Uint8List.fromList(img.encodePng(binaryImage));
    } catch (e) {
      throw Exception('Image processing failed: $e');
    }
  }

  /// Applies adaptive thresholding to improve hole detection
  img.Image _applyAdaptiveThreshold(img.Image grayscale) {
    // Create a binary image
    final binary = img.Image(
      width: grayscale.width,
      height: grayscale.height,
      numChannels: grayscale.numChannels,
    );

    const blockSize = 11;
    const C = 2;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        // Calculate local area bounds
        final startX = (x - blockSize ~/ 2).clamp(0, grayscale.width - 1);
        final endX = (x + blockSize ~/ 2).clamp(0, grayscale.width - 1);
        final startY = (y - blockSize ~/ 2).clamp(0, grayscale.height - 1);
        final endY = (y + blockSize ~/ 2).clamp(0, grayscale.height - 1);

        // Calculate the mean of the local area
        int sum = 0;
        int count = 0;

        for (int j = startY; j <= endY; j++) {
          for (int i = startX; i <= endX; i++) {
            sum += grayscale.getPixel(i, j).r.toInt();
            count++;
          }
        }

        final mean = sum / count;
        final threshold = mean - C;

        // Apply thresholding
        final pixelValue = grayscale.getPixel(x, y).r;
        if (pixelValue < threshold) {
          binary.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // Black for holes
        } else {
          binary.setPixel(
            x,
            y,
            img.ColorRgb8(255, 255, 255),
          ); // White for non-holes
        }
      }
    }

    return binary;
  }
}

/// Service responsible for detecting holes in processed punch card images
class HoleDetectionService {
  /// Detects holes in a binary image and returns a matrix of hole positions
  Future<List<List<bool>>> detectHoles(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode processed image');
      }

      // Define standard punch card dimensions
      // Typical IBM punch cards had 12 rows and 80 columns
      const int standardRows = 12;
      const int standardCols = 80;

      // Calculate cell dimensions based on image size
      final cellHeight = image.height / standardRows;
      final cellWidth = image.width / standardCols;

      // Create hole matrix
      final holeMatrix = List.generate(
        standardRows,
        (_) => List.generate(standardCols, (_) => false),
      );

      // Detect holes by analyzing each cell
      for (int row = 0; row < standardRows; row++) {
        for (int col = 0; col < standardCols; col++) {
          final startX = (col * cellWidth).round();
          final endX = ((col + 1) * cellWidth).round();
          final startY = (row * cellHeight).round();
          final endY = ((row + 1) * cellHeight).round();

          int darkPixels = 0;
          int totalPixels = 0;

          // Count dark pixels in the cell
          for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
              if (x < image.width && y < image.height) {
                final pixelValue = image.getPixel(x, y);
                final grayscaleValue =
                    pixelValue.r; // Use red channel as grayscale

                if (grayscaleValue < 128) {
                  darkPixels++;
                }
                totalPixels++;
              }
            }
          }

          // If the percentage of dark pixels exceeds threshold, consider it a hole
          final darkRatio = darkPixels / totalPixels;
          if (darkRatio > 0.3) {
            // Threshold may need adjustment
            holeMatrix[row][col] = true;
          }
        }
      }

      return holeMatrix;
    } catch (e) {
      throw Exception('Hole detection failed: $e');
    }
  }
}

/// Service responsible for interpreting hole patterns as instructions
class InstructionInterpreterService {
  /// Interprets a hole matrix and returns a list of instructions
  List<Instruction> interpretHoleMatrix(List<List<bool>> holeMatrix) {
    final instructions = <Instruction>[];

    if (holeMatrix.isEmpty || holeMatrix[0].isEmpty) {
      return instructions;
    }

    final rows = holeMatrix.length;
    final cols = holeMatrix[0].length;

    // Process each column as a separate instruction
    for (int col = 0; col < cols; col++) {
      // Extract the hole pattern for this column
      final columnPattern = List.generate(rows, (row) => holeMatrix[row][col]);

      // Skip columns with no holes
      if (!columnPattern.contains(true)) {
        continue;
      }

      // Interpret the pattern based on punch card encoding
      final instruction = _decodeColumnPattern(columnPattern, col);
      if (instruction != null) {
        instructions.add(instruction);
      }
    }

    return instructions;
  }

  /// Decodes a column pattern into an instruction
  ///
  /// This implementation uses a simplified encoding scheme where:
  /// - Row 0 (Y): Print command
  /// - Row 1 (X): Load command
  /// - Row 2 (0): Store command
  /// - Row 3 (1): Add command
  /// - Row 4 (2): Subtract command
  /// - Row 5 (3): Multiply command
  /// - Row 6 (4): Divide command
  /// - Row 7 (5): Jump command
  /// - Row 8 (6): Jump if zero command
  /// - Row 9 (7): Jump if negative command
  /// - Row 10 (8): Data definition (value in rows 11)
  /// - Row 11 (9): Value encoding (binary)
  Instruction? _decodeColumnPattern(List<bool> columnPattern, int columnIndex) {
    // Check for operation type
    if (columnPattern[0]) {
      // Y row - Print
      return Instruction(
        operation: 'PRINT',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[1]) {
      // X row - Load
      return Instruction(
        operation: 'LOAD',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[2]) {
      // 0 row - Store
      return Instruction(
        operation: 'STORE',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[3]) {
      // 1 row - Add
      return Instruction(
        operation: 'ADD',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[4]) {
      // 2 row - Subtract
      return Instruction(
        operation: 'SUB',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[5]) {
      // 3 row - Multiply
      return Instruction(
        operation: 'MUL',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[6]) {
      // 4 row - Divide
      return Instruction(
        operation: 'DIV',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[7]) {
      // 5 row - Jump
      return Instruction(
        operation: 'JMP',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[8]) {
      // 6 row - Jump if zero
      return Instruction(
        operation: 'JZ',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[9]) {
      // 7 row - Jump if negative
      return Instruction(
        operation: 'JN',
        parameters: {'address': _extractNumericValue(columnPattern)},
        columnIndex: columnIndex,
      );
    } else if (columnPattern[10]) {
      // 8 row - Data definition
      return Instruction(
        operation: 'DATA',
        parameters: {'value': _extractDataValue(columnPattern)},
        columnIndex: columnIndex,
      );
    }

    // If we get here, no valid instruction was found
    return null;
  }

  /// Extracts a numeric value from the lower bits of a column pattern
  int _extractNumericValue(List<bool> columnPattern) {
    // Use the last row for address encoding (binary)
    return columnPattern[11] ? 1 : 0;
  }

  /// Extracts a data value from a column pattern
  int _extractDataValue(List<bool> columnPattern) {
    // For data, we interpret the bottom row as the value
    return columnPattern[11] ? 1 : 0;
  }
}

/// Service responsible for executing interpreted instructions
class ExecutionEngineService {
  static const int memorySize = 1000;

  /// Executes a list of instructions and returns the result
  ExecutionResult executeInstructions(List<Instruction> instructions) {
    try {
      final memory = List<int>.filled(memorySize, 0);
      final output = <String>[];
      int accumulator = 0;
      int instructionPointer = 0;

      // Execute until we reach the end of instructions
      while (instructionPointer < instructions.length) {
        final instruction = instructions[instructionPointer];

        switch (instruction.operation) {
          case 'PRINT':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              output.add(memory[address].toString());
            } else {
              output.add(accumulator.toString());
            }
            instructionPointer++;
            break;

          case 'LOAD':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              accumulator = memory[address];
            }
            instructionPointer++;
            break;

          case 'STORE':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              memory[address] = accumulator;
            }
            instructionPointer++;
            break;

          case 'ADD':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              accumulator += memory[address];
            }
            instructionPointer++;
            break;

          case 'SUB':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              accumulator -= memory[address];
            }
            instructionPointer++;
            break;

          case 'MUL':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              accumulator *= memory[address];
            }
            instructionPointer++;
            break;

          case 'DIV':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < memorySize) {
              if (memory[address] == 0) {
                return ExecutionResult.error('Division by zero');
              }
              accumulator ~/= memory[address];
            }
            instructionPointer++;
            break;

          case 'JMP':
            final address = instruction.parameters['address'] as int;
            if (address >= 0 && address < instructions.length) {
              instructionPointer = address;
            } else {
              instructionPointer++;
            }
            break;

          case 'JZ':
            final address = instruction.parameters['address'] as int;
            if (accumulator == 0 &&
                address >= 0 &&
                address < instructions.length) {
              instructionPointer = address;
            } else {
              instructionPointer++;
            }
            break;

          case 'JN':
            final address = instruction.parameters['address'] as int;
            if (accumulator < 0 &&
                address >= 0 &&
                address < instructions.length) {
              instructionPointer = address;
            } else {
              instructionPointer++;
            }
            break;

          case 'DATA':
            final value = instruction.parameters['value'] as int;
            accumulator = value;
            instructionPointer++;
            break;

          default:
            instructionPointer++;
            break;
        }
      }

      // Create a memory dump for the first 100 memory locations (or less if needed)
      final memoryDump = <String>[];
      for (int i = 0; i < 100 && i < memorySize; i++) {
        if (memory[i] != 0) {
          memoryDump.add('Mem[$i] = ${memory[i]}');
        }
      }

      return ExecutionResult(
        output: output,
        memoryDump: memoryDump,
        success: true,
      );
    } catch (e) {
      return ExecutionResult.error('Execution error: $e');
    }
  }
}

// =============================================================================
// UI COMPONENTS
// =============================================================================

/// Home page containing the main interface
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ImagePicker _imagePicker = ImagePicker();
  final ImageProcessingService _imageProcessor = ImageProcessingService();
  final HoleDetectionService _holeDetector = HoleDetectionService();
  final InstructionInterpreterService _interpreter =
      InstructionInterpreterService();
  final ExecutionEngineService _executionEngine = ExecutionEngineService();

  PunchCard _punchCard = PunchCard.empty();
  ExecutionResult? _executionResult;

  bool _isProcessing = false;
  String? _errorMessage;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch Card Processor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isProcessing ? _buildLoadingIndicator() : _buildMainContent(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing punch card...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() {
                  _currentStep += 1;
                });
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    if (_currentStep < 3)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: const Text('Next'),
                      ),
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Select Punch Card Image'),
                content: SizedBox(
                  height: constraints.maxHeight * 0.7,
                  child: _buildImageSelectionStep(),
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Hole Detection'),
                content: SizedBox(
                  height: constraints.maxHeight * 0.7,
                  child: SingleChildScrollView(
                    child: _buildHoleDetectionStep(),
                  ),
                ),
                isActive: _currentStep >= 1,
                state: _punchCard.imageBytes.isEmpty
                    ? StepState.disabled
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Instruction Interpretation'),
                content: SizedBox(
                  height: constraints.maxHeight * 0.7,
                  child: SingleChildScrollView(child: _buildInstructionStep()),
                ),
                isActive: _currentStep >= 2,
                state: _punchCard.holeMatrix.isEmpty
                    ? StepState.disabled
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Execution Results'),
                content: SizedBox(
                  height: constraints.maxHeight * 0.7,
                  child: SingleChildScrollView(child: _buildExecutionStep()),
                ),
                isActive: _currentStep >= 3,
                state: _punchCard.instructions.isEmpty
                    ? StepState.disabled
                    : StepState.indexed,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSelectionStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or capture an image of a punch card to process.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image'),
                  onPressed: _pickImage,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _takePhoto,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste Image'),
                  onPressed: _pasteImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_punchCard.imageBytes.isNotEmpty)
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Image:'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRect(
                        child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(20.0),
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.memory(
                            _punchCard.imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHoleDetectionStep() {
    if (_punchCard.holeMatrix.isEmpty) {
      return const Text('Please select an image first to detect holes.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected hole pattern:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _buildHoleMatrix(),
        const SizedBox(height: 16),
        Text('Total holes detected: ${_countHoles()}'),
      ],
    );
  }

  Widget _buildHoleMatrix() {
    // Create a scrollable visualization of the hole matrix
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 240, // Fixed height for the grid
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row headers (Row numbers)
            Row(
              children: [
                // Empty cell for corner
                const SizedBox(width: 40, height: 20),
                // Column numbers (displayed vertically for space efficiency)
                for (int col = 0; col < _punchCard.columns; col += 5)
                  SizedBox(
                    width: 100, // Width for 5 columns
                    child: Center(child: Text('${col + 1}-${col + 5}')),
                  ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row numbers (displayed vertically)
                  Column(
                    children: [
                      for (int row = 0; row < _punchCard.rows; row++)
                        SizedBox(
                          width: 40,
                          height: 20,
                          child: Center(child: Text('R${row + 1}')),
                        ),
                    ],
                  ),
                  // Hole matrix
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int colGroup = 0;
                            colGroup < _punchCard.columns;
                            colGroup += 5)
                          Column(
                            children: [
                              for (int row = 0; row < _punchCard.rows; row++)
                                Row(
                                  children: [
                                    for (int col = colGroup;
                                        col < colGroup + 5 &&
                                            col < _punchCard.columns;
                                        col++)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Center(
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color:
                                                  _punchCard.hasHoleAt(row, col)
                                                      ? Colors.black
                                                      : Colors.transparent,
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countHoles() {
    int count = 0;
    for (int row = 0; row < _punchCard.rows; row++) {
      for (int col = 0; col < _punchCard.columns; col++) {
        if (_punchCard.hasHoleAt(row, col)) {
          count++;
        }
      }
    }
    return count;
  }

  Widget _buildInstructionStep() {
    if (_punchCard.instructions.isEmpty) {
      return const Text(
        'No instructions were detected. Please ensure your punch card image is clear and properly aligned.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interpreted Instructions:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _punchCard.instructions.length,
            itemBuilder: (context, index) {
              final instruction = _punchCard.instructions[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(instruction.operation),
                subtitle: Text(
                  'Column: ${instruction.columnIndex + 1}, Params: ${instruction.parameters}',
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Execute Instructions'),
          onPressed: _executeInstructions,
        ),
      ],
    );
  }

  Widget _buildExecutionStep() {
    if (_executionResult == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Click "Execute Instructions" in the previous step to see the results.',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Execute Now'),
            onPressed: _executeInstructions,
          ),
        ],
      );
    }

    final result = _executionResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Execution ${result.success ? 'Succeeded' : 'Failed'}',
          style: TextStyle(
            color: result.success ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!result.success && result.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Error: ${result.errorMessage}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        Text('Program Output:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        result.output.isEmpty
            ? const Text('No output produced')
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  itemCount: result.output.length,
                  itemBuilder: (context, index) {
                    return Text('> ${result.output[index]}');
                  },
                ),
              ),
        const SizedBox(height: 16),
        Text('Memory Dump:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        result.memoryDump.isEmpty
            ? const Text('No memory values to display')
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  itemCount: result.memoryDump.length,
                  itemBuilder: (context, index) {
                    return Text(result.memoryDump[index]);
                  },
                ),
              ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Save Results'),
              onPressed: _saveResults,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Start Over'),
              onPressed: _resetApplication,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      }
    } catch (e) {
      _setError('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      }
    } catch (e) {
      _setError('Error taking photo: $e');
    }
  }

  Future<void> _pasteImage() async {
    try {
      // Try to get image data from clipboard
      final imageBytes = await Pasteboard.image;
      if (imageBytes == null) {
        _setError('No image found in clipboard. Copy an image first.');
        return;
      }

      // Create a temporary file to store the image
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/clipboard_image.png');

      // Write the image bytes to the file
      await tempFile.writeAsBytes(imageBytes);

      // Process the image
      await _processImage(tempFile);
    } catch (e) {
      _setError('Error pasting image: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _executionResult = null;
    });

    try {
      // Process the image
      final processedImageBytes = await _imageProcessor.processImage(imageFile);

      // Detect holes
      final holeMatrix = await _holeDetector.detectHoles(processedImageBytes);

      // Interpret instructions
      final instructions = _interpreter.interpretHoleMatrix(holeMatrix);

      // Update the punch card
      setState(() {
        _punchCard = PunchCard(
          imageBytes: processedImageBytes,
          holeMatrix: holeMatrix,
          instructions: instructions,
        );
        _isProcessing = false;

        // Advance to hole detection step if we have holes
        if (holeMatrix.isNotEmpty) {
          _currentStep = 1;
        }
      });
    } catch (e) {
      _setError('Processing failed: $e');
    }
  }

  void _executeInstructions() {
    if (_punchCard.instructions.isEmpty) {
      _setError('No instructions to execute');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = _executionEngine.executeInstructions(
        _punchCard.instructions,
      );

      setState(() {
        _executionResult = result;
        _isProcessing = false;
        _currentStep = 3; // Move to execution results step
      });
    } catch (e) {
      _setError('Execution failed: $e');
    }
  }

  Future<void> _saveResults() async {
    if (_executionResult == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/punchcard_result_$timestamp.txt';

      final file = File(path);
      final buffer = StringBuffer();

      buffer.writeln('PUNCH CARD EXECUTION RESULTS');
      buffer.writeln('---------------------------');
      buffer.writeln('Date: ${DateTime.now().toString()}');
      buffer.writeln('');

      buffer.writeln('INSTRUCTIONS:');
      for (int i = 0; i < _punchCard.instructions.length; i++) {
        buffer.writeln('${i + 1}. ${_punchCard.instructions[i]}');
      }
      buffer.writeln('');

      buffer.writeln('OUTPUT:');
      if (_executionResult!.output.isEmpty) {
        buffer.writeln('No output produced');
      } else {
        for (final line in _executionResult!.output) {
          buffer.writeln('> $line');
        }
      }
      buffer.writeln('');

      buffer.writeln('MEMORY DUMP:');
      if (_executionResult!.memoryDump.isEmpty) {
        buffer.writeln('No memory values to display');
      } else {
        for (final line in _executionResult!.memoryDump) {
          buffer.writeln(line);
        }
      }

      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results saved to ${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      _setError('Error saving results: $e');
    }
  }

  void _resetApplication() {
    setState(() {
      _punchCard = PunchCard.empty();
      _executionResult = null;
      _errorMessage = null;
      _currentStep = 0;
    });
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isProcessing = false;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Punch Card Processor Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Punch Cards',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Punch cards were an early form of data storage and program input. '
                'Each card contains a pattern of holes that represent instructions or data.',
              ),
              SizedBox(height: 12),
              Text(
                'Using This App',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Select or capture an image of a punch card\n'
                '2. The app will detect the hole pattern\n'
                '3. The pattern will be interpreted as instructions\n'
                '4. Execute the instructions to see the results',
              ),
              SizedBox(height: 12),
              Text(
                'Supported Instructions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'PRINT: Display a value\n'
                'LOAD: Load a value from memory\n'
                'STORE: Store a value to memory\n'
                'ADD/SUB/MUL/DIV: Arithmetic operations\n'
                'JMP/JZ/JN: Control flow instructions\n'
                'DATA: Data definition',
              ),
              SizedBox(height: 12),
              Text(
                'Tips',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Ensure good lighting when taking photos\n'
                '• Keep the card flat and aligned with the frame\n'
                '• Try to maximize contrast between holes and card',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
