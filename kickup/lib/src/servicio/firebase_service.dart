import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelo/user_model.dart';
import '../modelo/partido_model.dart';
import '../modelo/equipo_model.dart';
import '../modelo/pista_model.dart';

/** Servicio centralizado para interactuar con Firebase.
   Proporciona métodos para autenticación, gestión de usuarios,
   partidos, equipos, pistas y almacenamiento de archivos.
   Encapsula toda la lógica de comunicación con Firebase. */
class FirebaseService {
  /** Instancia de Firebase Authentication para gestión de usuarios */
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /** Instancia de Firestore para almacenamiento de datos */
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /** Instancia de Firebase Storage para almacenamiento de archivos */
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /** Referencia a la colección de usuarios en Firestore */
  CollectionReference get _usersCollection => _firestore.collection('usuarios');
  
  /** Referencia a la colección de partidos en Firestore */
  CollectionReference get _partidosCollection => _firestore.collection('partidos');
  
  /** Referencia a la colección de equipos en Firestore */
  CollectionReference get _equiposCollection => _firestore.collection('equipos');
  
  /** Referencia a la colección de pistas en Firestore */
  CollectionReference get _pistasCollection => _firestore.collection('pistas');

  // MÉTODOS DE AUTENTICACIÓN

  /** Registra un nuevo usuario con email y contraseña.
     
     [email] Dirección de correo electrónico del usuario.
     [password] Contraseña del usuario.
     
     Retorna un UserCredential si el registro es exitoso.
     Lanza una excepción en caso de error. */
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

  /** Inicia sesión con email y contraseña.
     
     [email] Dirección de correo electrónico del usuario.
     [password] Contraseña del usuario.
     
     Retorna un UserCredential si el inicio de sesión es exitoso.
     Lanza una excepción en caso de error. */
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

  /** Cierra la sesión del usuario actual.
     
     Lanza una excepción en caso de error. */
  Future<void> cerrarSesion() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  /******************  MÉTODOS PARA USUARIOS *********************/

  /** Crea un nuevo usuario en Firestore.
     
     [usuario] Modelo del usuario a crear.
     
     Lanza una excepción en caso de error. */
  Future<void> crearUsuario(UserModel usuario) async {
    try {
      // Comprobar si ya existe un usuario con el mismo nombre
      final query = await _usersCollection
          .where('nombre', isEqualTo: usuario.nombre)
          .get();

      if (query.docs.isNotEmpty) {
        throw Exception('Ya existe un usuario con ese nombre');
      }

      // Si no existe, crea el usuario normalmente
      return await _usersCollection.doc(usuario.id).set(usuario.toJson());
    } catch (e) {
      print('Error al crear usuario: $e');
      rethrow;
    }
  }

  /** Obtiene un usuario por su ID.
     
     [userId] ID del usuario a obtener.
     
     Retorna un UserModel si el usuario existe, null en caso contrario.
     Lanza una excepción en caso de error. */
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

  /** Actualiza los datos de un usuario existente.
     
     [usuario] Modelo del usuario con los datos actualizados.
     
     Lanza una excepción en caso de error. */
  Future<void> actualizarUsuario(UserModel usuario) async {
    try {
      return await _usersCollection.doc(usuario.id).update(usuario.toJson());
    } catch (e) {
      print('Error al actualizar usuario: $e');
      rethrow;
    }
  }

  /*********************  MÉTODOS PARA PARTIDOS ****************************/

  /** Crea un nuevo partido en Firestore.
     
     [partido] Modelo del partido a crear.
     
     Retorna el ID del partido creado.
     Lanza una excepción en caso de error. */
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

  /** Obtiene todos los partidos disponibles.
     
     Retorna una lista de PartidoModel.
     Lanza una excepción en caso de error. */
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

  /** Obtiene un partido específico por su ID.
     
     [partidoId] ID del partido a obtener.
     
     Retorna un PartidoModel si el partido existe, null en caso contrario.
     Lanza una excepción en caso de error. */
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

  /** Actualiza los datos de un partido existente.
     
     [partido] Modelo del partido con los datos actualizados.
     
     Lanza una excepción en caso de error. */
  Future<void> actualizarPartido(PartidoModel partido) async {
    try {
      return await _partidosCollection.doc(partido.id).update(partido.toJson());
    } catch (e) {
      print('Error al actualizar partido: $e');
      rethrow;
    }
  }

  /*******************  MÉTODOS PARA EQUIPOS ***********************/

  /** Crea un nuevo equipo en Firestore.
     
     [equipo] Modelo del equipo a crear.
     
     Retorna el ID del equipo creado.
     Lanza una excepción en caso de error. */
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

  /** Obtiene todos los equipos disponibles.
     
     Retorna una lista de EquipoModel.
     Lanza una excepción en caso de error. */
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

  /** Proporciona un stream para escuchar cambios en equipos en tiempo real.
     
     Retorna un Stream de lista de EquipoModel que se actualiza automáticamente
     cuando hay cambios en la colección de equipos en Firestore. */
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

  /** Obtiene un equipo específico por su ID.
     
     [equipoId] ID del equipo a obtener.
     
     Retorna un EquipoModel si el equipo existe, null en caso contrario.
     Lanza una excepción en caso de error. */
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

  /** Actualiza los datos de un equipo existente.
     
     [equipo] Modelo del equipo con los datos actualizados.
     
     Lanza una excepción en caso de error. */
  Future<void> actualizarEquipo(EquipoModel equipo) async {
    try {
      return await _equiposCollection.doc(equipo.id).update(equipo.toJson());
    } catch (e) {
      print('Error al actualizar equipo: $e');
      rethrow;
    }
  }

  /*****************  MÉTODOS PARA PISTAS *********************/

  /** Crea una nueva pista deportiva en Firestore.
     
     [pista] Modelo de la pista a crear.
     
     Retorna el ID de la pista creada.
     Lanza una excepción en caso de error. */
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

  /** Obtiene todas las pistas deportivas disponibles.
     
     Retorna una lista de PistaModel.
     Lanza una excepción en caso de error. */
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

  /** Obtiene una pista específica por su ID.
     
     [pistaId] ID de la pista a obtener.
     
     Retorna un PistaModel si la pista existe, null en caso contrario.
     Lanza una excepción en caso de error. */
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

  /** Actualiza los datos de una pista existente.
     
     [pista] Modelo de la pista con los datos actualizados.
     
     Lanza una excepción en caso de error. */
  Future<void> actualizarPista(PistaModel pista) async {
    try {
      return await _pistasCollection.doc(pista.id).update(pista.toJson());
    } catch (e) {
      print('Error al actualizar pista: $e');
      rethrow;
    }
  }

  /********************  MÉTODOS PARA ALMACENAMIENTO **********************/

  /** Sube una imagen a Firebase Storage.
     
     [path] Ruta donde se almacenará la imagen en Storage.
     [file] Archivo de imagen a subir.
     
     Retorna la URL de descarga de la imagen subida.
     Lanza una excepción en caso de error. */
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

  /** Elimina una imagen de Firebase Storage.
     
     [path] Ruta de la imagen a eliminar en Storage.
     
     Lanza una excepción en caso de error. */
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