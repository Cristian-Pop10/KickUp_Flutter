class PistaModel {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String? tipo;
  final String? descripcion;
  final double? precio;
  final bool disponible;
  final String? imagenUrl;

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

  // Método para crear una copia del modelo con algunos campos modificados
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

  // Método para convertir el modelo a un mapa (para Firestore)
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

  // Método para crear un modelo a partir de un mapa (desde Firestore)
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