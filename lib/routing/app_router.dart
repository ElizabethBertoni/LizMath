
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_gate.dart';

GoRouter createAppRouter({
  required Widget home,
  required Widget Function(String level) game,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return AuthGate(home: home);
        },
      ),
      GoRoute(
        path: '/game/:level',
        builder: (context, state) {
          final level = state.pathParameters['level'] ?? 'Fácil';

          return AuthGate(
            home: game(level),
          );
        },
      ),
    ],
  );
}
