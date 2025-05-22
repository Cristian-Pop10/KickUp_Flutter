import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para registrar un nuevo usuario
  Future<bool> register(UserModel user) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password ?? '',
      );
      
      // Guardar datos adicionales en Firestore
      final userId = userCredential.user?.uid;
      if (userId != null) {
        final userWithId = user.copyWith(id: userId);
        await _firestore.collection('usuarios').doc(userId).set(userWithId.toJson());
        
        // Guardar información en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_id', userId);
        await prefs.setBool('is_logged_in', true);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  // Método para iniciar sesión
  Future<bool> login(String email, String password) async {
    try {
      // Iniciar sesión con Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Guardar información en SharedPreferences
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('user_id', userCredential.user!.uid);
        await prefs.setBool('is_logged_in', true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
      
      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
    } catch (e) {
      print('Error en el cierre de sesión: $e');
      rethrow;
    }
  }

  // Método para verificar si el usuario está autenticado
  Future<bool> isUserLoggedIn() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('is_logged_in') ?? false;
      }
      return false;
    } catch (e) {
      print('Error al verificar autenticación: $e');
      return false;
    }
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Método para obtener el ID del usuario actual
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}