
import 'dart:math' as math;

enum GameLevel {
  facil,
  intermediario,
  avancado,
  dificil,
}

class MathEngine {
  final GameLevel level;
  final List<double> availableNumbers;

  MathEngine({
    required this.level,
    required this.availableNumbers,
  });

  double calculate(String expression) {
    final parser = _Parser(
      expression: expression,
      level: level,
      availableNumbers: availableNumbers,
    );

    final result = parser.parse();

    if (!result.isFinite) {
      throw const FormatException('Resultado matemático inválido.');
    }

    return result;
  }

  bool checkAnswer(String expression, double target) {
    final result = calculate(expression);
    return (result - target).abs() < 0.0000001;
  }
}

class _Parser {
  final String expression;
  final GameLevel level;
  final List<double> availableNumbers;

  late final List<String> tokens;
  int position = 0;

  _Parser({
    required this.expression,
    required this.level,
    required this.availableNumbers,
  }) {
    tokens = _tokenize(expression);
  }

  double parse() {
    final result = _parseExpression();

    if (position < tokens.length) {
      throw FormatException(
        'Expressão inválida próximo de "${tokens[position]}".',
      );
    }

    return result;
  }

  List<String> _tokenize(String input) {
    final result = <String>[];
    final regex = RegExp(
      r'\d+(?:\.\d+)?|[a-zA-Z]+|\*\*|[+\-*/!()]',
    );

    int current = 0;

    for (final match in regex.allMatches(input)) {
      final between = input.substring(current, match.start);

      if (between.trim().isNotEmpty) {
        throw FormatException('Caractere inválido: $between');
      }

      result.add(match.group(0)!);
      current = match.end;
    }

    if (input.substring(current).trim().isNotEmpty) {
      throw const FormatException('Expressão contém caracteres inválidos.');
    }

    return result;
  }

  String? _peek() {
    if (position >= tokens.length) return null;
    return tokens[position];
  }

  bool _match(String token) {
    if (_peek() == token) {
      position++;
      return true;
    }
    return false;
  }

  void _requireOperator(String operatorName) {
    final allowed = switch (level) {
      GameLevel.facil => ['+', '-', '*', '/', 'sqrt', 'cbrt',
          '!', '**', 'abs', 'floor', 'ceil', '(', ')'],
      GameLevel.intermediario => ['+', '-', '*', '/', 'sqrt',
          'cbrt', '!', '**', 'abs', '(', ')'],
      GameLevel.avancado => ['+', '-', '*', '/', 'sqrt', '!', 'abs',
          '(', ')'],
      GameLevel.dificil => ['+', '-', '*', '/', 'abs', '(', ')'],
    };

    if (!allowed.contains(operatorName)) {
      throw FormatException(
        'O operador "$operatorName" não é permitido neste nível.',
      );
    }
  }

  double _parseExpression() {
    double value = _parseTerm();

    while (_peek() == '+' || _peek() == '-') {
      final operatorName = tokens[position++];
      _requireOperator(operatorName);

      final next = _parseTerm();

      value = operatorName == '+'
          ? value + next
          : value - next;
    }

    return value;
  }

  double _parseTerm() {
    double value = _parseUnary();

    while (_peek() == '*' || _peek() == '/') {
      final operatorName = tokens[position++];
      _requireOperator(operatorName);

      final next = _parseUnary();

      if (operatorName == '*') {
        value *= next;
      } else {
        if (next == 0) {
          throw const FormatException('Não é possível dividir por zero.');
        }

        final division = value / next;

        if (level != GameLevel.facil &&
            (division - division.round()).abs() > 0.0000001) {
          throw const FormatException(
            'Neste nível, a divisão precisa ter resultado inteiro.',
          );
        }

        value = division;
      }
    }

    return value;
  }

  double _parseUnary() {
    if (_match('+')) return _parseUnary();

    if (_match('-')) return -_parseUnary();

    return _parsePower();
  }

  double _parsePower() {
    double value = _parsePostfix();

    if (_match('**')) {
      _requireOperator('**');
      final exponent = _parseUnary();
      value = math.pow(value, exponent).toDouble();
    }

    return value;
  }

  double _parsePostfix() {
    double value = _parsePrimary();

    while (_match('!')) {
      _requireOperator('!');
      value = _factorial(value);
    }

    return value;
  }

  double _parsePrimary() {
    final token = _peek();

    if (token == null) {
      throw const FormatException('Expressão incompleta.');
    }

    if (_match('(')) {
      _requireOperator('(');
      final value = _parseExpression();

      if (!_match(')')) {
        throw const FormatException('Falta fechar um parêntese.');
      }

      _requireOperator(')');
      return value;
    }

    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(token)) {
      position++;

      final number = double.parse(token);

      final exists = availableNumbers.any(
        (n) => (n - number).abs() < 0.0000001,
      );

      if (!exists) {
        throw FormatException(
          'O número $token não está disponível no desafio.',
        );
      }

      return number;
    }

    if (['sqrt', 'cbrt', 'abs', 'floor', 'ceil'].contains(token)) {
      position++;
      _requireOperator(token);

      if (!_match('(')) {
        throw const FormatException('Esperado "(" após a função.');
      }

      final value = _parseExpression();

      if (!_match(')')) {
        throw const FormatException('Falta fechar o parêntese da função.');
      }

      switch (token) {
        case 'sqrt':
          if (value < 0) {
            throw const FormatException(
              'Não existe raiz quadrada real de número negativo.',
            );
          }
          return math.sqrt(value);

        case 'cbrt':
          return value < 0
              ? -math.pow(-value, 1 / 3).toDouble()
              : math.pow(value, 1 / 3).toDouble();

        case 'abs':
          return value.abs();

        case 'floor':
          return value.floorToDouble();

        case 'ceil':
          return value.ceilToDouble();
      }
    }

    throw FormatException('Elemento inesperado: $token');
  }

  double _factorial(double value) {
    if (value < 0 || value != value.roundToDouble()) {
      throw const FormatException(
        'O fatorial só pode ser aplicado a inteiros não negativos.',
      );
    }

    if (value > 170) {
      throw const FormatException('Número muito grande para fatorial.');
    }

    double result = 1;

    for (int i = 2; i <= value.toInt(); i++) {
      result *= i;
    }

    return result;
  }
}
