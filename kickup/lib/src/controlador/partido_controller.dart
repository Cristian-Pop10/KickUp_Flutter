import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/partido_model.dart';
import '../modelo/user_model.dart';
import 'dart:async';

/** Controlador que gestiona todas las operaciones relacionadas con partidos.
   Maneja la creación, búsqueda, inscripción y abandono de partidos,
   así como la verificación de estado de inscripciones. */
class PartidoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Stream para escuchar cambios en tiempo real de la colección de partidos.
     Los partidos se ordenan por fecha de forma ascendente. */
  Stream<List<PartidoModel>> get partidosStream => _firestore
      .collection('partidos')
      .orderBy('fecha', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .toList());

  /** Obtiene todos los partidos ordenados por fecha. */
  Future<List<PartidoModel>> obtenerPartidos() async {
    try {
      final snapshot = await _firestore
          .collection('partidos')
          .orderBy('fecha', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener partidos: $e');
      return [];
    }
  }

  /** Crea un nuevo partido en la base de datos.
     Genera automáticamente un ID único si no se proporciona. */
  Future<bool> crearPartido(PartidoModel partido) async {
    try {
      final id = partido.id.isEmpty
          ? 'partido_${DateTime.now().millisecondsSinceEpoch}'
          : partido.id;
      final partidoConId = partido.copyWith(id: id);

      await _firestore
          .collection('partidos')
          .doc(id)
          .set(partidoConId.toJson());
      return true;
    } catch (e) {
      print('Error al crear partido: $e');
      return false;
    }
  }

  /** Busca partidos por tipo, lugar o descripción.
     Realiza búsqueda insensible a mayúsculas y minúsculas. */
  Future<List<PartidoModel>> buscarPartidos(String query) async {
    try {
      if (query.isEmpty) {
        return await obtenerPartidos();
      }

      final queryLower = query.toLowerCase();

      final snapshot = await _firestore.collection('partidos').get();
      final partidos = snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .where((partido) =>
              partido.tipo.toLowerCase().contains(queryLower) ||
              partido.lugar.toLowerCase().contains(queryLower) ||
              (partido.descripcion?.toLowerCase().contains(queryLower) ??
                  false))
          .toList();

      return partidos;
    } catch (e) {
      print('Error al buscar partidos: $e');
      return [];
    }
  }

  /** Obtiene un partido específico por su ID. */
  Future<PartidoModel?> obtenerPartidoPorId(String partidoId) async {
    try {
      final doc = await _firestore.collection('partidos').doc(partidoId).get();
      if (doc.exists) {
        return PartidoModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener partido: $e');
      return null;
    }
  }

  /** Inscribe a un usuario en un partido específico.
     Utiliza transacciones para garantizar consistencia en el conteo de jugadores.
     Actualiza automáticamente el estado de 'completo' del partido. */
  Future<bool> inscribirsePartido(String partidoId, UserModel user) async {
    try {
      final partidoRef = _firestore.collection('partidos').doc(partidoId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(partidoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (jugadores.any((j) => j['id'] == user.id)) return true;

        jugadores.add(user.toJson());

        final jugadoresFaltantes = (data['jugadoresFaltantes'] as int) - 1;
        final completo = jugadoresFaltantes <= 0;

        transaction.update(partidoRef, {
          'jugadores': jugadores,
          'jugadoresFaltantes': jugadoresFaltantes,
          'completo': completo,
        });

        return true;
      });
    } catch (e) {
      print('Error al inscribirse al partido: $e');
      return false;
    }
  }

  /** Verifica si un usuario específico está inscrito en un partido. */
  Future<bool> verificarInscripcion(String partidoId, String userId) async {
    try {
      final doc = await _firestore.collection('partidos').doc(partidoId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final jugadores =
          List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
      return jugadores.any((j) => j['id'] == userId);
    } catch (e) {
      print('Error al verificar inscripción: $e');
      return false;
    }
  }

  /** Permite a un usuario abandonar un partido.
     Utiliza transacciones para garantizar consistencia en el conteo de jugadores.
     Actualiza automáticamente el estado de 'completo' del partido. */
  Future<bool> abandonarPartido(String partidoId, String userId) async {
    try {
      final partidoRef = _firestore.collection('partidos').doc(partidoId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(partidoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (!jugadores.any((j) => j['id'] == userId)) return true;

        final nuevosJugadores =
            jugadores.where((j) => j['id'] != userId).toList();

        final jugadoresFaltantes = (data['jugadoresFaltantes'] as int) + 1;

        transaction.update(partidoRef, {
          'jugadores': nuevosJugadores,
          'jugadoresFaltantes': jugadoresFaltantes,
          'completo': false,
        });

        return true;
      });
    } catch (e) {
      print('Error al abandonar el partido: $e');
      return false;
    }
  }

  /** Elimina un partido específico por su ID.
     Utiliza transacciones para garantizar consistencia.
     Solo el creador del partido puede eliminarlo. */
  Future<bool> eliminarPartido(String partidoId) async {
    try {
      final partidoRef = _firestore.collection('partidos').doc(partidoId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(partidoRef);
        if (!doc.exists) return false;

        // Eliminar el documento del partido
        transaction.delete(partidoRef);
        return true;
      });
    } catch (e) {
      print('Error al eliminar partido: $e');
      return false;
    }
  }

  /** Limpia automáticamente los partidos que ya han pasado su fecha.
     Se ejecuta periódicamente para mantener la base de datos limpia.
     Elimina todos los partidos cuya fecha sea anterior a la actual. */
  Future<void> limpiarPartidosExpirados() async {
    try {
      final ahora = DateTime.now();
      
      // Obtener todos los partidos
      final snapshot = await _firestore.collection('partidos').get();
      
      // Crear un batch para eliminar múltiples documentos
      final batch = _firestore.batch();
      int partidosEliminados = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fechaPartido = (data['fecha'] as Timestamp).toDate();
        
        // Si el partido ya pasó (con un margen de 2 horas para finalización)
        if (fechaPartido.isBefore(ahora.subtract(const Duration(hours: 2)))) {
          batch.delete(doc.reference);
          partidosEliminados++;
        }
      }

      // Ejecutar la eliminación en lote si hay partidos para eliminar
      if (partidosEliminados > 0) {
        await batch.commit();
        print('Partidos expirados eliminados: $partidosEliminados');
      }
    } catch (e) {
      print('Error al limpiar partidos expirados: $e');
    }
  }
}


