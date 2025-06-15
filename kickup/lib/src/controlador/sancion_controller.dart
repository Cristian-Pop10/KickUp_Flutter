import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickup/src/modelo/sancion_model.dart';

/** Controlador para gestionar las sanciones de jugadores.
 * Maneja la aplicación, consulta y actualización de sanciones
 * en tiempo real con Firebase Firestore.
 */
class SancionesController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Stream para obtener el historial de sanciones de un jugador en tiempo real.
   * @param jugadorId ID del jugador
   * @return Stream de lista de sanciones del jugador ordenadas por fecha
   */
  Stream<List<SancionModel>> streamHistorialJugador(String jugadorId) {
    try {
      return _firestore
          .collection('sanciones')
          .where('jugadorId', isEqualTo: jugadorId)
          .snapshots()
          .handleError((error) {
        print('Error en stream de sanciones: $error');
        return null;
      }).map((snapshot) {
        List<SancionModel> sanciones = [];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              // Asegurar que el ID esté incluido
              data['id'] = doc.id;

              // Verificar que tenga los campos necesarios
              if (data.containsKey('jugadorId') &&
                  data.containsKey('partidoId') &&
                  data.containsKey('fechaAplicacion')) {
                final sancion = SancionModel.fromJson(data);
                sanciones.add(sancion);
              }
            }
          } catch (e) {
            print('Error al parsear sanción ${doc.id}: $e');
            continue;
          }
        }

        // Ordenar manualmente por fecha (más reciente primero)
        sanciones
            .sort((a, b) => b.fechaAplicacion.compareTo(a.fechaAplicacion));

        // Limitar a 50 resultados
        if (sanciones.length > 50) {
          sanciones = sanciones.take(50).toList();
        }

        return sanciones;
      }).handleError((error) {
        print('Error final en stream: $error');
        return <SancionModel>[];
      });
    } catch (e) {
      print('Error al crear stream de sanciones: $e');
      return Stream.value([]);
    }
  }

  /** Obtiene las sanciones de un partido específico.
   * @param partidoId ID del partido
   * @return Lista de sanciones del partido
   */
  Future<List<SancionModel>> obtenerSancionesPartido(String partidoId) async {
    try {
      final snapshot = await _firestore
          .collection('sanciones')
          .where('partidoId', isEqualTo: partidoId)
          .get();

      return snapshot.docs
          .map((doc) => SancionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener sanciones del partido: $e');
      return [];
    }
  }

  /** Verifica si ya se aplicaron sanciones para un partido.
   * @param partidoId ID del partido
   * @return true si ya existen sanciones para el partido
   */
  Future<bool> sancionesYaAplicadas(String partidoId) async {
    try {
      final snapshot = await _firestore
          .collection('sanciones')
          .where('partidoId', isEqualTo: partidoId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar sanciones aplicadas: $e');
      return false;
    }
  }

  /** Aplica sanciones a los jugadores de un partido.
   * @param partidoId ID del partido
   * @param estadosAsistencia Mapa con el estado de asistencia de cada jugador
   * @param aplicadoPor ID del usuario que aplica las sanciones
   * @return true si las sanciones se aplicaron correctamente
   */
  Future<bool> aplicarSanciones(
    String partidoId,
    Map<String, EstadoAsistencia> estadosAsistencia,
    String aplicadoPor,
  ) async {
    try {
      // Verificar si ya se aplicaron sanciones
      final yaAplicadas = await sancionesYaAplicadas(partidoId);
      if (yaAplicadas) {
        return false;
      }

      // Filtrar solo los jugadores que tienen estado diferente a sinMarcar
      final estadosFiltrados =
          Map<String, EstadoAsistencia>.from(estadosAsistencia)
            ..removeWhere((key, value) => value == EstadoAsistencia.sinMarcar);

      if (estadosFiltrados.isEmpty) {
        return false;
      }

      // Obtener información del usuario que aplica las sanciones
      DocumentSnapshot? usuarioDoc;
      try {
        usuarioDoc =
            await _firestore.collection('usuarios').doc(aplicadoPor).get();
      } catch (e) {
        print(' Error al obtener usuario aplicador: $e');
      }

      final nombreAplicadoPor = usuarioDoc?.exists == true
          ? '${(usuarioDoc!.data() as Map<String, dynamic>?)?['nombre'] ?? ''} ${(usuarioDoc.data() as Map<String, dynamic>?)?['apellidos'] ?? ''}'
              .trim()
          : 'Usuario desconocido';

      // Usar batch simple (sin transacción anidada)
      final batch = _firestore.batch();
      int sancionesCreadas = 0;

      // Obtener todos los datos de jugadores primero
      final jugadoresData = <String, Map<String, dynamic>>{};

      for (final jugadorId in estadosFiltrados.keys) {
        try {
          final jugadorDoc =
              await _firestore.collection('usuarios').doc(jugadorId).get();

          if (jugadorDoc.exists) {
            jugadoresData[jugadorId] =
                jugadorDoc.data() as Map<String, dynamic>;
          } else {
            print(' Jugador $jugadorId no existe, saltando...');
          }
        } catch (e) {
          print(' Error al obtener jugador $jugadorId: $e');
        }
      }

      // Procesar cada jugador
      for (final entry in estadosFiltrados.entries) {
        final jugadorId = entry.key;
        final estadoAsistencia = entry.value;

        if (!jugadoresData.containsKey(jugadorId)) {
          continue;
        }

        final jugadorData = jugadoresData[jugadorId]!;
        final nombreJugador =
            '${jugadorData['nombre'] ?? ''} ${jugadorData['apellidos'] ?? ''}'
                .trim();
        final puntosActuales = jugadorData['puntos'] ?? 15;
        final puntosAplicados = estadoAsistencia.puntos;
        final nuevosPuntos = puntosActuales + puntosAplicados;

        // Crear documento de sanción
        final sancionRef = _firestore.collection('sanciones').doc();

        // Crear el mapa de datos manualmente para evitar problemas de serialización
        final sancionData = {
          'id': sancionRef.id,
          'partidoId': partidoId,
          'jugadorId': jugadorId,
          'estadoAsistencia': estadoAsistencia.name,
          'puntosAplicados': puntosAplicados,
          'aplicadoPor': aplicadoPor,
          'nombreAplicadoPor': nombreAplicadoPor,
          'nombreJugadorSancionado': nombreJugador,
          'fechaAplicacion': DateTime.now().toIso8601String(),
          'comentarios': null,
        };

        // Agregar sanción al batch
        batch.set(sancionRef, sancionData);

        // Actualizar puntos del jugador
        batch.update(_firestore.collection('usuarios').doc(jugadorId),
            {'puntos': nuevosPuntos});

        sancionesCreadas++;
      }

      if (sancionesCreadas == 0) {
        return false;
      }

      // Ejecutar todas las operaciones
      await batch.commit();

      return true;
    } catch (e, stackTrace) {
      print(' Error detallado al aplicar sanciones: $e');
      print(' Stack trace: $stackTrace');
      return false;
    }
  }

  /** Calcula estadísticas a partir de la lista de sanciones.
   * @param sanciones Lista de sanciones del jugador
   * @return Mapa con estadísticas de asistencia
   */
  Map<String, int> calcularEstadisticas(List<SancionModel> sanciones) {
    final estadisticas = <String, int>{
      'totalPartidos': sanciones.length,
      'aTiempo': 0,
      'tarde': 0,
      'noAsistio': 0,
      'totalPuntos': 0,
    };

    for (var sancion in sanciones) {
      // Contar por tipo de asistencia
      switch (sancion.estadoAsistencia) {
        case EstadoAsistencia.aTiempo:
          estadisticas['aTiempo'] = estadisticas['aTiempo']! + 1;
          break;
        case EstadoAsistencia.tarde:
          estadisticas['tarde'] = estadisticas['tarde']! + 1;
          break;
        case EstadoAsistencia.noAsistio:
          estadisticas['noAsistio'] = estadisticas['noAsistio']! + 1;
          break;
        case EstadoAsistencia.sinMarcar:
          break;
      }

      // Sumar puntos totales
      estadisticas['totalPuntos'] =
          estadisticas['totalPuntos']! + sancion.puntosAplicados;
    }

    return estadisticas;
  }

  /** Elimina una sanción específica (solo para administradores).
   * @param sancionId ID de la sanción a eliminar
   * @return true si se eliminó correctamente
   */
  Future<bool> eliminarSancion(String sancionId) async {
    try {
      await _firestore.collection('sanciones').doc(sancionId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar sanción: $e');
      return false;
    }
  }

  /** Obtiene el total de puntos acumulados por un jugador.
   * @param jugadorId ID del jugador
   * @return Total de puntos de sanciones/bonificaciones
   */
  Future<int> obtenerTotalPuntosSanciones(String jugadorId) async {
    try {
      final snapshot = await _firestore
          .collection('sanciones')
          .where('jugadorId', isEqualTo: jugadorId)
          .get();

      int totalPuntos = 0;
      for (var doc in snapshot.docs) {
        final sancion = SancionModel.fromFirestore(doc);
        totalPuntos += sancion.puntosAplicados;
      }

      return totalPuntos;
    } catch (e) {
      print('Error al calcular total de puntos: $e');
      return 0;
    }
  }
}
