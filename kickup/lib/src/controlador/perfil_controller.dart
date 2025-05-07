import 'package:flutter_application/src/modelo/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilController {
  // Método para obtener el usuario actual
  Future<UserModel?> obtenerUsuarioActual() async {
    try {
      // En una aplicación real, aquí obtendrías los datos del usuario desde Firebase o tu backend
      // Por ahora, simulamos datos de ejemplo
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        return null;
      }
      
      // Datos de ejemplo
      return UserModel(
        id: userId,
        email: 'usuario@example.com',
        nombre: 'Juan',
        apellidos: 'Pérez',
        edad: 28,
        nivel: 3,
        posicion: 'Delantero',
        telefono: '123456789',
        profileImageUrl: 'assets/profile.jpg',
        // No incluimos createdAt aquí
      );
    } catch (e) {
      print('Error al obtener el usuario: $e');
      return null;
    }
  }

  // Método para actualizar el perfil del usuario
  Future<bool> actualizarPerfil(UserModel usuario) async {
    try {
      // En una aplicación real, aquí actualizarías los datos del usuario en Firebase o tu backend
      // Por ahora, simulamos una actualización exitosa
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      // Simulamos guardar algunos datos en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nombre', usuario.nombre ?? '');
      await prefs.setString('user_apellidos', usuario.apellidos ?? '');
      
      return true;
    } catch (e) {
      print('Error al actualizar el perfil: $e');
      return false;
    }
  }
}