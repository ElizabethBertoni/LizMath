
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  static User get _currentUser {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user;
  }

  static DocumentReference<Map<String, dynamic>> get _userDocument {
    return _db.collection('users').doc(_userId);
  }

  static DocumentReference<Map<String, dynamic>> get _leaderboardDocument {
    return _db.collection('leaderboard').doc(_userId);
  }

  // Recupera a pontuação e os desafios resolvidos.
  static Future<Map<String, dynamic>> getProgress() async {
    final document = await _userDocument.get();

    if (!document.exists) {
      return {
        'score': 0,
        'solvedChallenges': <String>[],
      };
    }

    final data = document.data()!;

    return {
      'score': (data['score'] as num?)?.toInt() ?? 0,
      'solvedChallenges': List<String>.from(
        data['solvedChallenges'] ?? [],
      ),
    };
  }

  // Registra um desafio, adiciona pontos e atualiza o ranking.
  // Retorna false se o desafio já tiver sido resolvido.
  static Future<bool> registerSolvedChallenge(
    String challengeId, {
    int points = 10,
  }) async {
    final userDocument = _userDocument;
    final leaderboardDocument = _leaderboardDocument;
    final user = _currentUser;

    return _db.runTransaction<bool>((transaction) async {
      final document = await transaction.get(userDocument);
      final data = document.data() ?? {};

      final solvedChallenges = List<String>.from(
        data['solvedChallenges'] ?? [],
      );

      if (solvedChallenges.contains(challengeId)) {
        return false;
      }

      final currentScore =
          (data['score'] as num?)?.toInt() ?? 0;

      final newScore = currentScore + points;

      final name = (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : (user.displayName ?? 'Jogador');

      // Atualiza o progresso privado do jogador.
      transaction.set(
        userDocument,
        {
          'name': name,
          'score': newScore,
          'solvedChallenges': FieldValue.arrayUnion([challengeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Atualiza os dados públicos do ranking.
      transaction.set(
        leaderboardDocument,
        {
          'name': name,
          'score': newScore,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    });
  }

  // Verifica se um desafio já foi resolvido.
  static Future<bool> hasSolvedChallenge(String challengeId) async {
    final progress = await getProgress();

    final solvedChallenges =
        List<String>.from(progress['solvedChallenges']);

    return solvedChallenges.contains(challengeId);
  }

  // Recupera o ranking global ordenado pela pontuação.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .snapshots();
  }
}
