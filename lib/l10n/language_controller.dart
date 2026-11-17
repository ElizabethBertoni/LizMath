
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('pt');

  Locale get locale => _locale;

  LanguageController() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();

    final languageCode = preferences.getString('languageCode') ?? 'pt';

    _locale = Locale(languageCode);

    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'pt' && languageCode != 'en') {
      return;
    }

    _locale = Locale(languageCode);

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('languageCode', languageCode);

    notifyListeners();
  }
}
