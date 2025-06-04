import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelo/user_model.dart';
import '../modelo/partido_model.dart';
import '../modelo/equipo_model.dart';
import '../modelo/pista_model.dart';

class FirebaseService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Referencias a colecciones
  CollectionReference get _usersCollection => _firestore.collection('usuarios');
  CollectionReference get _partidosCollection => _firestore.collection('partidos');
  CollectionReference get _equiposCollection => _firestore.collection('equipos');
  CollectionReference get _pistasCollection => _firestore.collection('pistas');

  // Métodos de autenticación
  Future<UserCredential> registrarUsuario(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error en el registro: $e');
      rethrow; // Relanzar la excepción para manejarla en la capa superior
    }
  }

  Future<UserCredential> iniciarSesion(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Métodos para usuarios
  Future<void> crearUsuario(UserModel usuario) async {
    try {
      return await _usersCollection.doc(usuario.id).set(usuario.toJson());
    } catch (e) {
      print('Error al crear usuario: $e');
      rethrow;
    }
  }

  Future<UserModel?> obtenerUsuario(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario: $e');
      rethrow;
    }
  }

  Future<void> actualizarUsuario(UserModel usuario) async {
    try {
      return await _usersCollection.doc(usuario.id).update(usuario.toJson());
    } catch (e) {
      print('Error al actualizar usuario: $e');
      rethrow;
    }
  }

  // Métodos para partidos
  Future<String> crearPartido(PartidoModel partido) async {
    try {
      final docRef = _partidosCollection.doc();
      final partidoConId = partido.copyWith(id: docRef.id);
      await docRef.set(partidoConId.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al crear partido: $e');
      rethrow;
    }
  }

  Future<List<PartidoModel>> obtenerPartidos() async {
    try {
      final querySnapshot = await _partidosCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PartidoModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener partidos: $e');
      rethrow;
    }
  }

  Future<PartidoModel?> obtenerPartidoPorId(String partidoId) async {
    try {
      final doc = await _partidosCollection.doc(partidoId).get();
      if (doc.exists) {
        return PartidoModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener partido: $e');
      rethrow;
    }
  }

  Future<void> actualizarPartido(PartidoModel partido) async {
    try {
      return await _partidosCollection.doc(partido.id).update(partido.toJson());
    } catch (e) {
      print('Error al actualizar partido: $e');
      rethrow;
    }
  }

  // Métodos para equipos
  Future<String> crearEquipo(EquipoModel equipo) async {
    try {
      final docRef = _equiposCollection.doc();
      final equipoConId = equipo.copyWith(id: docRef.id);
      await docRef.set(equipoConId.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al crear equipo: $e');
      rethrow;
    }
  }

  Future<List<EquipoModel>> obtenerEquipos() async {
    try {
      final querySnapshot = await _equiposCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EquipoModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener equipos: $e');
      rethrow;
    }
  }

  // Método para escuchar cambios en equipos en tiempo real
  Stream<List<EquipoModel>> obtenerEquiposStream() {
    try {
      return _equiposCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return EquipoModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (e) {
      print('Error al obtener stream de equipos: $e');
      // No podemos usar rethrow en un Stream, así que devolvemos un stream vacío
      return Stream.value([]);
    }
  }

  Future<EquipoModel?> obtenerEquipoPorId(String equipoId) async {
    try {
      final doc = await _equiposCollection.doc(equipoId).get();
      if (doc.exists) {
        return EquipoModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener equipo: $e');
      rethrow;
    }
  }

  Future<void> actualizarEquipo(EquipoModel equipo) async {
    try {
      return await _equiposCollection.doc(equipo.id).update(equipo.toJson());
    } catch (e) {
      print('Error al actualizar equipo: $e');
      rethrow;
    }
  }

  // Métodos para pistas
  Future<String> crearPista(PistaModel pista) async {
    try {
      final docRef = _pistasCollection.doc();
      final pistaConId = pista.copyWith(id: docRef.id);
      await docRef.set(pistaConId.toJson());
      return docRef.id;
    } catch (e) {
      print('Error al crear pista: $e');
      rethrow;
    }
  }

  Future<List<PistaModel>> obtenerPistas() async {
    try {
      final querySnapshot = await _pistasCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PistaModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener pistas: $e');
      rethrow;
    }
  }

  Future<PistaModel?> obtenerPistaPorId(String pistaId) async {
    try {
      final doc = await _pistasCollection.doc(pistaId).get();
      if (doc.exists) {
        return PistaModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener pista: $e');
      rethrow;
    }
  }

  Future<void> actualizarPista(PistaModel pista) async {
    try {
      return await _pistasCollection.doc(pista.id).update(pista.toJson());
    } catch (e) {
      print('Error al actualizar pista: $e');
      rethrow;
    }
  }

  // Métodos para almacenamiento
  Future<String> subirImagen(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      rethrow;
    }
  }

  Future<void> eliminarImagen(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: $e');
      rethrow;
    }
  }
}