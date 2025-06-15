/** Modelo que representa una sanción aplicada a un jugador.
 * Almacena información sobre la asistencia y las penalizaciones
 * o bonificaciones aplicadas en un partido específico.
 */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SancionModel {
  /** ID único de la sanción */
  final String id;
  
  /** ID del partido donde se aplicó la sanción */
  final String partidoId;
  
  /** ID del jugador sancionado */
  final String jugadorId;
  
  /** Estado de asistencia del jugador */
  final EstadoAsistencia estadoAsistencia;
  
  /** Puntos aplicados (positivos para bonificaciones, negativos para sanciones) */
  final int puntosAplicados;
  
  /** ID del usuario que aplicó la sanción (creador del partido) */
  final String aplicadoPor;

  /** Nombre completo del usuario que aplicó la sanción */
  final String nombreAplicadoPor;

  /** Nombre completo del jugador que recibió la sanción */
  final String nombreJugadorSancionado;
  
  /** Fecha y hora cuando se aplicó la sanción */
  final DateTime fechaAplicacion;
  
  /** Comentarios adicionales sobre la sanción (opcional) */
  final String? comentarios;

  SancionModel({
    required this.id,
    required this.partidoId,
    required this.jugadorId,
    required this.estadoAsistencia,
    required this.puntosAplicados,
    required this.aplicadoPor,
    required this.nombreAplicadoPor,
    required this.nombreJugadorSancionado,
    required this.fechaAplicacion,
    this.comentarios,
  });

  /** Crea una copia de la sanción con propiedades modificadas */
  SancionModel copyWith({
    String? id,
    String? partidoId,
    String? jugadorId,
    EstadoAsistencia? estadoAsistencia,
    int? puntosAplicados,
    String? aplicadoPor,
    String? nombreAplicadoPor,
    String? nombreJugadorSancionado,
    DateTime? fechaAplicacion,
    String? comentarios,
  }) {
    return SancionModel(
      id: id ?? this.id,
      partidoId: partidoId ?? this.partidoId,
      jugadorId: jugadorId ?? this.jugadorId,
      estadoAsistencia: estadoAsistencia ?? this.estadoAsistencia,
      puntosAplicados: puntosAplicados ?? this.puntosAplicados,
      aplicadoPor: aplicadoPor ?? this.aplicadoPor,
      nombreAplicadoPor: nombreAplicadoPor ?? this.nombreAplicadoPor,
      nombreJugadorSancionado: nombreJugadorSancionado ?? this.nombreJugadorSancionado,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      comentarios: comentarios ?? this.comentarios,
    );
  }

  /** Crea una instancia desde un mapa de datos */
  factory SancionModel.fromJson(Map<String, dynamic> json) {
    return SancionModel(
      id: json['id'] ?? '',
      partidoId: json['partidoId'] ?? '',
      jugadorId: json['jugadorId'] ?? '',
      estadoAsistencia: _parseEstadoAsistencia(json['estadoAsistencia']),
      puntosAplicados: json['puntosAplicados'] ?? 0,
      aplicadoPor: json['aplicadoPor'] ?? '',
      nombreAplicadoPor: json['nombreAplicadoPor'] ?? '',
      nombreJugadorSancionado: json['nombreJugadorSancionado'] ?? '',
      fechaAplicacion: _parseFecha(json['fechaAplicacion']),
      comentarios: json['comentarios'],
    );
  }

  /** Parsea el estado de asistencia desde string */
  static EstadoAsistencia _parseEstadoAsistencia(dynamic value) {
    if (value == null) return EstadoAsistencia.sinMarcar;
    
    final String stringValue = value.toString();
    
    // Intentar primero con el nombre del enum
    for (EstadoAsistencia estado in EstadoAsistencia.values) {
      if (estado.name == stringValue) {
        return estado;
      }
    }
    
    // Fallback con toString() para compatibilidad
    for (EstadoAsistencia estado in EstadoAsistencia.values) {
      if (estado.toString() == stringValue) {
        return estado;
      }
    }
    
    print(' Estado de asistencia no reconocido: $stringValue');
    return EstadoAsistencia.sinMarcar;
  }

  /** Parsea la fecha desde diferentes formatos */
  static DateTime _parseFecha(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print(' Error al parsear fecha: $value');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /** Crea una instancia desde un documento de Firestore */
  factory SancionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Asegurar que el ID del documento se incluya
    return SancionModel.fromJson(data);
  }

  /** Convierte la instancia a un mapa de datos */
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partidoId': partidoId,
      'jugadorId': jugadorId,
      'estadoAsistencia': estadoAsistencia.name, 
      'puntosAplicados': puntosAplicados,
      'aplicadoPor': aplicadoPor,
      'nombreAplicadoPor': nombreAplicadoPor,
      'nombreJugadorSancionado': nombreJugadorSancionado,
      'fechaAplicacion': fechaAplicacion.toIso8601String(),
      'comentarios': comentarios,
    };
  }
}

/** Enumeración para los diferentes estados de asistencia */
enum EstadoAsistencia {
  sinMarcar,
  aTiempo,
  tarde,
  noAsistio,
}

/** Extensión para obtener información adicional sobre los estados */
extension EstadoAsistenciaExtension on EstadoAsistencia {
  /** Obtiene los puntos asociados al estado */
  int get puntos {
    switch (this) {
      case EstadoAsistencia.aTiempo:
        return 0;
      case EstadoAsistencia.tarde:
        return -1;
      case EstadoAsistencia.noAsistio:
        return -3;
      case EstadoAsistencia.sinMarcar:
        return 0;
    }
  }

  /** Obtiene el texto descriptivo del estado */
  String get descripcion {
    switch (this) {
      case EstadoAsistencia.aTiempo:
        return 'A tiempo';
      case EstadoAsistencia.tarde:
        return 'Llegó tarde (-1 pt)';
      case EstadoAsistencia.noAsistio:
        return 'No asistió (-3 pts)';
      case EstadoAsistencia.sinMarcar:
        return 'Sin marcar';
    }
  }

  /** Obtiene el color asociado al estado */
  Color get color {
    switch (this) {
      case EstadoAsistencia.aTiempo:
        return Colors.green;
      case EstadoAsistencia.tarde:
        return Colors.orange;
      case EstadoAsistencia.noAsistio:
        return Colors.red;
      case EstadoAsistencia.sinMarcar:
        return Colors.grey;
    }
  }

  /** Obtiene el icono asociado al estado */
  IconData get icono {
    switch (this) {
      case EstadoAsistencia.aTiempo:
        return Icons.check_circle;
      case EstadoAsistencia.tarde:
        return Icons.access_time;
      case EstadoAsistencia.noAsistio:
        return Icons.cancel;
      case EstadoAsistencia.sinMarcar:
        return Icons.help_outline;
    }
  }
}
