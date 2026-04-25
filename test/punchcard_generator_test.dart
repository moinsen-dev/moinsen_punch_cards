import 'package:flutter_test/flutter_test.dart';
import 'package:moinsen_punch_cards/punchcard_generator.dart';

void main() {
  group('PunchCardInstruction', () {
    test('toString formats correctly', () {
      final instruction = PunchCardInstruction(
        column: 5,
        rows: [0, 1],
        operation: 'LOAD',
        parameters: {'value': 42},
      );

      expect(
        instruction.toString(),
        'LOAD at column 5 (rows: 0, 1)',
      );
    });
  });

  group('PunchCardProgram', () {
    test('auto-generates id when not provided', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final program = PunchCardProgram(
        title: 'Test',
        instructions: [],
      );
      final after = DateTime.now().millisecondsSinceEpoch;

      final id = int.parse(program.id);
      expect(id, greaterThanOrEqualTo(before));
      expect(id, lessThanOrEqualTo(after));
    });

    test('uses provided id', () {
      final program = PunchCardProgram(
        id: 'custom-id',
        title: 'Test',
        instructions: [],
      );
      expect(program.id, 'custom-id');
    });

    test('getOperations returns formatted strings', () {
      final program = PunchCardProgram(
        title: 'Test',
        instructions: [
          PunchCardInstruction(
            column: 1,
            rows: [0, 1],
            operation: 'LOAD',
            parameters: {'value': 5},
          ),
          PunchCardInstruction(
            column: 2,
            rows: [2],
            operation: 'ADD',
            parameters: {'register': 'A'},
          ),
        ],
      );

      final ops = program.getOperations();
      expect(ops.length, 2);
      expect(ops[0], contains('LOAD'));
      expect(ops[0], contains('Column 1'));
      expect(ops[1], contains('ADD'));
      expect(ops[1], contains('Column 2'));
    });

    test('default maxColumns is 80 and maxRows is 12', () {
      final program = PunchCardProgram(
        title: 'Test',
        instructions: [],
      );
      expect(program.maxColumns, 80);
      expect(program.maxRows, 12);
    });
  });

  group('PunchCardSvgGenerator', () {
    test('generateSvg produces valid SVG with title', () {
      final generator = PunchCardSvgGenerator();
      final program = PunchCardProgram(
        title: 'My Card',
        instructions: [
          PunchCardInstruction(
            column: 5,
            rows: [0, 1],
            operation: 'LOAD',
            parameters: {'value': 5},
          ),
        ],
      );

      final svg = generator.generateSvg(program);

      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('My Card'));
      expect(svg, contains('LOAD'));
      expect(svg, contains('cx="85"'));
      expect(svg, contains('cy="80"'));
    });

    test('generateSvg handles empty instructions', () {
      final generator = PunchCardSvgGenerator();
      final program = PunchCardProgram(
        title: 'Empty',
        instructions: [],
      );

      final svg = generator.generateSvg(program);

      expect(svg, contains('<svg'));
      expect(svg, contains('Empty'));
    });
  });

  group('extractJsonFromText', () {
    test('extracts plain JSON', () {
      final text = '{"title": "Test", "instructions": []}';
      final result = extractJsonFromText(text);
      expect(result['title'], 'Test');
      expect(result['instructions'], []);
    });

    test('extracts JSON from markdown code block', () {
      final text = '```json\n{"title": "Hello", "instructions": []}\n```';
      final result = extractJsonFromText(text);
      expect(result['title'], 'Hello');
    });

    test('extracts JSON from code block without language tag', () {
      final text = '```\n{"title": "World"}\n```';
      final result = extractJsonFromText(text);
      expect(result['title'], 'World');
    });

    test('extracts JSON surrounded by text', () {
      final text = 'Here is the result:\n{"title": "Embedded"}\nDone.';
      final result = extractJsonFromText(text);
      expect(result['title'], 'Embedded');
    });

    test('throws when no JSON found', () {
      expect(
        () => extractJsonFromText('no json here'),
        throwsException,
      );
    });

    test('throws on invalid JSON', () {
      expect(
        () => extractJsonFromText('{invalid}'),
        throwsException,
      );
    });
  });

  group('parseProgramJson', () {
    test('parses full program JSON', () {
      final json = {
        'title': 'Add Two Numbers',
        'instructions': [
          {
            'column': 1,
            'rows': [0, 1],
            'operation': 'LOAD',
            'parameters': {'value': 5},
          },
          {
            'column': 2,
            'rows': [2],
            'operation': 'ADD',
            'parameters': {'register': 'A'},
          },
        ],
      };

      final program = parseProgramJson(json);

      expect(program.title, 'Add Two Numbers');
      expect(program.instructions.length, 2);
      expect(program.instructions[0].column, 1);
      expect(program.instructions[0].rows, [0, 1]);
      expect(program.instructions[0].operation, 'LOAD');
      expect(program.instructions[1].operation, 'ADD');
    });

    test('parses program with empty instructions', () {
      final json = {
        'title': 'Empty Program',
        'instructions': [],
      };

      final program = parseProgramJson(json);
      expect(program.title, 'Empty Program');
      expect(program.instructions, isEmpty);
    });
  });
}
