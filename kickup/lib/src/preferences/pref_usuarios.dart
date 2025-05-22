import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static late SharedPreferences _prefs;

  // Inicializar las preferencias
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Última página visitada
  static String get ultimaPagina =>
      _prefs.getString('ultimaPagina') ?? '/login';

  static set ultimaPagina(String value) =>
      _prefs.setString('ultimaPagina', value);

  // Email del usuario
  static String get userEmail => _prefs.getString('user_email') ?? '';

  static set userEmail(String value) => _prefs.setString('user_email', value);

  // ID del usuario
  static String get userId => _prefs.getString('user_id') ?? '';

  static set userId(String value) => _prefs.setString('user_id', value);

  // Nombre del usuario
  static String get userName => _prefs.getString('user_name') ?? '';

  static set userName(String value) => _prefs.setString('user_name', value);

  // Tema oscuro
  static bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? false;

  static set isDarkMode(bool value) => _prefs.setBool('is_dark_mode', value);

  // Notificaciones
  static bool get notificationsEnabled =>
      _prefs.getBool('notifications_enabled') ?? true;

  static set notificationsEnabled(bool value) =>
      _prefs.setBool('notifications_enabled', value);

  // Limpiar todas las preferencias (logout)
  static Future<void> clear() async {
    // Guardar algunas preferencias que no deben eliminarse
    final bool darkMode = isDarkMode;
    final bool notifications = notificationsEnabled;

    // Limpiar todas las preferencias
    await _prefs.clear();

    // Restaurar las preferencias que no deben eliminarse
    isDarkMode = darkMode;
    notificationsEnabled = notifications;
  }
}
