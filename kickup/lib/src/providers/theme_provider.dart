import 'package:flutter/material.dart';
import 'package:kickup/src/preferences/pref_usuarios.dart';

/** Provider que gestiona el estado del tema de la aplicación.
   Utiliza ChangeNotifier para notificar cambios a los widgets que escuchan
   y sincroniza automáticamente con las preferencias del usuario para
   mantener la configuración entre sesiones. */
class ThemeProvider with ChangeNotifier {
  /** Estado interno del modo oscuro, inicializado desde las preferencias */
  bool _isDarkMode = PreferenciasUsuario.isDarkMode;

  /** Obtiene el estado actual del modo oscuro.
     Retorna true si el tema oscuro está activado, false para tema claro. */
  bool get isDarkMode => _isDarkMode;

  /** Cambia el tema de la aplicación y persiste la configuración.
     
     [isOn] true para activar el tema oscuro, false para el tema claro.
     Actualiza tanto el estado interno como las preferencias del usuario
     y notifica a todos los widgets que escuchan este provider.*/
  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    PreferenciasUsuario.isDarkMode = isOn;
    notifyListeners();
  }

  /** Carga la configuración de tema desde las preferencias almacenadas.
     Útil para sincronizar el estado del provider con las preferencias
     guardadas, especialmente al inicializar la aplicación.*/
  Future<void> loadThemeFromPrefs() async {
    _isDarkMode = PreferenciasUsuario.isDarkMode;
    notifyListeners();
  }
}