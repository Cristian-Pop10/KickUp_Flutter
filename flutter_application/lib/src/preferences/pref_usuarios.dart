import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static late SharedPreferences _prefs;

  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get ultimaPagina {
    return _prefs.getString('ultimaPagina') ?? '/login';
  }

  set ultimaPagina(String value) {
    _prefs.setString('ultimaPagina', value);
  }

  String get userEmail {
    return _prefs.getString('user_email') ?? '';
  }

  set userEmail(String value) {
    _prefs.setString('user_email', value);
  }
}
