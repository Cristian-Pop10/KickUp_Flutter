class PistaModel {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String? tipo; // Fútbol 7, Fútbol 11, Fútbol Sala, etc.
  final String? descripcion;
  final double? precio; // Precio por hora
  final bool? disponible;
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
    this.disponible,
    this.imagenUrl,
  });

  // Constructor de copia con parámetros opcionales
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

  // Método para crear un PistaModel desde un Map (por ejemplo, desde JSON)
  factory PistaModel.fromJson(Map<String, dynamic> json) {
    return PistaModel(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      precio: json['precio'],
      disponible: json['disponible'],
      imagenUrl: json['imagenUrl'],
    );
  }

  // Método para convertir un PistaModel a un Map (por ejemplo, para JSON)
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
}
