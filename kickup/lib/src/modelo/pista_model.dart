/** Modelo que representa una pista deportiva en la aplicación.
   Contiene toda la información relacionada con una instalación deportiva,
   incluyendo ubicación geográfica, características y disponibilidad. */
class PistaModel {
  /** Identificador único de la pista */
  final String id;
  
  /** Nombre de la pista deportiva */
  final String nombre;
  
  /** Dirección física de la pista */
  final String direccion;
  
  /** Coordenada de latitud para ubicación en mapa */
  final double latitud;
  
  /** Coordenada de longitud para ubicación en mapa */
  final double longitud;
  
  /** Tipo de pista */
  final String? tipo;
  
  /** Descripción opcional con detalles adicionales de la pista */
  final String? descripcion;
  
  /** Precio por hora de alquiler de la pista */
  final double? precio;
  
  /** Indica si la pista está disponible para reservas */
  final bool disponible;
  
  /** URL de la imagen principal de la pista */
  final String? imagenUrl;

  /** Constructor principal que inicializa una pista con sus propiedades.
     Requiere los campos obligatorios y permite valores opcionales. */
  PistaModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.tipo,
    this.descripcion,
    this.precio,
    required this.disponible,
    this.imagenUrl,
  });

  /** Crea una copia de la pista con propiedades específicas modificadas.
     Útil para actualizar una pista sin modificar la original. */
  PistaModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    String? tipo,
    String? descripcion,
    double? precio,
    bool? disponible,
    String? imagenUrl,
  }) {
    return PistaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      disponible: disponible ?? this.disponible,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  /** Convierte la instancia de PistaModel a un mapa de datos.
     Utilizado para serializar la pista para almacenamiento en Firestore o JSON. */
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'tipo': tipo,
      'descripcion': descripcion,
      'precio': precio,
      'disponible': disponible,
      'imagenUrl': imagenUrl,
    };
  }

  /** Crea una instancia de PistaModel a partir de un mapa de datos.
     Utilizado para deserializar datos de Firestore o JSON.
     Maneja valores nulos y conversiones de tipos de forma segura. */
  factory PistaModel.fromJson(Map<String, dynamic> json) {
    return PistaModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: json['latitud'] ?? 0.0,
      longitud: json['longitud'] ?? 0.0,
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      precio: json['precio'] != null ? json['precio'].toDouble() : null,
      disponible: json['disponible'] ?? true,
      imagenUrl: json['imagenUrl'],
    );
  }
}