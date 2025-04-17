import 'package:flutter/material.dart';
import 'package:flutter_application/src/vista/log_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/signup_model.dart';
import '../modelo/user_model.dart';
import '../servicio/auth_service.dart';
import '../vista/partidos_screen.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<bool> register(SignupModel signupModel) async {
    return await _authService.register(UserModel(
      email: signupModel.email,
      password: signupModel.password,
    ));
  }

  Future<bool> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<void> logout(BuildContext context) async {
    await _authService.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');

  }

  // Método para manejar el proceso de login y navegación
  Future<void> handleLogin(
      BuildContext context, String email, String password) async {
    try {
      final success = await login(email, password);

      if (success && context.mounted) {
        // Login exitoso, navegar a la pantalla de partidos
        // Guardar sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        // Guardar el ID del usuario después de un login exitoso
        final userId = 'user_1'; // Este valor debe provenir del backend o Firebase
        await prefs.setString('user_id', userId);
        print('✅ Sesión guardada con ID de usuario: $userId');

        // Navegar a la pantalla de Partidos
        navigateToPartidos(context, userId);
      } else if (context.mounted) {
        // Login fallido, mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en el inicio de sesión')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Método para navegar a la pantalla de partidos
  void navigateToPartidos(BuildContext context, String userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PartidosView(userId: userId), // Ahora usa el userId real
      ),
    );
  }

  // Validaciones de email y password
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!value.contains('@')) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}
