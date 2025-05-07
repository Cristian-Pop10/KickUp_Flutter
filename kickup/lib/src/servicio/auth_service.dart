import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/user_model.dart';

class AuthService {
  // Método para registrar un nuevo usuario
  Future<bool> register(UserModel user) async {
    try {
      // Aquí normalmente usarías Firebase, pero por ahora simulamos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email); // Ahora email no es nulo
      await prefs.setString('user_password', user.password ?? '');
      return true;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  // Método para iniciar sesión
  Future<bool> login(String email, String password) async {
    try {
      // Simulamos una verificación de credenciales
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('user_email');
      final storedPassword = prefs.getString('user_password');
      
      // Si no hay credenciales almacenadas, permitimos cualquier login para pruebas
      if (storedEmail == null || storedPassword == null) {
        return true;
      }
      
      return email == storedEmail && password == storedPassword;
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
  }

  // Método para verificar si el usuario está autenticado
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
}