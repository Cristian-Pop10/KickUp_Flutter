import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/src/modelo/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para obtener el usuario actual
  Future<UserModel?> obtenerUsuarioActual() async {
    try {
      // Obtener el ID del usuario actual
      final userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        // Intentar obtener el ID desde SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString('user_id');
        
        if (storedUserId == null || storedUserId.isEmpty) {
          return null;
        }
        
        // Obtener datos del usuario desde Firestore
        final doc = await _firestore.collection('usuarios').doc(storedUserId).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      } else {
        // Obtener datos del usuario desde Firestore
        final doc = await _firestore.collection('usuarios').doc(userId).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      }
      
      // Si no se encuentra el usuario, crear un modelo con datos básicos
      if (userId != null) {
        final user = _auth.currentUser;
        return UserModel(
          id: userId,
          email: user?.email ?? '',
          nombre: user?.displayName?.split(' ').first ?? '',
          apellidos: user?.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
      }
      
      return null;
    } catch (e) {
      print('Error al obtener el usuario: $e');
      return null;
    }
  }

  // Método para actualizar el perfil del usuario
  Future<bool> actualizarPerfil(UserModel usuario) async {
    try {
      if (usuario.id == null) {
        return false;
      }
      
      // Actualizar datos en Firestore
      await _firestore.collection('usuarios').doc(usuario.id).set(
        usuario.toJson(),
        SetOptions(merge: true),
      );
      
      // Actualizar displayName en Firebase Auth si es necesario
      if (usuario.nombre != null || usuario.apellidos != null) {
        final user = _auth.currentUser;
        if (user != null) {
          final displayName = [
            usuario.nombre ?? '',
            usuario.apellidos ?? '',
          ].where((s) => s.isNotEmpty).join(' ');
          
          if (displayName.isNotEmpty) {
            await user.updateDisplayName(displayName);
          }
        }
      }
      
      return true;
    } catch (e) {
      print('Error al actualizar el perfil: $e');
      return false;
    }
  }
}