import 'package:firebase_auth/firebase_auth.dart';
import '../modelo/signup_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> register(UserModel user) async {
    try {
      // Registro real en Firebase Auth
      await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // Puedes manejar errores más específicos aquí
      print('Error de Firebase: ${e.message}');
      return false;
    } catch (e) {
      print('Error general: $e');
      return false;
    }
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
