import 'package:kickup/src/modelo/user_model.dart';

/** Modelo que representa un partido deportivo en la aplicación.
   Contiene toda la información relacionada con un partido, incluyendo
   fecha, ubicación, participantes y estado del mismo. */
class PartidoModel {
  /** Identificador único del partido */
  final String id;
  
  /** Fecha y hora programada para el partido */
  final DateTime fecha;
  
  /** Tipo de partido */
  final String tipo;
  
  /** Ubicación donde se realizará el partido */
  final String lugar;
  
  /** Indica si el partido ya tiene todos los jugadores necesarios */
  final bool completo;
  
  /** Número de jugadores que aún faltan para completar el partido */
  final int jugadoresFaltantes;
  
  /** Precio por jugador para participar en el partido */
  final double precio;
  
  /** Duración estimada del partido en minutos */
  final int duracion;
  
  /** Descripción opcional con detalles adicionales del partido */
  final String? descripcion;
  
  /** Lista de jugadores inscritos en el partido */
  final List<UserModel> jugadores;

  /** Constructor principal que inicializa un partido con sus propiedades.
     Requiere los campos obligatorios y permite valores opcionales. */
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

  /** Crea una copia del partido con propiedades específicas modificadas.
     Útil para actualizar un partido sin modificar el original. */
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

  /** Crea una instancia de PartidoModel a partir de un mapa de datos.
     Utilizado para deserializar datos de Firestore o JSON.
     Maneja valores nulos y conversiones de tipos de forma segura. */
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

  /** Convierte la instancia de PartidoModel a un mapa de datos.
     Utilizado para serializar el partido para almacenamiento en Firestore o JSON.
     Convierte la fecha a formato ISO 8601 y serializa la lista de jugadores. */
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