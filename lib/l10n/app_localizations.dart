
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('pt'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    )!;
  }

  static const Map<String, Map<String, String>> _translations = {
    'pt': {
      // Identidade do aplicativo
      'appName': 'LizMath',

      // Página inicial
      'welcome': 'A matemática pode\nser um jogo.',
      'tagline': 'DESAFIE SUA MENTE',
      'description':
          'Use os operadores, encontre soluções e supere seus limites.',
      'nextChallenge': 'SEU PRÓXIMO DESAFIO',
      'challengeDescription':
          'Cada partida traz números aleatórios com pelo menos uma solução possível.',

      // Dificuldades
      'chooseDifficulty': 'Escolha sua dificuldade',
      'difficultyDescription': 'Cada nível oferece novos operadores.',
      'easy': 'Fácil',
      'medium': 'Intermediário',
      'advanced': 'Avançado',
      'hard': 'Difícil',
      'easyDescription': 'Todos os operadores',
      'mediumDescription': 'Um pouco mais de desafio',
      'advancedDescription': 'Exige mais raciocínio',
      'hardDescription': 'Para os mais experientes',
      'startGame': 'COMEÇAR A JOGAR',

      // Ranking
      'ranking': 'RANKING GLOBAL',
      'globalRanking': 'Ranking Global',
      'topPlayers': 'OS MELHORES JOGADORES',
      'rankingDescription': 'Resolva desafios e conquiste seu lugar!',
      'noPlayers':
          'Ainda não existem jogadores no ranking.\nSeja o primeiro a marcar pontos!',
      'rankingError': 'Não foi possível carregar o ranking.',
      'player': 'Jogador',
      'points': 'pontos',

      // Jogo
      'help': 'Ajuda',
      'skip': 'Pular desafio',
      'verify': 'Verificar',

      // Navegação inferior
      'navHome': 'Início',
      'navPlay': 'Jogar',
      'navRanking': 'Ranking',
      'navProfile': 'Perfil',

      // Perfil
      'profileTitle': 'Meu Perfil',
      'yourProgress': 'Meu progresso',
      'completedChallenges': 'Desafios concluídos',
      'settings': 'Configurações',
      'sound': 'Efeitos sonoros',
      'profileError': 'Não foi possível carregar seu progresso.',

      // Configurações
      'language': 'Idioma',
      'portuguese': 'Português',
      'english': 'Inglês',
      'logout': 'Sair da conta',
      'soundOn': 'Desativar som',
      'soundOff': 'Ativar som',
      'theme': 'Tema',
      'darkTheme': 'Escuro',
      'lightTheme': 'Claro',

      // Rodapé
      'footer': 'LIZMATH  •  DESAFIE SEU RACIOCÍNIO',
    },

    'en': {
      // App identity
      'appName': 'LizMath',

      // Home page
      'welcome': 'Mathematics can\nbe a game.',
      'tagline': 'CHALLENGE YOUR MIND',
      'description':
          'Use operators, find solutions and push your limits.',
      'nextChallenge': 'YOUR NEXT CHALLENGE',
      'challengeDescription':
          'Each game brings random numbers with at least one possible solution.',

      // Difficulties
      'chooseDifficulty': 'Choose your difficulty',
      'difficultyDescription': 'Each level offers new operators.',
      'easy': 'Easy',
      'medium': 'Intermediate',
      'advanced': 'Advanced',
      'hard': 'Hard',
      'easyDescription': 'All operators',
      'mediumDescription': 'A little more challenging',
      'advancedDescription': 'Requires more reasoning',
      'hardDescription': 'For experienced players',
      'startGame': 'START PLAYING',

      // Ranking
      'ranking': 'GLOBAL RANKING',
      'globalRanking': 'Global Ranking',
      'topPlayers': 'TOP PLAYERS',
      'rankingDescription': 'Solve challenges and earn your place!',
      'noPlayers':
          'There are no players in the ranking yet.\nBe the first to score points!',
      'rankingError': 'Could not load the ranking.',
      'player': 'Player',
      'points': 'points',

      // Game
      'help': 'Help',
      'skip': 'Skip challenge',
      'verify': 'Check',

      // Bottom navigation
      'navHome': 'Home',
      'navPlay': 'Play',
      'navRanking': 'Ranking',
      'navProfile': 'Profile',

      // Profile
      'profileTitle': 'My Profile',
      'yourProgress': 'My progress',
      'completedChallenges': 'Completed challenges',
      'settings': 'Settings',
      'sound': 'Sound effects',
      'profileError': 'Could not load your progress.',

      // Settings
      'language': 'Language',
      'portuguese': 'Portuguese',
      'english': 'English',
      'logout': 'Sign out',
      'soundOn': 'Turn sound off',
      'soundOff': 'Turn sound on',
      'theme': 'Theme',
      'darkTheme': 'Dark',
      'lightTheme': 'Light',

      // Footer
      'footer': 'LIZMATH  •  CHALLENGE YOUR REASONING',
    },
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['pt']?[key] ??
        key;
  }

  String get(String key) => translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
