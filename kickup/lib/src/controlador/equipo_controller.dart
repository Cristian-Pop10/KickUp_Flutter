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
     Sube la imagen a Firebase Storage si se proporciona y guarda el equipo en Firestore. 
     MODIFICADO: Ahora guarda el ID del creador en el equipo. */
  Future<bool> crearEquipoConImagen(EquipoModel equipo, File? logoImage, String creadorId) async {
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
      
      // Crear el equipo con el creador incluido
      final equipoConId = equipoConLogo.copyWith(
        id: id,
        jugadoresIds: [creadorId], // Añadir el creador como primer jugador
      );

      // Obtener datos del creador para añadirlo al array de jugadores
      final userDoc = await _firestore.collection('usuarios').doc(creadorId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final creadorData = {
          'id': creadorId,
          'nombre': userData['nombre'] ?? '',
          'apellidos': userData['apellidos'] ?? '',
          'posicion': userData['posicion'] ?? 'Sin posición',
          'puntos': userData['puntos'] ?? 15,
        };

        // Guardar el equipo con información del creador
        await _firestore.collection('equipos').doc(id).set({
          ...equipoConId.toJson(),
          'creadorId': creadorId, // NUEVO: Guardar ID del creador
          'fechaCreacion': FieldValue.serverTimestamp(),
          'jugadores': [creadorData], // Añadir creador al array de jugadores
        });
      } else {
        // Si no se encuentra el usuario, crear sin jugadores
        await _firestore.collection('equipos').doc(id).set({
          ...equipoConId.toJson(),
          'creadorId': creadorId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  /** Crea un nuevo equipo y asigna al usuario creador como capitán.
     MODIFICADO: Ahora guarda el ID del creador. */
  Future<bool> crearEquipo(EquipoModel equipo, String userIdCreador) async {
    try {
      // Obtener datos del creador
      final userDoc = await _firestore.collection('usuarios').doc(userIdCreador).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final creadorData = {
        'id': userIdCreador,
        'nombre': userData['nombre'] ?? '',
        'apellidos': userData['apellidos'] ?? '',
        'posicion': userData['posicion'] ?? 'Sin posición',
        'puntos': userData['puntos'] ?? 15,
      };

      final equipoConCapitan = equipo.copyWith(
        jugadoresIds: [userIdCreador],
      );

      await _firestore
          .collection('equipos')
          .doc(equipoConCapitan.id)
          .set({
            ...equipoConCapitan.toJson(),
            'creadorId': userIdCreador, // NUEVO: Guardar ID del creador
            'fechaCreacion': FieldValue.serverTimestamp(),
            'jugadores': [creadorData], // Añadir creador al array de jugadores
          });
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

  /** NUEVO: Verifica si un usuario es el creador de un equipo específico. */
  Future<bool> esCreadorDelEquipo(String equipoId, String userId) async {
    try {
      final equipoDoc = await _firestore.collection('equipos').doc(equipoId).get();
      if (equipoDoc.exists) {
        final data = equipoDoc.data() as Map<String, dynamic>;
        final creadorId = data['creadorId'] as String?;
        return creadorId == userId;
      }
      return false;
    } catch (e) {
      print('Error al verificar creador del equipo: $e');
      return false;
    }
  }

  /** Permite a un usuario unirse a un equipo.
     Método único con verificación de duplicados y transacción atómica. */
  Future<bool> unirseEquipo(String equipoId, String userId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // Obtener referencias
        final equipoRef = _firestore.collection('equipos').doc(equipoId);
        final userRef = _firestore.collection('usuarios').doc(userId);

        // Leer documentos
        final equipoDoc = await transaction.get(equipoRef);
        final userDoc = await transaction.get(userRef);

        if (!equipoDoc.exists || !userDoc.exists) {
          return false;
        }

        final equipoData = equipoDoc.data()!;
        final userData = userDoc.data()!;

        // Verificar si ya es miembro
        final jugadoresIds = List<String>.from(equipoData['jugadoresIds'] ?? []);
        if (jugadoresIds.contains(userId)) {
          // Ya es miembro, no hacer nada
          return true;
        }

        // Obtener lista actual de jugadores y eliminar duplicados por ID
        final jugadoresRaw = List<Map<String, dynamic>>.from(equipoData['jugadores'] ?? []);
        final jugadoresMap = <String, Map<String, dynamic>>{};
        
        // Crear mapa para eliminar duplicados
        for (var jugador in jugadoresRaw) {
          final id = jugador['id'];
          if (id != null) {
            jugadoresMap[id] = jugador;
          }
        }

        // Verificar nuevamente en el array de jugadores
        if (jugadoresMap.containsKey(userId)) {
          // Ya existe en el array, solo actualizar jugadoresIds si es necesario
          if (!jugadoresIds.contains(userId)) {
            jugadoresIds.add(userId);
            transaction.update(equipoRef, {
              'jugadoresIds': jugadoresIds,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
          return true;
        }

        // Crear nuevo objeto jugador
        final nuevoJugador = {
          'id': userId,
          'nombre': userData['nombre'] ?? '',
          'apellidos': userData['apellidos'] ?? '',
          'posicion': userData['posicion'] ?? 'Sin posición',
          'puntos': userData['puntos'] ?? 15,
        };

        // Añadir a las listas
        jugadoresIds.add(userId);
        jugadoresMap[userId] = nuevoJugador;

        // Actualizar documento
        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadoresMap.values.toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
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
      return await _firestore.runTransaction<bool>((transaction) async {
        final equipoRef = _firestore.collection('equipos').doc(equipoId);
        final doc = await transaction.get(equipoRef);
        
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
        final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (!jugadoresIds.contains(userId)) return true;

        // Remover de ambas listas
        jugadoresIds.remove(userId);
        jugadores.removeWhere((jugador) => jugador['id'] == userId);

        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadores,
          'lastUpdated': FieldValue.serverTimestamp(),
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

  /** MODIFICADO: Elimina un equipo específico. 
     Disponible para administradores Y creadores del equipo. */
  Future<bool> eliminarEquipo(String equipoId, String userId) async {
    try {
      // Verificar si es admin o creador del equipo
      final esAdmin = await esUsuarioAdmin(userId);
      final esCreador = await esCreadorDelEquipo(equipoId, userId);
      
      if (!esAdmin && !esCreador) {
        print('Usuario no tiene permisos para eliminar este equipo');
        return false;
      }

      // Eliminar logo del equipo de Firebase Storage si existe
      try {
        final equipoDoc = await _firestore.collection('equipos').doc(equipoId).get();
        if (equipoDoc.exists) {
          final data = equipoDoc.data() as Map<String, dynamic>;
          final logoUrl = data['logoUrl'] as String?;
          
          if (logoUrl != null && logoUrl.isNotEmpty) {
            // Extraer el path del logo desde la URL
            final uri = Uri.parse(logoUrl);
            final pathSegments = uri.pathSegments;
            if (pathSegments.length >= 2) {
              final logoPath = pathSegments.sublist(1).join('/');
              await _storage.ref(logoPath).delete();
            }
          }
        }
      } catch (e) {
        print('Error al eliminar logo del equipo: $e');
        // Continuar con la eliminación del equipo aunque falle la eliminación del logo
      }

      // Eliminar el documento del equipo
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