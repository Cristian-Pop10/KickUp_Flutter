import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/vista/partidos_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/signup_model.dart';
import '../modelo/user_model.dart';
import '../servicio/auth_service.dart';
import '../vista/perfil_view.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> register(SignupModel signupModel) async {
    try {
      return await _authService.register(UserModel(
        email: signupModel.email,
        password: signupModel.password,
      ));
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      return await _authService.login(email, password);
    } catch (e) {
      print('Error en el login: $e');
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();

      // Navegar de vuelta a la pantalla de login
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error en el logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  // Método para manejar el proceso de login y navegación
  Future<void> handleLogin(
      BuildContext context, String email, String password) async {
    try {
      final success = await login(email, password);

      if (success && context.mounted) {
        // Obtener el ID del usuario después de un login exitoso
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? '';
        
        // Guardar el ID del usuario en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        print('✅ Sesión guardada con ID de usuario: $userId');

        // Navegar a la pantalla de Partidos
        if (context.mounted) {
          navigateToPartidos(context, userId);
        }
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
        builder: (context) => PartidosView(userId: userId),
      ),
    );
  }

  // Método para navegar a la pantalla de perfil
  void navigateToPerfil(BuildContext context) {
    final userId = _authService.getCurrentUserId() ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PerfilView(userId: userId),
      ),
    );
  }

  // Método para verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    return await _authService.isUserLoggedIn();
  }

  // Método para obtener el ID del usuario actual
  Future<String?> getCurrentUserId() async {
    return _authService.getCurrentUserId();
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

  /// Registra un usuario con todos los campos en Firebase Auth y Firestore
  Future<bool> registerWithUser(UserModel user) async {
    try {
      // 1. Registrar en Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password ?? '',
      );

      // 2. Guardar datos adicionales en Firestore
      final userWithId = user.copyWith(id: credential.user?.uid);
      await _firestore
          .collection('usuarios')
          .doc(credential.user?.uid)
          .set(userWithId.toJson());

      // 3. Guardar información en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_id', credential.user?.uid ?? '');
      await prefs.setBool('is_logged_in', true);

      return true;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  Future<String?> getProfileImageUrl(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('usuarios').doc(userId).get();
  return doc.data()?['profileImageUrl'] as String?;
}
}