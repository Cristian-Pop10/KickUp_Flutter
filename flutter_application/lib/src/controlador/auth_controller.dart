import 'package:firebase_auth/firebase_auth.dart';
import '../modelo/signup_model.dart';
import '../modelo/user_model.dart';
import '../servicio/auth_service.dart';
import '../servicio/user_service.dart';

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

  Future<void> logout() async {
    await _authService.logout();
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
