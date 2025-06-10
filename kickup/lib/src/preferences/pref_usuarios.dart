import 'package:shared_preferences/shared_preferences.dart';

/** Clase utilitaria para gestionar las preferencias del usuario de forma centralizada.
   Proporciona una interfaz simplificada para acceder y modificar configuraciones
   persistentes utilizando SharedPreferences como almacenamiento local. */
class PreferenciasUsuario {
  /** Instancia de SharedPreferences para el almacenamiento local */
  static late SharedPreferences _prefs;

  /** Inicializa las preferencias del usuario.
     Debe llamarse al inicio de la aplicación antes de usar cualquier
     getter o setter de esta clase.*/
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /** Obtiene la última página visitada por el usuario.
     Retorna '/login' como valor por defecto si no se ha establecido ninguna. */
  static String get ultimaPagina =>
      _prefs.getString('ultimaPagina') ?? '/login';

  /** Establece la última página visitada por el usuario.
     Útil para restaurar la navegación después de reiniciar la app. */
  static set ultimaPagina(String value) =>
      _prefs.setString('ultimaPagina', value);

  /** Obtiene el email del usuario almacenado localmente.
     Retorna una cadena vacía si no se ha establecido ningún email. */
  static String get userEmail => _prefs.getString('user_email') ?? '';

  /** Establece el email del usuario para almacenamiento local.
     Se utiliza para recordar el último email usado en el login. */
  static set userEmail(String value) => _prefs.setString('user_email', value);

  /** Obtiene el nombre del usuario almacenado localmente.
     Retorna una cadena vacía si no se ha establecido ningún nombre. */
  static String get userName => _prefs.getString('user_name') ?? '';

  /** Establece el nombre del usuario para almacenamiento local.
     Útil para personalizar la interfaz sin consultar la base de datos. */
  static set userName(String value) => _prefs.setString('user_name', value);

  /** Obtiene la preferencia de tema oscuro del usuario.
     Retorna false por defecto (tema claro). */
  static bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? false;

  /** Establece la preferencia de tema oscuro del usuario.
     true para tema oscuro, false para tema claro. */
  static set isDarkMode(bool value) => _prefs.setBool('is_dark_mode', value);

  /** Obtiene la configuración de notificaciones del usuario.
     Retorna true por defecto (notificaciones habilitadas). */
  static bool get notificationsEnabled =>
      _prefs.getBool('notifications_enabled') ?? true;

  /** Establece la configuración de notificaciones del usuario.
     true para habilitar notificaciones, false para deshabilitarlas. */
  static set notificationsEnabled(bool value) =>
      _prefs.setBool('notifications_enabled', value);

  /** Limpia todas las preferencias del usuario excepto configuraciones globales.
     Se ejecuta típicamente durante el logout para eliminar datos personales
     pero conservar preferencias de la aplicación como tema y notificaciones.*/
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