import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickup/src/modelo/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/** Controlador que gestiona todas las operaciones relacionadas con el perfil de usuario.
   Maneja la obtención y actualización de datos de perfil, gestión de imágenes de perfil,
   y sincronización entre Firebase Auth, Firestore y Storage. */
class PerfilController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /** Obtiene los datos del usuario actual desde Firebase Auth y Firestore.
     Si no encuentra el usuario en Auth, intenta recuperarlo desde SharedPreferences.
     Crea un perfil básico si no existe en Firestore. */
  Future<UserModel?> obtenerUsuarioActual() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString('user_id');

        if (storedUserId == null || storedUserId.isEmpty) {
          return null;
        }

        final doc =
            await _firestore.collection('usuarios').doc(storedUserId).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      } else {
        final doc = await _firestore.collection('usuarios').doc(userId).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        } else {
          print('Usuario no encontrado en Firestore, creando perfil básico');
        }
      }

      if (userId != null) {
        final user = _auth.currentUser;
        final userModel = UserModel(
          id: userId,
          email: user?.email ?? '',
          nombre: user?.displayName?.split(' ').first ?? '',
          apellidos: user?.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
        return userModel;
      }

      print('No se pudo obtener información del usuario');
      return null;
    } catch (e) {
      print('Error al obtener el usuario: $e');
      return null;
    }
  }

  /** Actualiza la información del perfil del usuario en Firestore y Firebase Auth.
     Sincroniza el displayName en Auth con el nombre completo del usuario. */
  Future<bool> actualizarPerfil(UserModel usuario) async {
    try {
      if (usuario.id == null) {
        print('ID de usuario es null');
        return false;
      }

      await _firestore
          .collection('usuarios')
          .doc(usuario.id)
          .set(
            usuario.toJson(),
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 30));

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

  /** Permite al usuario seleccionar una imagen desde la galería.
     Optimiza la imagen reduciendo su tamaño y calidad para mejorar el rendimiento. */
  Future<File?> seleccionarImagenGaleria() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        return file;
      }
      print(' No se seleccionó ninguna imagen');
      return null;
    } catch (e) {
      print('Error al seleccionar imagen de galería: $e');
      return null;
    }
  }

  /** Permite al usuario tomar una foto con la cámara del dispositivo.
     Optimiza la imagen reduciendo su tamaño y calidad para mejorar el rendimiento. */
  Future<File?> tomarFoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        return file;
      }
      print(' No se tomó ninguna foto');
      return null;
    } catch (e) {
      print(' Error al tomar foto: $e');
      return null;
    }
  }

  /** Sube una imagen a Firebase Storage y retorna la URL de descarga.
     Incluye validación de tamaño, monitoreo de progreso y manejo de timeouts.
     Limita el tamaño máximo de archivo a 5MB. */
  Future<String?> subirImagen(File imagen, String userId) async {
    try {
      final fileSize = await imagen.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > 5) {
        print(' Archivo demasiado grande: ${fileSizeMB.toStringAsFixed(2)} MB');
        return null;
      }

      final fileName = '$userId.jpg';
      final storageRef = _storage.ref().child('imagenes').child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        imagen,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print(' Progreso de subida: ${progress.toStringAsFixed(1)}%');
      });

      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Timeout en la subida de imagen');
        },
      );

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print(' Error al subir imagen: $e');
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

  /** Actualiza la foto de perfil del usuario.
     Sube la imagen a Storage, actualiza la URL en Firestore y sincroniza con Firebase Auth. */
  Future<bool> actualizarFotoPerfil(File imagen, String userId) async {
    try {
      final imageUrl = await subirImagen(imagen, userId);

      if (imageUrl == null) {
        print(' Error: No se pudo obtener URL de la imagen');
        return false;
      }

      await _firestore.collection('usuarios').doc(userId).update({
        'profileImageUrl': imageUrl,
      }).timeout(const Duration(seconds: 30));

      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(imageUrl);
      }

      return true;
    } catch (e) {
      print(' Error al actualizar foto de perfil: $e');
      if (e is FirebaseException) {
        print('🔥 Código de error Firebase: ${e.code}');
        print('🔥 Mensaje de error Firebase: ${e.message}');
      }
      return false;
    }
  }

  /** Elimina la foto de perfil del usuario.
     Remueve la imagen de Storage, elimina la URL de Firestore y actualiza Firebase Auth. */
  Future<bool> eliminarFotoPerfil(String userId) async {
    try {
      try {
        final storageRef =
            _storage.ref().child('imagenes').child('$userId.jpg');
        await storageRef.delete();
      } catch (e) {
        print(' Error al eliminar imagen de Storage: $e');
      }

      await _firestore.collection('usuarios').doc(userId).update({
        'profileImageUrl': FieldValue.delete(),
      }).timeout(const Duration(seconds: 30));

      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(null);
      }

      return true;
    } catch (e) {
      print(' Error al eliminar foto de perfil: $e');
      return false;
    }
  }
}
