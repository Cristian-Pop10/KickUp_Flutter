import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/vista/partidos_view.dart';
import 'package:kickup/src/vista/jugadores_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/signup_model.dart';
import '../modelo/user_model.dart';
import '../servicio/auth_service.dart';
import '../vista/perfil_view.dart';

/** Controlador que gestiona todas las operaciones de autenticación y manejo de sesión.
   Proporciona métodos para registro, inicio de sesión, cierre de sesión,
   validación de credenciales y navegación post-autenticación. */
class AuthController {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Registra un nuevo usuario con datos básicos.
     Recibe un SignupModel y lo convierte a UserModel para el registro.
     Retorna true si el registro fue exitoso, false en caso contrario. */
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

  /** Inicia sesión con email y contraseña.
     Retorna true si el login fue exitoso, false en caso contrario. */
  Future<bool> login(String email, String password) async {
    try {
      return await _authService.login(email, password);
    } catch (e) {
      print('Error en el login: $e');
      return false;
    }
  }

  /** Cierra la sesión del usuario actual y navega a la pantalla de login. */
  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();

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

  /** Gestiona el proceso completo de login y navegación posterior.
     Verifica si el usuario es admin antes de navegar.
     Intenta iniciar sesión, guarda el ID del usuario en SharedPreferences
     y navega a la pantalla correcta según el tipo de usuario. */
  Future<void> handleLogin(
      BuildContext context, String email, String password) async {
    try {
      final success = await login(email, password);

      if (success && context.mounted) {
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);

        // Verificar si es admin antes de navegar
        await _navigateBasedOnUserType(context, userId);
      } else if (context.mounted) {
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

  /** Navega a la pantalla correcta según el tipo de usuario.
     Verifica en Firestore si el usuario es admin y navega en consecuencia. */
  Future<void> _navigateBasedOnUserType(
      BuildContext context, String userId) async {
    try {
      // Consultar Firestore para verificar si es admin
      final doc = await _firestore.collection('usuarios').doc(userId).get();

      if (!doc.exists) {
        if (context.mounted) {
          navigateToPartidos(context, userId);
        }
        return;
      }

      final userData = doc.data() as Map<String, dynamic>;
      final isAdmin =
          userData['isAdmin'] == true || userData['esAdmin'] == true;

      if (context.mounted) {
        if (isAdmin) {
          navigateToJugadores(context, userId);
        } else {
          navigateToPartidos(context, userId);
        }
      }
    } catch (e) {
      print('Error verificando tipo de usuario: $e');
      if (context.mounted) {
        // En caso de error, ir a partidos por defecto
        navigateToPartidos(context, userId);
      }
    }
  }

  /** Navega a la pantalla de partidos. */
  void navigateToPartidos(BuildContext context, String userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PartidosView(),
      ),
    );
  }

  /** Navega a la pantalla de jugadores (para admins). */
  void navigateToJugadores(BuildContext context, String userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const JugadoresView(),
      ),
    );
  }

  /** Navega a la pantalla de perfil del usuario. */
  void navigateToPerfil(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PerfilView(),
      ),
    );
  }

  /** Verifica si hay un usuario autenticado actualmente. */
  Future<bool> isAuthenticated() async {
    return await _authService.isUserLoggedIn();
  }

  /** Obtiene el ID del usuario actualmente autenticado. */
  Future<String?> getCurrentUserId() async {
    return _authService.getCurrentUserId();
  }

  /** Valida el formato del email.
     Retorna un mensaje de error si el email no es válido, o null si es correcto. */
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!value.contains('@')) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }

  /** Valida la contraseña.
     Verifica que la contraseña no esté vacía y tenga al menos 6 caracteres. */
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /** Registra un usuario con todos sus datos en Firebase Auth y Firestore.
     Crea la cuenta en Firebase Auth y guarda los datos adicionales en Firestore.
     También almacena información de sesión en SharedPreferences. */
  Future<bool> registerWithUser(UserModel user) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password ?? '',
      );

      final userWithId = user.copyWith(id: credential.user?.uid);
      await _firestore
          .collection('usuarios')
          .doc(credential.user?.uid)
          .set(userWithId.toJson());

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

  /** Obtiene la URL de la imagen de perfil de un usuario.
     Consulta Firestore para obtener la URL de la imagen asociada al userId. */
  Future<String?> getProfileImageUrl(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    return doc.data()?['profileImageUrl'] as String?;
  }
}
