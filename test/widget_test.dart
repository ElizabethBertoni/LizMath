
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:emplake/auth_gate.dart';

void main() {
  testWidgets('Texto é exibido em português', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [
          Locale('pt'),
          Locale('en'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) {
            return Text(
              localizedText(
                context,
                'Desafie sua mente.',
                'Challenge your mind.',
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Desafie sua mente.'), findsOneWidget);
  });

  testWidgets('Texto é exibido em inglês', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('pt'),
          Locale('en'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) {
            return Text(
              localizedText(
                context,
                'Desafie sua mente.',
                'Challenge your mind.',
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Challenge your mind.'), findsOneWidget);
  });
}
