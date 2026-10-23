import 'dart:convert';

class SolutionResult {
  final String equation;
  final String equationType;
  final String method;
  final List<SolutionStep> steps;
  final String finalSolution;
  final String? notes;

  SolutionResult({
    required this.equation,
    required this.equationType,
    required this.method,
    required this.steps,
    required this.finalSolution,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'equation': equation,
      'equationType': equationType,
      'method': method,
      'steps': steps.map((s) => s.toMap()).toList(),
      'finalSolution': finalSolution,
      'notes': notes,
    };
  }

  factory SolutionResult.fromMap(Map<String, dynamic> map) {
    return SolutionResult(
      equation: map['equation'] ?? '',
      equationType: map['equationType'] ?? 'Persamaan Diferensial Biasa',
      method: map['method'] ?? 'Metode Analitik',
      steps: (map['steps'] as List<dynamic>? ?? [])
          .map((s) => SolutionStep.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      finalSolution: map['finalSolution'] ?? '',
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());
  factory SolutionResult.fromJson(String source) =>
      SolutionResult.fromMap(json.decode(source));
}

class SolutionStep {
  final String title;
  final String explanation;
  final String formula;

  SolutionStep({
    required this.title,
    required this.explanation,
    required this.formula,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'explanation': explanation,
      'formula': formula,
    };
  }

  factory SolutionStep.fromMap(Map<String, dynamic> map) {
    return SolutionStep(
      title: map['title'] ?? '',
      explanation: map['explanation'] ?? '',
      formula: map['formula'] ?? '',
    );
  }
}
