import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/** Servicio para gestionar las notificaciones push de la aplicación.
   Controla el estado de las notificaciones del usuario y maneja
   la suscripción/desuscripción a temas de Firebase Cloud Messaging. */
class NotificacionesService {
  /** Clave utilizada para almacenar el estado de notificaciones en SharedPreferences */
  static const _key = 'notificaciones';

  /** Obtiene el estado actual de las notificaciones del usuario.
     
     Retorna true si las notificaciones están habilitadas, false si están
     deshabilitadas. Por defecto retorna true si no se ha establecido
     ninguna preferencia previamente.*/
  Future<bool> getEstado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  /** Establece el estado de las notificaciones del usuario.
     
     [activo] true para habilitar notificaciones, false para deshabilitarlas.
     
     Cuando se habilitan las notificaciones, se suscribe automáticamente al
     tema "general" de Firebase Cloud Messaging. Cuando se deshabilitan,
     se desuscribe del tema.*/
  Future<void> setEstado(bool activo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, activo);

    if (activo) {
      FirebaseMessaging.instance.subscribeToTopic("general");
    } else {
      FirebaseMessaging.instance.unsubscribeFromTopic("general");
    }
  }
}
