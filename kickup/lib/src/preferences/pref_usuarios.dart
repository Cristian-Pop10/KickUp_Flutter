import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get ultimaPagina =>
      _prefs.getString('ultimaPagina') ?? '/login';

  static set ultimaPagina(String value) =>
      _prefs.setString('ultimaPagina', value);

  static String get userEmail => _prefs.getString('user_email') ?? '';

  static set userEmail(String value) => _prefs.setString('user_email', value);

  static String get userId => _prefs.getString('user_id') ?? '';

  static set userId(String value) => _prefs.setString('user_id', value);
}
