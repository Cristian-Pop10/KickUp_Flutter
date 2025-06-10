import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelo/user_model.dart';

/** Servicio de autenticación que gestiona el registro, inicio de sesión y
   estado de autenticación de usuarios utilizando Firebase Auth y Firestore.
   También maneja la persistencia local de datos de sesión. */
class AuthService {
  /** Instancia de Firebase Authentication para gestión de usuarios */
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /** Instancia de Firestore para almacenar datos adicionales del usuario */
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Registra un nuevo usuario en la aplicación.
     
     Crea una cuenta en Firebase Auth, guarda los datos del perfil en Firestore
     y establece la sesión local en SharedPreferences.
     
     [user] Modelo del usuario con email, password y datos del perfil.
     
     Retorna true si el registro fue exitoso, false en caso contrario.*/
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
        await _firestore
            .collection('usuarios')
            .doc(userId)
            .set(userWithId.toJson());

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

  /** Inicia sesión con email y contraseña.
     
     Autentica al usuario con Firebase Auth y establece la sesión local
     en SharedPreferences para mantener el estado de autenticación.
     
     [email] Dirección de correo electrónico del usuario.
     [password] Contraseña del usuario.
     
     Retorna true si el inicio de sesión fue exitoso, false en caso contrario.*/
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

  /** Cierra la sesión del usuario actual.
     
     Desautentica al usuario de Firebase Auth y limpia los datos de sesión
     almacenados en SharedPreferences.
     
     Lanza una excepción si ocurre un error durante el proceso.*/
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

  /** Verifica si el usuario está actualmente autenticado.
     
     Comprueba tanto el estado de Firebase Auth como las preferencias locales
     para determinar si hay una sesión activa válida.
     
     Retorna true si el usuario está autenticado, false en caso contrario.*/
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

  /** Obtiene el usuario actual de Firebase Auth.
     
     Retorna el objeto User de Firebase si hay un usuario autenticado,
     null en caso contrario.*/
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /** Obtiene el ID único del usuario actual.
     Retorna el UID del usuario autenticado o null si no hay sesión activa. */
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
