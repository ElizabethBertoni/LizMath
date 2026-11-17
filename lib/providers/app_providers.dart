
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themePreferenceKey = 'lizmath_dark_theme';

final themeProvider =
    NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadTheme();
    return true;
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getBool(themePreferenceKey);

    if (savedTheme != null) {
      state = savedTheme;
    }
  }

  Future<void> setTheme(bool isDark) async {
    state = isDark;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(themePreferenceKey, isDark);
  }
}
