
import 'math_engine.dart';

void main() {
  final engine = MathEngine(
    level: GameLevel.facil,
    availableNumbers: [2, 3, 5, 8],
  );

  print(engine.calculate('5 / 2'));
  print(engine.calculate('(2 + 3) * 8'));
  print(engine.calculate('sqrt(8)'));
}
