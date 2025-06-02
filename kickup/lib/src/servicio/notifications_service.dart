import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacionesService {
  static const _key = 'notificaciones';

  Future<bool> getEstado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

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
