
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../sound_manager.dart';
import '../services/firestore_service.dart';

class GameScreen extends StatefulWidget {
  final String level;

  const GameScreen({
    super.key,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Color purple = Color(0xFF8065F6);

  late List<String> numbers;

  int score = 0;
  bool _isLoadingProgress = true;
  bool _isVerifying = false;
  bool _isReturningOperators = false;

  final Set<String> _solvedChallengeIds = {};

  // Cinco áreas para adicionar operadores.
  final List<List<String>> operatorGroups =
      List.generate(5, (_) => <String>[]);

  int selectedGap = 0;

  Set<String> _returningOperators = {};

  // Identificação do tema atual.
  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  // Cores adaptáveis.
  Color get _background =>
      _isDark ? const Color(0xFF10121B) : const Color(0xFFF5F5FA);

  Color get _boardColor =>
      _isDark ? const Color(0xFF191C29) : Colors.white;

  Color get _cardColor =>
      _isDark ? const Color(0xFF292D40) : const Color(0xFFEDEAFB);

  Color get _gapColor =>
      _isDark ? const Color(0xFF222638) : const Color(0xFFF1EFFA);

  Color get _primaryText =>
      _isDark ? Colors.white : const Color(0xFF202033);

  Color get _secondaryText =>
      _isDark ? Colors.white70 : const Color(0xFF68677A);

  Color get _mutedText =>
      _isDark ? Colors.white38 : const Color(0xFF9290A2);

  Color get _borderColor =>
      _isDark ? Colors.white24 : const Color(0xFFD8D5E8);

  Color get _buttonText =>
      _isDark ? Colors.white : const Color(0xFF39334F);

  bool get _isEnglish =>
      Localizations.localeOf(context).languageCode == 'en';

  String _text(String portuguese, String english) {
    return _isEnglish ? english : portuguese;
  }

  int get _pointsForLevel {
    switch (widget.level.toLowerCase()) {
      case 'fácil':
      case 'facil':
        return 5;

      case 'intermediário':
      case 'intermediario':
        return 10;

      case 'avançado':
      case 'avancado':
        return 15;

      case 'difícil':
      case 'dificil':
        return 20;

      default:
        return 10;
    }
  }

  String get _translatedLevel {
    switch (widget.level.toLowerCase()) {
      case 'fácil':
      case 'facil':
        return _text('Fácil', 'Easy');
      case 'intermediário':
      case 'intermediario':
        return _text('Intermediário', 'Intermediate');
      case 'avançado':
      case 'avancado':
        return _text('Avançado', 'Advanced');
      case 'difícil':
      case 'dificil':
        return _text('Difícil', 'Hard');
      default:
        return widget.level;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    try {
      final progress = await FirestoreService.getProgress();

      if (!mounted) return;

      setState(() {
        score = (progress['score'] as num).toInt();

        _solvedChallengeIds.addAll(
          List<String>.from(progress['solvedChallenges'] ?? []),
        );

        numbers = _createSolvableChallenge();
        _isLoadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        numbers = _createSolvableChallenge();
        _isLoadingProgress = false;
      });

      _showMessage(
        _text(
          'Não foi possível carregar seu progresso.',
          'Could not load your progress.',
        ),
        true,
      );
    }
  }

  String _challengeIdFor(List<String> challengeNumbers) {
    return '${widget.level}_${challengeNumbers.join('_')}';
  }

  String get _currentChallengeId => _challengeIdFor(numbers);

  List<String> _createSolvableChallenge() {
    final random = math.Random();
    const basicOperators = ['+', '-', '*'];

    List<String>? firstValidChallenge;

    for (int attempt = 0; attempt < 5000; attempt++) {
      final a = random.nextInt(9) + 1;
      final b = random.nextInt(9) + 1;
      final c = random.nextInt(9) + 1;

      final firstOperator =
          basicOperators[random.nextInt(basicOperators.length)];

      final secondOperator =
          basicOperators[random.nextInt(basicOperators.length)];

      try {
        final result = _ExpressionParser(
          [
            a.toString(),
            firstOperator,
            b.toString(),
            secondOperator,
            c.toString(),
          ],
          allowDecimalDivision: false,
        ).parse();

        if (result.isFinite &&
            result == result.roundToDouble() &&
            result >= 1 &&
            result <= 9) {
          final candidate = [
            a.toString(),
            b.toString(),
            c.toString(),
            result.toInt().toString(),
          ];

          firstValidChallenge ??= candidate;

          final challengeId = _challengeIdFor(candidate);

          if (!_solvedChallengeIds.contains(challengeId)) {
            return candidate;
          }
        }
      } catch (_) {}
    }

    return firstValidChallenge ?? ['2', '3', '4', '1'];
  }

  void _newChallenge() {
    if (_isReturningOperators || _isVerifying) return;

    setState(() {
      numbers = _createSolvableChallenge();

      for (final group in operatorGroups) {
        group.clear();
      }

      selectedGap = 0;
    });
  }

  bool get allowDecimalDivision {
    final level = widget.level.toLowerCase();
    return level == 'fácil' || level == 'facil';
  }

  List<String> get operators {
    switch (widget.level.toLowerCase()) {
      case 'fácil':
      case 'facil':
        return [
          '+', '-', '*', '/', '(', ')',
          '√', '∛', '!', '**', '|x|',
          '⌊x⌋', '⌈x⌉', '='
        ];

      case 'intermediário':
      case 'intermediario':
        return [
          '+', '-', '*', '/', '(', ')',
          '√', '∛', '!', '**', '|x|', '='
        ];

      case 'avançado':
      case 'avancado':
        return [
          '+', '-', '*', '/', '(', ')',
          '√', '!', '|x|', '='
        ];

      case 'difícil':
      case 'dificil':
        return ['+', '-', '*', '/', '(', ')', '|x|', '='];

      default:
        return ['+', '-', '*', '/', '='];
    }
  }

  void _addOperator(int gapIndex, String operator) {
    if (_isReturningOperators || _isVerifying) return;

    if (operator == '=' && _allOperators.contains('=')) {
      _showMessage(
        _text(
          'Você só pode utilizar um sinal de igualdade.',
          'You can only use one equals sign.',
        ),
        true,
      );
      return;
    }

    setState(() {
      operatorGroups[gapIndex].add(operator);
      selectedGap = gapIndex;
    });

    _playSound('click');
  }

  List<String> get _allOperators {
    return operatorGroups.expand((group) => group).toList();
  }

  void _removeOperator(int gapIndex, int operatorIndex) {
    if (_isReturningOperators || _isVerifying) return;

    setState(() {
      operatorGroups[gapIndex].removeAt(operatorIndex);
      selectedGap = gapIndex;
    });
  }

  void _undo() {
    if (_isReturningOperators || _isVerifying) return;

    if (operatorGroups[selectedGap].isEmpty) return;

    setState(() {
      operatorGroups[selectedGap].removeLast();
    });
  }

  void _clear() {
    if (_isReturningOperators || _isVerifying) return;

    setState(() {
      for (final group in operatorGroups) {
        group.clear();
      }

      selectedGap = 0;
    });
  }

  List<String> _buildTokens() {
    final tokens = <String>[];

    tokens.addAll(operatorGroups[0]);

    String currentNumber = numbers[0];

    for (int i = 1; i < numbers.length; i++) {
      final group = operatorGroups[i];

      if (group.isEmpty) {
        currentNumber += numbers[i];
      } else {
        tokens.add(currentNumber);
        tokens.addAll(group);
        currentNumber = numbers[i];
      }
    }

    tokens.add(currentNumber);
    tokens.addAll(operatorGroups[4]);

    return tokens;
  }

  String _currentExpressionLatex() {
    return _tokensToLatex(_buildTokens());
  }

  String _tokensToLatex(List<String> tokens) {
    final output = StringBuffer();

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == '√' ||
          token == '∛' ||
          token == '|x|' ||
          token == '⌊x⌋' ||
          token == '⌈x⌉') {
        final operand = _latexOperand(tokens, i + 1);

        if (operand == null) {
          output.write(token);
          continue;
        }

        if (token == '√') {
          output.write(r'\sqrt{' + operand.value + '}');
        } else if (token == '∛') {
          output.write(r'\sqrt[3]{' + operand.value + '}');
        } else if (token == '|x|') {
          output.write(r'\left|' + operand.value + r'\right|');
        } else if (token == '⌊x⌋') {
          output.write(
            r'\left\lfloor ' + operand.value + r'\right\rfloor',
          );
        } else {
          output.write(
            r'\left\lceil ' + operand.value + r'\right\rceil',
          );
        }

        i += operand.consumed;
        continue;
      }

      switch (token) {
        case '*':
          output.write(r'\times ');
          break;
        case '/':
          output.write(r'\div ');
          break;
        case '**':
          final exponent = _latexOperand(tokens, i + 1);

          if (exponent == null) {
            output.write('^');
          } else {
            output.write('^{${exponent.value}}');
            i += exponent.consumed;
          }
          break;
        case '(':
          output.write('(');
          break;
        case ')':
          output.write(')');
          break;
        case '!':
          output.write('!');
          break;
        case '=':
          output.write('=');
          break;
        case '+':
        case '-':
          output.write(token);
          break;
        default:
          output.write(token);
      }
    }

    return output.toString();
  }

  ({String value, int consumed})? _latexOperand(
    List<String> tokens,
    int start,
  ) {
    if (start >= tokens.length) return null;

    final token = tokens[start];

    if (token == '(') {
      int depth = 0;

      for (int i = start; i < tokens.length; i++) {
        if (tokens[i] == '(') depth++;
        if (tokens[i] == ')') depth--;

        if (depth == 0) {
          final inside = tokens.sublist(start + 1, i);

          return (
            value: r'\left(' +
                _tokensToLatex(inside) +
                r'\right)',
            consumed: i - start,
          );
        }
      }

      return (value: '(', consumed: 0);
    }

    if (token == '√' ||
        token == '∛' ||
        token == '|x|' ||
        token == '⌊x⌋' ||
        token == '⌈x⌉') {
      final nested = _latexOperand(tokens, start + 1);

      if (nested == null) return null;

      String value;

      if (token == '√') {
        value = r'\sqrt{' + nested.value + '}';
      } else if (token == '∛') {
        value = r'\sqrt[3]{' + nested.value + '}';
      } else if (token == '|x|') {
        value = r'\left|' + nested.value + r'\right|';
      } else if (token == '⌊x⌋') {
        value = r'\left\lfloor ' +
            nested.value +
            r'\right\rfloor';
      } else {
        value = r'\left\lceil ' +
            nested.value +
            r'\right\rceil';
      }

      return (
        value: value,
        consumed: nested.consumed + 1,
      );
    }

    String value = token;
    int consumed = 1;

    while (start + consumed < tokens.length &&
        tokens[start + consumed] == '!') {
      value += '!';
      consumed++;
    }

    return (value: value, consumed: consumed);
  }

  Future<void> _verifyExpression() async {
    if (_isReturningOperators || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final tokens = _buildTokens();
      final equalIndex = tokens.indexOf('=');

      if (equalIndex == -1) {
        _showMessage(
          _text(
            'Adicione o sinal = à expressão.',
            'Add the = sign to the expression.',
          ),
          true,
        );
        return;
      }

      if (tokens.lastIndexOf('=') != equalIndex) {
        _showMessage(
          _text(
            'Você só pode utilizar um sinal de igualdade.',
            'You can only use one equals sign.',
          ),
          true,
        );
        return;
      }

      try {
        final leftTokens = tokens.sublist(0, equalIndex);
        final rightTokens = tokens.sublist(equalIndex + 1);

        final leftValue = _ExpressionParser(
          leftTokens,
          allowDecimalDivision: allowDecimalDivision,
        ).parse();

        final rightValue = _ExpressionParser(
          rightTokens,
          allowDecimalDivision: allowDecimalDivision,
        ).parse();

        final correct =
            (leftValue - rightValue).abs() < 0.0000001;

        if (correct) {
          try {
            final challengeId = _currentChallengeId;
            final points = _pointsForLevel;

            final registered =
                await FirestoreService.registerSolvedChallenge(
              challengeId,
              points: points,
            );

            if (!mounted) return;

            if (registered) {
              setState(() {
              score += points;
              _solvedChallengeIds.add(challengeId);
            });

              _playSound('success');

              _showMessage(
                _text(
                  'Parabéns! Você ganhou $points pontos! 🎉',
                  'Congratulations! You earned $points points! 🎉',
                ),
                false,
              );
            } else {
              _solvedChallengeIds.add(challengeId);

              _showMessage(
                _text(
                  'Você já resolveu esse desafio anteriormente!',
                  'You have already solved this challenge!',
                ),
                true,
              );
            }
          } catch (e) {
            if (!mounted) return;

            _playSound('error');

            _showMessage(
              _text(
                'Resposta correta, mas não foi possível salvar sua pontuação.',
                'Correct answer, but your score could not be saved.',
              ),
              true,
            );
          }
        } else {
          _playSound('error');

          _showMessage(
            _text(
              'A igualdade está incorreta. Resultado: '
              '${_formatNumber(leftValue)} e ${_formatNumber(rightValue)}.',
              'The equation is incorrect. Results: '
              '${_formatNumber(leftValue)} and ${_formatNumber(rightValue)}.',
            ),
            true,
          );
        }
      } catch (_) {
        _playSound('error');

        _showMessage(
          _text(
            'Expressão inválida. Confira a posição dos operadores.',
            'Invalid expression. Check the position of the operators.',
          ),
          true,
        );
      }
    } finally {
      await _returnOperatorsToPanel();

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _returnOperatorsToPanel() async {
    if (!mounted) return;

    setState(() {
      _isReturningOperators = true;
      _returningOperators = _allOperators.toSet();
    });

    await Future.delayed(const Duration(milliseconds: 420));

    if (!mounted) return;

    setState(() {
      for (final group in operatorGroups) {
        group.clear();
      }

      selectedGap = 0;
      _isReturningOperators = false;
      _returningOperators.clear();
    });
  }

  void _skipChallenge() {
    if (_isReturningOperators || _isVerifying) return;

    _playSound('skip');
    _newChallenge();

    _showMessage(
      _text(
        'Desafio pulado! Aqui está um novo.',
        'Challenge skipped! Here is a new one.',
      ),
      false,
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _boardColor,
          title: Row(
            children: [
              const Icon(Icons.help_outline, color: purple),
              const SizedBox(width: 10),
              Text(
                _text('Como jogar', 'How to play'),
                style: TextStyle(color: _primaryText),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              _text(
                '1. Monte uma igualdade usando os quatro números exibidos.\n\n'
                '2. Existem cinco áreas para adicionar operadores: antes do primeiro número, entre os números e depois do último.\n\n'
                '3. Selecione uma área e toque em um operador ou arraste-o até ela. Você pode adicionar vários operadores na mesma área.\n\n'
                '4. Quando uma área estiver vazia, os números vizinhos serão unidos. Por exemplo: 2, 3 e 4 podem formar 234.\n\n'
                '5. Utilize exatamente um sinal de igualdade (=).\n\n'
                '6. Toque em Verificar para conferir sua resposta.\n\n'
                '7. Toque em um operador colocado no tabuleiro para removê-lo. Use Limpar para apagar todos os operadores.\n\n'
                '8. Se o desafio estiver difícil, toque em Pular desafio para receber outros números.',
                '1. Build an equation using the four numbers displayed.\n\n'
                '2. There are five operator areas: before the first number, between the numbers and after the last number.\n\n'
                '3. Select an area and tap an operator or drag it into that area. You can add multiple operators to the same area.\n\n'
                '4. When an area is empty, neighboring numbers are joined. For example: 2, 3 and 4 can form 234.\n\n'
                '5. Use exactly one equals sign (=).\n\n'
                '6. Tap Check to verify your answer.\n\n'
                '7. Tap an operator on the board to remove it. Use Clear to remove all operators.\n\n'
                '8. If the challenge is too difficult, tap Skip challenge to get new numbers.',
              ),
              style: TextStyle(
                color: _secondaryText,
                height: 1.45,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_text('Entendi', 'Got it')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playSound(String soundName) {
    return GameSound.play(soundName);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(4);
  }

  void _showMessage(String message, bool error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _primaryText,
        title: Text('LizMath - $_translatedLevel'),
        centerTitle: true,
        actions: [
          if (!_isLoadingProgress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '⭐ $score',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: GameSound.enabled
                ? _text('Desativar som', 'Turn sound off')
                : _text('Ativar som', 'Turn sound on'),
            onPressed: () {
              GameSound.toggle();
              setState(() {});
            },
            icon: Icon(
              GameSound.enabled
                  ? Icons.volume_up
                  : Icons.volume_off,
            ),
          ),
          IconButton(
            tooltip: _text('Ajuda', 'Help'),
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingProgress
            ? const Center(
                child: CircularProgressIndicator(color: purple),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _text(
                            'Monte sua expressão!',
                            'Build your expression!',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _text(
                            'Adicione quantos operadores quiser antes, entre ou depois dos números.',
                            'Add as many operators as you want before, between or after the numbers.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _secondaryText),
                        ),
                        const SizedBox(height: 24),

                        _buildBoard(),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: _boardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _text(
                                  'FÓRMULA EM LATEX',
                                  'LATEX FORMULA',
                                ),
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Math.tex(
                                  _currentExpressionLatex(),
                                  mathStyle: MathStyle.display,
                                  textStyle: TextStyle(
                                    color: _primaryText,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        Text(
                          _text('OPERADORES', 'OPERATORS'),
                          style: TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: operators.map((op) {
                            return AnimatedScale(
                              scale: _isReturningOperators &&
                                      _returningOperators.contains(op)
                                  ? 1.16
                                  : 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: Draggable<String>(
                                data: op,
                                feedback: _operatorChip(
                                  op,
                                  dragging: true,
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _operatorChip(op),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    _addOperator(selectedGap, op);
                                  },
                                  child: _operatorChip(op),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _text(
                            'Área selecionada: ${selectedGap + 1} de 5',
                            'Selected area: ${selectedGap + 1} of 5',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _text(
                            'Toque em uma área do tabuleiro para selecioná-la.',
                            'Tap an area on the board to select it.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isVerifying ||
                                        _isReturningOperators
                                    ? null
                                    : _undo,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _buttonText,
                                  side: BorderSide(color: _borderColor),
                                ),
                                child: Text(_text('Desfazer', 'Undo')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isVerifying ||
                                        _isReturningOperators
                                    ? null
                                    : _clear,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _buttonText,
                                  side: BorderSide(color: _borderColor),
                                ),
                                child: Text(_text('Limpar', 'Clear')),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton(
                          onPressed: _isReturningOperators ||
                                  _isVerifying
                              ? null
                              : _verifyExpression,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          child: Text(_text('Verificar', 'Check')),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _isVerifying ||
                                  _isReturningOperators
                              ? null
                              : _newChallenge,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _text('Novo desafio', 'New challenge'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _buttonText,
                            side: const BorderSide(color: purple),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _isReturningOperators ||
                                  _isVerifying
                              ? null
                              : _skipChallenge,
                          icon: const Icon(Icons.skip_next),
                          label: Text(
                            _text('Pular desafio', 'Skip challenge'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _buttonText,
                            side: BorderSide(color: _borderColor),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _boardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: purple.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _text('ÁREA DE MONTAGEM', 'ASSEMBLY AREA'),
            style: TextStyle(
              color: _mutedText,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildGap(0),
                _numberCard(numbers[0]),
                _buildGap(1),
                _numberCard(numbers[1]),
                _buildGap(2),
                _numberCard(numbers[2]),
                _buildGap(3),
                _numberCard(numbers[3]),
                _buildGap(4),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _text(
              'Áreas vazias juntam os números vizinhos.',
              'Empty areas join neighboring numbers.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGap(int index) {
    final selected = selectedGap == index;
    final group = operatorGroups[index];

    final String label;

    if (index == 0) {
      label = _text('ANTES', 'BEFORE');
    } else if (index == 4) {
      label = _text('DEPOIS', 'AFTER');
    } else {
      label = '${index}–${index + 1}';
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return !_isVerifying &&
            !_isReturningOperators &&
            operators.contains(details.data) &&
            !(details.data == '=' && _allOperators.contains('='));
      },
      onAcceptWithDetails: (details) {
        _addOperator(index, details.data);
      },
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (_isReturningOperators || _isVerifying) return;

            setState(() {
              selectedGap = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 82,
            constraints: const BoxConstraints(minHeight: 82),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: hovering
                  ? purple.withValues(alpha: 0.3)
                  : selected
                      ? purple.withValues(alpha: 0.18)
                      : _gapColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering || selected ? purple : _borderColor,
                width: selected || hovering ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? purple : _mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (group.isEmpty)
                  SizedBox(
                    height: 38,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: _mutedText,
                        size: 20,
                      ),
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    runSpacing: 3,
                    children: List.generate(group.length, (operatorIndex) {
                      final operator = group[operatorIndex];

                      return GestureDetector(
                        onTap: () {
                          _removeOperator(index, operatorIndex);
                        },
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 28,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            operator,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _numberCard(String number) {
    return Container(
      width: 48,
      height: 58,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: _primaryText,
          fontSize: 23,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _operatorChip(String op, {bool dragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: purple,
          borderRadius: BorderRadius.circular(12),
          boxShadow: dragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Text(
          op,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ExpressionParser {
  final List<String> tokens;
  final bool allowDecimalDivision;

  int position = 0;

  _ExpressionParser(
    this.tokens, {
    required this.allowDecimalDivision,
  });

  String? get current =>
      position < tokens.length ? tokens[position] : null;

  bool _match(String token) {
    if (current == token) {
      position++;
      return true;
    }

    return false;
  }

  double parse() {
    if (tokens.isEmpty) {
      throw FormatException('Empty expression');
    }

    final result = _parseExpression();

    if (position != tokens.length || !result.isFinite) {
      throw FormatException('Invalid expression');
    }

    return result;
  }

  double _parseExpression() {
    double value = _parseTerm();

    while (true) {
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        break;
      }
    }

    return value;
  }

  double _parseTerm() {
    double value = _parseUnary();

    while (true) {
      if (_match('*')) {
        value *= _parseUnary();
      } else if (_match('/')) {
        final divisor = _parseUnary();

        if (divisor == 0) {
          throw FormatException('Division by zero');
        }

        final result = value / divisor;

        if (!allowDecimalDivision &&
            (result - result.round()).abs() > 0.0000001) {
          throw FormatException('Non-integer division');
        }

        value = result;
      } else {
        break;
      }
    }

    return value;
  }

  double _parseUnary() {
    if (_match('+')) return _parseUnary();
    if (_match('-')) return -_parseUnary();

    if (_match('√')) {
      final value = _parseUnary();

      if (value < 0) {
        throw FormatException('Invalid square root');
      }

      return math.sqrt(value);
    }

    if (_match('∛')) {
      final value = _parseUnary();

      return value < 0
          ? -math.pow(-value, 1 / 3).toDouble()
          : math.pow(value, 1 / 3).toDouble();
    }

    if (_match('|x|')) return _parseUnary().abs();
    if (_match('⌊x⌋')) return _parseUnary().floorToDouble();
    if (_match('⌈x⌉')) return _parseUnary().ceilToDouble();

    return _parsePower();
  }

  double _parsePower() {
    final value = _parsePostfix();

    if (_match('**')) {
      return math.pow(value, _parseUnary()).toDouble();
    }

    return value;
  }

  double _parsePostfix() {
    double value = _parsePrimary();

    while (_match('!')) {
      if (value < 0 ||
          value != value.roundToDouble() ||
          value > 170) {
        throw FormatException('Invalid factorial');
      }

      double result = 1;

      for (int i = 2; i <= value.toInt(); i++) {
        result *= i;
      }

      value = result;
    }

    return value;
  }

  double _parsePrimary() {
    if (_match('(')) {
      final value = _parseExpression();

      if (!_match(')')) {
        throw FormatException('Unclosed parentheses');
      }

      return value;
    }

    final token = current;

    if (token == null) {
      throw FormatException('Incomplete expression');
    }

    final value = double.tryParse(token);

    if (value == null) {
      throw FormatException('Invalid number');
    }

    position++;
    return value;
  }
}
