class EquipoModel {
  final String id;
  final String nombre;
  final String tipo; // Fútbol Sala, Fútbol 7, Fútbol 11
  final String logoUrl;
  final String? descripcion;
  final List<String> jugadoresIds;
  final String? creadorId;

  EquipoModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    this.descripcion,
    required this.jugadoresIds,
    this.creadorId,
  });

  // Constructor de copia con parámetros opcionales
  EquipoModel copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? logoUrl,
    String? descripcion,
    List<String>? jugadoresIds,
    String? creadorId,
  }) {
    return EquipoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      logoUrl: logoUrl ?? this.logoUrl,
      descripcion: descripcion ?? this.descripcion,
      jugadoresIds: jugadoresIds ?? this.jugadoresIds,
      creadorId: creadorId ?? this.creadorId,
    );
  }

  // Método para crear un EquipoModel desde un Map (por ejemplo, desde JSON)
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      logoUrl: json['logoUrl'],
      descripcion: json['descripcion'],
      jugadoresIds: List<String>.from(json['jugadoresIds'] ?? []),
      creadorId: json['creadorId'],
    );
  }

  // Método para convertir un EquipoModel a un Map (por ejemplo, para JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'logoUrl': logoUrl,
      'descripcion': descripcion,
      'jugadoresIds': jugadoresIds,
      'creadorId': creadorId,
    };
  }
}