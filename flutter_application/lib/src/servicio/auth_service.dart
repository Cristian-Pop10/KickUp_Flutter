import 'package:firebase_auth/firebase_auth.dart';
import '../modelo/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el usuario autenticado actual
  User? get currentUser => _auth.currentUser;

  // Escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Método para registrar un usuario
  Future<bool> register(UserModel user) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase: ${e.message}');
      return false;
    } catch (e) {
      print('Error general: $e');
      return false;
    }
  }

  // Método para iniciar sesión
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No se encontró un usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        print('La contraseña es incorrecta.');
      } else {
        print('Error de Firebase: ${e.message}');
      }
      return false;
    } catch (e) {
      print('Error general: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('Sesión cerrada exitosamente.');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }
}