
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/firestore_service.dart';
import 'l10n/app_localizations.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  static const Color purple = Color(0xFF8065F6);
  static const Color gold = Color(0xFFF2B75B);

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context);

    final isEnglish =
        Localizations.localeOf(context).languageCode == 'en';

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF10121B)
        : const Color(0xFFF5F5FA);

    final primaryText =
        isDark ? Colors.white : const Color(0xFF202033);

    final secondaryText =
        isDark ? Colors.white54 : const Color(0xFF777589);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryText,
        title: Text(
          app.get('globalRanking'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.getLeaderboard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: purple,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.error_outline,
                    message: app.get('rankingError'),
                    isDark: isDark,
                  );
                }

                final players = snapshot.data?.docs ?? [];

                if (players.isEmpty) {
                  return _buildMessage(
                    icon: Icons.emoji_events_outlined,
                    message: app.get('noPlayers'),
                    isDark: isDark,
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 25),

                    const Icon(
                      Icons.emoji_events,
                      color: gold,
                      size: 55,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      app.get('topPlayers').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF9C87FF),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      app.get('rankingDescription'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          25,
                        ),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final data = players[index].data();

                          final name = data['name'] as String? ??
                              app.get('player');

                          final score =
                              (data['score'] as num?)?.toInt() ?? 0;

                          return _buildPlayerTile(
                            position: index + 1,
                            name: name,
                            score: score,
                            isEnglish: isEnglish,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerTile({
    required int position,
    required String name,
    required int score,
    required bool isEnglish,
    required bool isDark,
  }) {
    Color positionColor = isDark
        ? Colors.white54
        : const Color(0xFF88869A);

    IconData? positionIcon;

    if (position == 1) {
      positionColor = const Color(0xFFFFD45C);
      positionIcon = Icons.emoji_events;
    } else if (position == 2) {
      positionColor = const Color(0xFFBFC7D5);
      positionIcon = Icons.emoji_events;
    } else if (position == 3) {
      positionColor = const Color(0xFFCD8B5A);
      positionIcon = Icons.emoji_events;
    }

    final cardColor = isDark
        ? const Color(0xFF1B1E2B)
        : Colors.white;

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF202033);

    final defaultBorder = isDark
        ? const Color(0xFF303346)
        : const Color(0xFFE0DDEC);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: position <= 3
              ? positionColor.withValues(alpha: 0.45)
              : defaultBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: positionIcon != null
                ? Icon(
                    positionIcon,
                    color: positionColor,
                    size: 27,
                  )
                : Text(
                    isEnglish ? '#$position' : '$positionº',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: positionColor,
                    ),
                  ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Row(
            children: [
              const Icon(
                Icons.star,
                color: gold,
                size: 19,
              ),
              const SizedBox(width: 5),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    required bool isDark,
  }) {
    final textColor = isDark
        ? Colors.white70
        : const Color(0xFF68677A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF9C87FF),
              size: 55,
            ),

            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
