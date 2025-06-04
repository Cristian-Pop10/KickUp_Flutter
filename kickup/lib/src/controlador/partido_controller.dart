import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/partido_model.dart';
import '../modelo/user_model.dart';
import 'dart:async';

class PartidoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios en la colección de partidos
  Stream<List<PartidoModel>> get partidosStream => _firestore
      .collection('partidos')
      .orderBy('fecha', descending: false) // Ordenar por fecha
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .toList());

  // Obtener todos los partidos
  Future<List<PartidoModel>> obtenerPartidos() async {
    try {
      final snapshot = await _firestore
          .collection('partidos')
          .orderBy('fecha', descending: false) // Ordenar por fecha
          .get();
      
      return snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener partidos: $e');
      return [];
    }
  }

  // Crear un nuevo partido
  Future<bool> crearPartido(PartidoModel partido) async {
    try {
      // Si no tiene ID, generar uno
      final id = partido.id.isEmpty ? 'partido_${DateTime.now().millisecondsSinceEpoch}' : partido.id;
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

  // Buscar partidos por texto
  Future<List<PartidoModel>> buscarPartidos(String query) async {
    try {
      if (query.isEmpty) {
        return await obtenerPartidos();
      }
      
      // Convertir la consulta a minúsculas para búsqueda insensible a mayúsculas
      final queryLower = query.toLowerCase();
      
      // Obtener todos los partidos y filtrar en memoria
      // Nota: Firestore no soporta búsquedas de texto completo nativas
      final snapshot = await _firestore.collection('partidos').get();
      final partidos = snapshot.docs
          .map((doc) => PartidoModel.fromJson(doc.data()))
          .where((partido) =>
              partido.tipo.toLowerCase().contains(queryLower) ||
              partido.lugar.toLowerCase().contains(queryLower) ||
              (partido.descripcion?.toLowerCase().contains(queryLower) ?? false))
          .toList();
      
      return partidos;
    } catch (e) {
      print('Error al buscar partidos: $e');
      return [];
    }
  }

  // Obtener un partido por su ID
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

  // Inscribirse a un partido (agregar userId a la lista de jugadores)
  Future<bool> inscribirsePartido(String partidoId, UserModel user) async {
    try {
      final partidoRef = _firestore.collection('partidos').doc(partidoId);
      
      // Usar transacción para garantizar consistencia
      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(partidoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
        
        // Verificar si ya está inscrito
        if (jugadores.any((j) => j['id'] == user.id)) return true;

        // Agregar el jugador
        jugadores.add(user.toJson());
        
        // Actualizar jugadoresFaltantes y completo
        final jugadoresFaltantes = (data['jugadoresFaltantes'] as int) - 1;
        final completo = jugadoresFaltantes <= 0;
        
        // Actualizar el documento
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

  // Verificar si un usuario está inscrito en un partido
  Future<bool> verificarInscripcion(String partidoId, String userId) async {
    try {
      final doc = await _firestore.collection('partidos').doc(partidoId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
      return jugadores.any((j) => j['id'] == userId);
    } catch (e) {
      print('Error al verificar inscripción: $e');
      return false;
    }
  }

  // Abandonar un partido (eliminar userId de la lista de jugadores)
  Future<bool> abandonarPartido(String partidoId, String userId) async {
    try {
      final partidoRef = _firestore.collection('partidos').doc(partidoId);
      
      // Usar transacción para garantizar consistencia
      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(partidoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
        
        // Verificar si está inscrito
        if (!jugadores.any((j) => j['id'] == userId)) return true;
        
        // Eliminar el jugador
        final nuevosJugadores = jugadores.where((j) => j['id'] != userId).toList();
        
        // Actualizar jugadoresFaltantes y completo
        final jugadoresFaltantes = (data['jugadoresFaltantes'] as int) + 1;
        
        // Actualizar el documento
        transaction.update(partidoRef, {
          'jugadores': nuevosJugadores,
          'jugadoresFaltantes': jugadoresFaltantes,
          'completo': false, // Si alguien abandona, ya no está completo
        });
        
        return true;
      });
    } catch (e) {
      print('Error al abandonar el partido: $e');
      return false;
    }
  }
}