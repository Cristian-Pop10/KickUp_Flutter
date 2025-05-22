import 'package:flutter_application/src/modelo/user_model.dart';

class PartidoModel {
  final String id;
  final DateTime fecha;
  final String tipo;
  final String lugar;
  final bool completo;
  final int jugadoresFaltantes;
  final double precio;
  final int duracion;
  final String? descripcion;
  final List<UserModel> jugadores;

  PartidoModel({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.lugar,
    required this.completo,
    required this.jugadoresFaltantes,
    required this.precio,
    required this.duracion,
    this.descripcion,
    required this.jugadores,
  });

  // Constructor de copia con parámetros opcionales
  PartidoModel copyWith({
    String? id,
    DateTime? fecha,
    String? tipo,
    String? lugar,
    bool? completo,
    int? jugadoresFaltantes,
    double? precio,
    int? duracion,
    String? descripcion,
    List<UserModel>? jugadores,
  }) {
    return PartidoModel(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      lugar: lugar ?? this.lugar,
      completo: completo ?? this.completo,
      jugadoresFaltantes: jugadoresFaltantes ?? this.jugadoresFaltantes,
      precio: precio ?? this.precio,
      duracion: duracion ?? this.duracion,
      descripcion: descripcion ?? this.descripcion,
      jugadores: jugadores ?? this.jugadores,
    );
  }

  // Método para crear un PartidoModel desde un Map (por ejemplo, desde JSON)
  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: json['id'] ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      tipo: json['tipo'] ?? '',
      lugar: json['lugar'] ?? '',
      completo: json['completo'] ?? false,
      jugadoresFaltantes: json['jugadoresFaltantes'] ?? 0,
      precio: (json['precio'] != null) ? (json['precio'] as num).toDouble() : 0.0,
      duracion: json['duracion'] ?? 0,
      descripcion: json['descripcion'],
      jugadores: (json['jugadores'] as List?)
          ?.map((jugador) => UserModel.fromJson(jugador))
          .toList() ?? [],
    );
  }

  // Método para convertir un PartidoModel a un Map (por ejemplo, para JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'lugar': lugar,
      'completo': completo,
      'jugadoresFaltantes': jugadoresFaltantes,
      'precio': precio,
      'duracion': duracion,
      'descripcion': descripcion,
      'jugadores': jugadores.map((jugador) => jugador.toJson()).toList(),
    };
  }
}
