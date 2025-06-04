import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickup/src/modelo/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Método para obtener el usuario actual
  Future<UserModel?> obtenerUsuarioActual() async {
    try {
      print('🔍 Obteniendo usuario actual...');
      
      // Obtener el ID del usuario actual
      final userId = _auth.currentUser?.uid;
      print('👤 Usuario ID desde Auth: $userId');

      if (userId == null) {
        print('⚠️ No hay usuario autenticado en Firebase Auth');
        // Intentar obtener el ID desde SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString('user_id');
        print('💾 Usuario ID desde SharedPreferences: $storedUserId');

        if (storedUserId == null || storedUserId.isEmpty) {
          print('❌ No se encontró usuario en SharedPreferences');
          return null;
        }

        // Obtener datos del usuario desde Firestore
        final doc = await _firestore.collection('usuarios').doc(storedUserId).get();
        if (doc.exists) {
          print('✅ Usuario encontrado en Firestore');
          return UserModel.fromJson(doc.data()!);
        }
      } else {
        // Obtener datos del usuario desde Firestore
        final doc = await _firestore.collection('usuarios').doc(userId).get();
        if (doc.exists) {
          print('✅ Usuario encontrado en Firestore');
          return UserModel.fromJson(doc.data()!);
        } else {
          print('⚠️ Usuario no encontrado en Firestore, creando perfil básico');
        }
      }

      // Si no se encuentra el usuario, crear un modelo con datos básicos
      if (userId != null) {
        final user = _auth.currentUser;
        final userModel = UserModel(
          id: userId,
          email: user?.email ?? '',
          nombre: user?.displayName?.split(' ').first ?? '',
          apellidos: user?.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
        print('✅ Creado perfil básico para usuario');
        return userModel;
      }

      print('❌ No se pudo obtener información del usuario');
      return null;
    } catch (e) {
      print('❌ Error al obtener el usuario: $e');
      return null;
    }
  }

  // Método para actualizar el perfil del usuario
  Future<bool> actualizarPerfil(UserModel usuario) async {
    try {
      print('📝 Actualizando perfil del usuario...');
      
      if (usuario.id == null) {
        print('❌ ID de usuario es null');
        return false;
      }

      print('💾 Guardando en Firestore...');
      // Actualizar datos en Firestore
      await _firestore.collection('usuarios').doc(usuario.id).set(
            usuario.toJson(),
            SetOptions(merge: true),
          ).timeout(const Duration(seconds: 30));

      // Actualizar displayName en Firebase Auth si es necesario
      if (usuario.nombre != null || usuario.apellidos != null) {
        final user = _auth.currentUser;
        if (user != null) {
          final displayName = [
            usuario.nombre ?? '',
            usuario.apellidos ?? '',
          ].where((s) => s.isNotEmpty).join(' ');

          if (displayName.isNotEmpty) {
            print('👤 Actualizando displayName en Auth...');
            await user.updateDisplayName(displayName);
          }
        }
      }

      print('✅ Perfil actualizado correctamente');
      return true;
    } catch (e) {
      print('❌ Error al actualizar el perfil: $e');
      return false;
    }
  }

  // Método para seleccionar imagen de la galería
  Future<File?> seleccionarImagenGaleria() async {
    try {
      print('📱 Abriendo galería...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        print('✅ Imagen seleccionada: ${file.path}');
        return file;
      }
      print('⚠️ No se seleccionó ninguna imagen');
      return null;
    } catch (e) {
      print('❌ Error al seleccionar imagen de galería: $e');
      return null;
    }
  }

  // Método para tomar foto con la cámara
  Future<File?> tomarFoto() async {
    try {
      print('📷 Abriendo cámara...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        print('✅ Foto tomada: ${file.path}');
        return file;
      }
      print('⚠️ No se tomó ninguna foto');
      return null;
    } catch (e) {
      print('❌ Error al tomar foto: $e');
      return null;
    }
  }

  // Método para subir imagen a Firebase Storage
  Future<String?> subirImagen(File imagen, String userId) async {
    try {
      print('=== INICIO SUBIDA DE IMAGEN ===');
      print('📁 Ruta de la imagen: ${imagen.path}');
      print('📋 Existe el archivo: ${await imagen.exists()}');
      print('👤 Usuario autenticado: ${_auth.currentUser?.uid}');
      
      // Verificar tamaño del archivo
      final fileSize = await imagen.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      print('📊 Tamaño de la imagen: ${fileSizeMB.toStringAsFixed(2)} MB');
      
      if (fileSizeMB > 5) {
        print('❌ Archivo demasiado grande: ${fileSizeMB.toStringAsFixed(2)} MB');
        return null;
      }

      // Crear referencia al archivo en Storage (usando ruta más simple)
      final fileName = '$userId.jpg';
      final storageRef = _storage.ref().child('imagenes').child(fileName);
      print('📍 Referencia Storage: imagenes/$fileName');

      print('🔄 Iniciando subida...');
      
      // Subir la imagen con timeout
      final UploadTask uploadTask = storageRef.putFile(
        imagen,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitorear progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📈 Progreso de subida: ${progress.toStringAsFixed(1)}%');
      });

      // Esperar a que se complete la subida con timeout
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          print('⏰ Timeout en la subida');
          uploadTask.cancel();
          throw Exception('Timeout en la subida de imagen');
        },
      );

      // Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Imagen subida exitosamente');
      print('🔗 URL de descarga: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      if (e is FirebaseException) {
        print('🔥 Tipo de error: FirebaseException');
        print('🔥 Código de error Firebase: ${e.code}');
        print('🔥 Mensaje de error Firebase: ${e.message}');
      } else {
        print('⚠️ Tipo de error: ${e.runtimeType}');
      }
      return null;
    }
  }

  // Método para actualizar la foto de perfil
  Future<bool> actualizarFotoPerfil(File imagen, String userId) async {
    try {
      print('=== INICIO ACTUALIZACIÓN FOTO PERFIL ===');
      print('👤 Usuario ID: $userId');
      
      // Subir la imagen a Firebase Storage
      final imageUrl = await subirImagen(imagen, userId);

      if (imageUrl == null) {
        print('❌ Error: No se pudo obtener URL de la imagen');
        return false;
      }

      print('💾 Actualizando URL en Firestore...');
      // Actualizar la URL de la imagen en el perfil del usuario
      await _firestore.collection('usuarios').doc(userId).update({
        'profileImageUrl': imageUrl,
      }).timeout(const Duration(seconds: 30));

      // Actualizar photoURL en Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        print('👤 Actualizando photoURL en Auth...');
        await user.updatePhotoURL(imageUrl);
      }

      print('✅ Foto de perfil actualizada correctamente');
      return true;
    } catch (e) {
      print('❌ Error al actualizar foto de perfil: $e');
      if (e is FirebaseException) {
        print('🔥 Código de error Firebase: ${e.code}');
        print('🔥 Mensaje de error Firebase: ${e.message}');
      }
      return false;
    }
  }

  // Método para eliminar la foto de perfil
  Future<bool> eliminarFotoPerfil(String userId) async {
    try {
      print('🗑️ Eliminando foto de perfil...');
      
      // Intentar eliminar la imagen de Storage
      try {
        final storageRef = _storage.ref().child('imagenes').child('$userId.jpg');
        await storageRef.delete();
        print('✅ Imagen eliminada de Storage');
      } catch (e) {
        print('⚠️ Error al eliminar imagen de Storage: $e');
        // Continuar aunque falle la eliminación de Storage
      }

      // Actualizar el perfil para eliminar la URL de la imagen
      await _firestore.collection('usuarios').doc(userId).update({
        'profileImageUrl': FieldValue.delete(),
      }).timeout(const Duration(seconds: 30));

      // Actualizar photoURL en Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(null);
      }

      print('✅ Foto de perfil eliminada correctamente');
      return true;
    } catch (e) {
      print('❌ Error al eliminar foto de perfil: $e');
      return false;
    }
  }
}
