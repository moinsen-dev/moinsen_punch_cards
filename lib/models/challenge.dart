import 'package:flutter/material.dart';

enum ChallengeDifficulty {
  low,
  medium,
  high;

  String get displayName => switch (this) {
        ChallengeDifficulty.low => 'Beginner',
        ChallengeDifficulty.medium => 'Intermediate',
        ChallengeDifficulty.high => 'Advanced',
      };

  Color get color => switch (this) {
        ChallengeDifficulty.low => Colors.green,
        ChallengeDifficulty.medium => Colors.orange,
        ChallengeDifficulty.high => Colors.red,
      };
}

enum ChallengeStatus { notStarted, inProgress, completed, failed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final List<String> requiredPatterns;
  final List<String> forbiddenPatterns;
  final int timeLimit; // in seconds
  final int points;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.requiredPatterns,
    required this.forbiddenPatterns,
    required this.timeLimit,
    required this.points,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ChallengeDifficulty.values.firstWhere(
        (d) => d.toString() == 'ChallengeDifficulty.${json['difficulty']}',
      ),
      requiredPatterns: List<String>.from(json['requiredPatterns']),
      forbiddenPatterns: List<String>.from(json['forbiddenPatterns']),
      timeLimit: json['timeLimit'] as int,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'requiredPatterns': requiredPatterns,
      'forbiddenPatterns': forbiddenPatterns,
      'timeLimit': timeLimit,
      'points': points,
    };
  }

  // Example challenges
  static List<Challenge> get sampleChallenges => [
        Challenge(
          id: '1',
          title: 'Simple Addition',
          description:
              'Create a program that adds two numbers (5 and 3) and stores the result.',
          difficulty: ChallengeDifficulty.low,
          requiredPatterns: ['LOAD', 'ADD', 'STORE'],
          forbiddenPatterns: [],
          timeLimit: 5,
          points: 100,
        ),
        Challenge(
          id: '2',
          title: 'Number Comparison',
          description:
              'Create a program that compares two numbers and jumps if they are equal.',
          difficulty: ChallengeDifficulty.medium,
          requiredPatterns: ['LOAD', 'SUB', 'JZ', 'STORE'],
          forbiddenPatterns: [],
          timeLimit: 8,
          points: 200,
        ),
        Challenge(
          id: '3',
          title: 'Simple Loop',
          description: 'Create a program that counts from 1 to 5 using a loop.',
          difficulty: ChallengeDifficulty.high,
          requiredPatterns: ['LOAD', 'ADD', 'STORE', 'JMP', 'JZ'],
          forbiddenPatterns: [],
          timeLimit: 10,
          points: 300,
        ),
      ];
}
