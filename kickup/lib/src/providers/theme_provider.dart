import 'package:flutter/material.dart';
import 'package:kickup/src/preferences/pref_usuarios.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = PreferenciasUsuario.isDarkMode;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    PreferenciasUsuario.isDarkMode = isOn;
    notifyListeners();
  }

  Future<void> loadThemeFromPrefs() async {
    _isDarkMode = PreferenciasUsuario.isDarkMode;
    notifyListeners();
  }
}
