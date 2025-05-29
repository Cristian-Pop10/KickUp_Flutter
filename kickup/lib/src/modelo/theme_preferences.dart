import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const THEME_MODE = 'MODE';
  static const DARK = 'DARK';
  static const LIGHT = 'LIGHT';

  Future<void> setModeTheme(String theme) async {
    if (theme == DARK || theme == LIGHT) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(THEME_MODE, theme);
      print('Theme mode set to: $theme');
    } else {
      throw ArgumentError('Invalid theme mode: $theme');
    }
  }

  Future<String> getModeTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString(THEME_MODE);
    return theme ?? LIGHT; // Valor por defecto: LIGHT
  }
}
