
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'game/game_screen.dart';
import 'sound_manager.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'ranking_screen.dart';
import 'services/firestore_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_controller.dart';
import 'providers/app_providers.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: LizMathApp(),
    ),
  );
}

class LizMathApp extends ConsumerStatefulWidget {
  const LizMathApp({super.key});

  @override
  ConsumerState<LizMathApp> createState() => _LizMathAppState();
}

class _LizMathAppState extends ConsumerState<LizMathApp> {
  late final LanguageController languageController;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();

    languageController = LanguageController();

    router = createAppRouter(
      home: HomeRoute(
        languageController: languageController,
      ),
      game: (level) => GameScreen(level: level),
    );
  }

  @override
  void dispose() {
    languageController.dispose();
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = ref.watch(themeProvider);

    return AnimatedBuilder(
      animation: languageController,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'LizMath',
          locale: languageController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            FirebaseUILocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F4FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8065F6),
              brightness: Brightness.light,
            ),
            cardColor: Colors.white,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF10121B),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8065F6),
              brightness: Brightness.dark,
            ),
            cardColor: const Color(0xFF191C29),
            fontFamily: 'Roboto',
          ),
          routerConfig: router,
        );
      },
    );
  }
}

// Página inicial conectada ao Riverpod.
class HomeRoute extends ConsumerWidget {
  final LanguageController languageController;

  const HomeRoute({
    super.key,
    required this.languageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = ref.watch(themeProvider);

    return AuthGate(
      home: HomeScreen(
        languageController: languageController,
        isDarkTheme: isDarkTheme,
        onThemeChanged: (value) {
          ref.read(themeProvider.notifier).setTheme(value);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final LanguageController languageController;
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.languageController,
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _lastTabKey = 'lastSelectedTab';

  static const Color purple = Color(0xFF8065F6);

  int selectedTab = 0;
  bool _isTabLoaded = false;

  String selectedLevel = 'Fácil';

  late Future<Map<String, dynamic>> _progressFuture;

  bool get _isDark => widget.isDarkTheme;

  Color get _cardColor =>
      _isDark ? const Color(0xFF1B1E2B) : Colors.white;

  Color get _navigationColor =>
      _isDark ? const Color(0xFF191C29) : Colors.white;

  Color get _secondaryText =>
      _isDark ? Colors.white54 : Colors.black54;

  Color get _borderColor =>
      _isDark ? const Color(0xFF303346) : const Color(0xFFE0DDEC);

  Color get _primaryText =>
      _isDark ? Colors.white : const Color(0xFF242236);

  final List<Map<String, dynamic>> levels = [
    {
      'name': 'Fácil',
      'key': 'easy',
      'descriptionKey': 'easyDescription',
      'color': const Color(0xFF43C99B),
      'icon': Icons.sentiment_satisfied_alt,
    },
    {
      'name': 'Intermediário',
      'key': 'medium',
      'descriptionKey': 'mediumDescription',
      'color': const Color(0xFF61A5FA),
      'icon': Icons.psychology_alt,
    },
    {
      'name': 'Avançado',
      'key': 'advanced',
      'descriptionKey': 'advancedDescription',
      'color': const Color(0xFFF2B75B),
      'icon': Icons.local_fire_department,
    },
    {
      'name': 'Difícil',
      'key': 'hard',
      'descriptionKey': 'hardDescription',
      'color': const Color(0xFFEA718B),
      'icon': Icons.bolt,
    },
  ];

  @override
  void initState() {
    super.initState();

    _progressFuture = FirestoreService.getProgress();
    _loadLastTab();
  }

  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTab = prefs.getInt(_lastTabKey) ?? 0;

    if (!mounted) return;

    setState(() {
      selectedTab = savedTab >= 0 && savedTab < 4 ? savedTab : 0;
      _isTabLoaded = true;
    });
  }

  void _changeTab(int index) {
    if (index < 0 || index >= 4) return;

    setState(() {
      selectedTab = index;
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_lastTabKey, index);
    });

    if (index == 3) {
      _refreshProgress();
    }
  }

  void _refreshProgress() {
    setState(() {
      _progressFuture = FirestoreService.getProgress();
    });
  }

  Future<void> startGame() async {
    await context.push(
      '/game/${Uri.encodeComponent(selectedLevel)}',
    );

    if (!mounted) return;

    _refreshProgress();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context);

    if (!_isTabLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: purple),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            _buildHomePage(app),
            _buildPlayPage(app),
            const RankingScreen(),
            _buildProfilePage(app),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: _changeTab,
        backgroundColor: _navigationColor,
        indicatorColor: purple.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: app.get('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.gamepad_outlined),
            selectedIcon: const Icon(Icons.gamepad),
            label: app.get('navPlay'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: app.get('navRanking'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: app.get('navProfile'),
          ),
        ],
      ),
    );
  }

  // TELA INICIAL

  Widget _buildHomePage(AppLocalizations app) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 60 : 24,
            vertical: 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 55),
                  _buildWelcome(app),
                  const SizedBox(height: 35),
                  _buildChallengeCard(app),
                  const SizedBox(height: 35),
                  _buildStartButton(app),
                  const SizedBox(height: 35),
                  _buildFooter(app),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.functions,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'LIZMATH',
          style: TextStyle(
            color: _primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(AppLocalizations app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.get('tagline'),
          style: const TextStyle(
            color: Color(0xFF9C87FF),
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          app.get('welcome'),
          style: TextStyle(
            color: _primaryText,
            fontSize: 42,
            height: 1.15,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          app.get('description'),
          style: TextStyle(
            fontSize: 15,
            color: _secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(AppLocalizations app) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [
                  Color(0xFF282343),
                  Color(0xFF1B1D2D),
                ]
              : const [
                  Color(0xFFEAE5FF),
                  Color(0xFFF5F2FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDark
              ? const Color(0xFF494064)
              : const Color(0xFFD5CCF5),
        ),
      ),
      child: Column(
        children: [
          Text(
            app.get('nextChallenge'),
            style: const TextStyle(
              color: Color(0xFF9C87FF),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '?  ·  ?  ·  ?  ·  ?',
            style: TextStyle(
              color: _primaryText,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            app.get('challengeDescription'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(AppLocalizations app) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: () => _changeTab(1),
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              app.get('startGame'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations app) {
    return Center(
      child: Text(
        app.get('footer'),
        style: TextStyle(
          color: _secondaryText.withValues(alpha: 0.6),
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // TELA DE JOGO / DIFICULDADE

  Widget _buildPlayPage(AppLocalizations app) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 60 : 24,
            vertical: 35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.get('chooseDifficulty'),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.get('difficultyDescription'),
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildLevels(isWide, app),
                  const SizedBox(height: 30),
                  _buildStartButtonForGame(app),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevels(bool isWide, AppLocalizations app) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: levels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 135,
      ),
      itemBuilder: (context, index) {
        final level = levels[index];
        final isSelected = selectedLevel == level['name'];

        return InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            setState(() {
              selectedLevel = level['name'] as String;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected
                  ? (level['color'] as Color).withValues(alpha: 0.13)
                  : _cardColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: isSelected
                    ? level['color'] as Color
                    : _borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  level['icon'] as IconData,
                  color: level['color'] as Color,
                  size: 25,
                ),
                const Spacer(),
                Text(
                  app.get(level['key'] as String),
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.get(level['descriptionKey'] as String),
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButtonForGame(AppLocalizations app) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              app.get('startGame'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  // TELA DE PERFIL

  Widget _buildProfilePage(AppLocalizations app) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? {};
        final score = (progress['score'] as num?)?.toInt() ?? 0;

        final solvedChallenges =
            (progress['solvedChallenges'] as List?)?.length ?? 0;

        final name = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : app.get('player');

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.get('profileTitle'),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            color: purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    app.get('yourProgress'),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: CircularProgressIndicator(color: purple),
                    )
                  else if (snapshot.hasError)
                    Text(
                      app.get('profileError'),
                      style: const TextStyle(color: Colors.redAccent),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.stars,
                            value: score.toString(),
                            label: app.get('points'),
                            color: const Color(0xFFF2B75B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_outline,
                            value: solvedChallenges.toString(),
                            label: app.get('completedChallenges'),
                            color: const Color(0xFF43C99B),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  Text(
                    app.get('settings'),
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileSetting(
                    icon: Icons.language,
                    title: app.get('language'),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.languageController.locale.languageCode,
                        dropdownColor: _cardColor,
                        style: TextStyle(color: _primaryText),
                        items: [
                          DropdownMenuItem(
                            value: 'pt',
                            child: Text(app.get('portuguese')),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(app.get('english')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            widget.languageController.changeLanguage(value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileSetting(
                    icon: _isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: app.get('theme'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isDark
                              ? app.get('darkTheme')
                              : app.get('lightTheme'),
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: widget.isDarkTheme,
                          activeThumbColor: purple,
                          onChanged: widget.onThemeChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileSetting(
                    icon: GameSound.enabled
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                    title: app.get('sound'),
                    trailing: Switch(
                      value: GameSound.enabled,
                      activeThumbColor: purple,
                      onChanged: (value) {
                        setState(() {
                          GameSound.toggle();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(app.get('logout')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA718B),
                        side: const BorderSide(
                          color: Color(0xFFEA718B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 22,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: _primaryText,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetting({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9C87FF)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _primaryText,
                fontSize: 14,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
