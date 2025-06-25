import 'package:shared_preferences/shared_preferences.dart';

/** Clase utilitaria para gestionar las preferencias de tema de la aplicación.
   Permite guardar y recuperar la configuración de tema (claro/oscuro) 
   utilizando SharedPreferences para persistencia local. */
class ThemePreferences {
  /** Clave utilizada para almacenar el modo de tema en SharedPreferences */
  static const THEME_MODE = 'MODE';

  /** Constante que representa el tema oscuro */
  static const DARK = 'DARK';

  /** Constante que representa el tema claro */
  static const LIGHT = 'LIGHT';

  /** Guarda el modo de tema seleccionado en las preferencias locales.*/
  Future<void> setModeTheme(String theme) async {
    if (theme == DARK || theme == LIGHT) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(THEME_MODE, theme);
      print('Theme mode set to: $theme');
    } else {
      throw ArgumentError('Invalid theme mode: $theme');
    }
  }

  /** Recupera el modo de tema guardado en las preferencias locales.     
     Retorna el tema guardado o LIGHT como valor por defecto si no
     se ha establecido ninguna preferencia previamente.*/
  Future<String> getModeTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString(THEME_MODE);
    return theme ?? LIGHT; // Valor por defecto: LIGHT
  }
}
