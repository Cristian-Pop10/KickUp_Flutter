import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelo/equipo_model.dart';

/** Controlador que gestiona todas las operaciones relacionadas con equipos.
   Maneja la creación, búsqueda, modificación y eliminación de equipos,
   así como la gestión de miembros y operaciones administrativas. */
class EquipoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static final _equiposStreamController =
      StreamController<List<EquipoModel>>.broadcast();

  /** Stream para escuchar cambios en tiempo real de la lista de equipos. */
  Stream<List<EquipoModel>> get equiposStream =>
      _equiposStreamController.stream;

  /** Constructor que inicia la escucha de cambios en Firebase. */
  EquipoController() {
    _firestore.collection('equipos').snapshots().listen((snapshot) {
      final equipos =
          snapshot.docs.map((doc) => EquipoModel.fromJson(doc.data())).toList();
      _equiposStreamController.add(equipos);
    });
  }

  /** Obtiene todos los equipos de la base de datos. */
  Future<List<EquipoModel>> obtenerEquipos() async {
    try {
      final querySnapshot = await _firestore.collection('equipos').get();
      final equipos = querySnapshot.docs
          .map((doc) => EquipoModel.fromJson(doc.data()))
          .toList();

      return equipos;
    } catch (e) {
      print('Error al obtener equipos: $e');
      return [];
    }
  }

  /** Crea un nuevo equipo con imagen de logo opcional.
     Sube la imagen a Firebase Storage si se proporciona y guarda el equipo en Firestore. */
  Future<bool> crearEquipoConImagen(EquipoModel equipo, File? logoImage) async {
    try {
      String logoUrl = equipo.logoUrl;

      if (logoImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'equipos/${equipo.nombre}_$timestamp.jpg';

        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(logoImage);
        final snapshot = await uploadTask.whenComplete(() => null);
        logoUrl = await snapshot.ref.getDownloadURL();
      }

      final equipoConLogo = equipo.copyWith(logoUrl: logoUrl);

      final id = equipo.id.isEmpty
          ? 'equipo_${DateTime.now().millisecondsSinceEpoch}'
          : equipo.id;
      final equipoConId = equipoConLogo.copyWith(id: id);

      await _firestore.collection('equipos').doc(id).set(equipoConId.toJson());

      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  /** Crea un nuevo equipo y asigna al usuario creador como capitán. */
  Future<bool> crearEquipo(EquipoModel equipo, String userIdCreador) async {
    try {
      final equipoConCapitan = equipo.copyWith(
        jugadoresIds: [userIdCreador],
      );
      await _firestore
          .collection('equipos')
          .doc(equipoConCapitan.id)
          .set(equipoConCapitan.toJson());
      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  /** Busca equipos por nombre, tipo o descripción.
     Realiza búsqueda insensible a mayúsculas y minúsculas. */
  Future<List<EquipoModel>> buscarEquipos(String query) async {
    try {
      if (query.isEmpty) {
        return await obtenerEquipos();
      }

      final queryLower = query.toLowerCase();
      final equipos = await obtenerEquipos();

      return equipos.where((equipo) {
        return equipo.nombre.toLowerCase().contains(queryLower) ||
            equipo.tipo.toLowerCase().contains(queryLower) ||
            (equipo.descripcion?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    } catch (e) {
      print('Error al buscar equipos: $e');
      return [];
    }
  }

  /** Obtiene un equipo específico por su ID. */
  Future<EquipoModel?> obtenerEquipoPorId(String equipoId) async {
    try {
      final doc = await _firestore.collection('equipos').doc(equipoId).get();
      if (doc.exists) {
        return EquipoModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener equipo: $e');
      return null;
    }
  }

  /** Permite a un usuario unirse a un equipo.
     Utiliza transacciones para garantizar consistencia de datos. */
  Future<bool> unirseEquipo(String equipoId, String userId) async {
    try {
      final equipoRef = _firestore.collection('equipos').doc(equipoId);
      final usuarioDoc =
          await _firestore.collection('usuarios').doc(userId).get();
      final userData = usuarioDoc.data();

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(equipoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (jugadoresIds.contains(userId)) return true;

        jugadoresIds.add(userId);
        jugadores.add({
          'id': userId,
          'nombre': userData?['nombre'] ?? '',
          'apellidos': userData?['apellidos'] ?? '',
          'posicion': userData?['posicion'] ?? '',
          'profileImageUrl': userData?['profileImageUrl'] ?? '',
        });

        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadores,
        });

        return true;
      });
    } catch (e) {
      print('Error al unirse al equipo: $e');
      return false;
    }
  }

  /** Permite a un usuario abandonar un equipo.
     Utiliza transacciones para garantizar consistencia de datos. */
  Future<bool> abandonarEquipo(String equipoId, String userId) async {
    try {
      final equipoRef = _firestore.collection('equipos').doc(equipoId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(equipoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (!jugadoresIds.contains(userId)) return true;

        jugadoresIds.remove(userId);
        jugadores.removeWhere((jugador) => jugador['id'] == userId);

        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadores,
        });

        return true;
      });
    } catch (e) {
      print('Error al abandonar el equipo: $e');
      return false;
    }
  }

  /** Actualiza la URL del logo de un equipo. */
  Future<void> actualizarLogoEquipo(String equipoId, String logoUrl) async {
    await FirebaseFirestore.instance
        .collection('equipos')
        .doc(equipoId)
        .update({
      'logoUrl': logoUrl,
    });
  }

  /** Verifica si un usuario tiene permisos de administrador. */
  Future<bool> esUsuarioAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['esAdmin'] == true || userData['rol'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Error al verificar admin: $e');
      return false;
    }
  }

  /** Elimina un equipo específico. Solo disponible para administradores. */
  Future<bool> eliminarEquipo(String equipoId, String userId) async {
    try {
      final esAdmin = await esUsuarioAdmin(userId);
      if (!esAdmin) {
        print('Usuario no tiene permisos de administrador');
        return false;
      }

      await _firestore.collection('equipos').doc(equipoId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar equipo: $e');
      return false;
    }
  }

  /** Elimina múltiples equipos en una sola operación.
     Solo disponible para administradores. Utiliza batch para optimizar la operación. */
  Future<int> eliminarEquiposMultiples(
      List<String> equiposIds, String userId) async {
    try {
      final esAdmin = await esUsuarioAdmin(userId);
      if (!esAdmin) {
        print('Usuario no tiene permisos de administrador');
        return 0;
      }

      int eliminados = 0;
      final batch = _firestore.batch();

      for (final equipoId in equiposIds) {
        final equipoRef = _firestore.collection('equipos').doc(equipoId);
        batch.delete(equipoRef);
        eliminados++;
      }

      await batch.commit();
      return eliminados;
    } catch (e) {
      print('Error al eliminar equipos múltiples: $e');
      return 0;
    }
  }

  /** Cierra el stream controller para liberar recursos. */
  void dispose() {
    _equiposStreamController.close();
  }
}
