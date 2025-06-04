class EquipoModel {
  final String id;
  final String creadorId;
  final String nombre;
  final String tipo;
  final String logoUrl;
  final String? descripcion;
  final List<String> jugadoresIds;
  final int nivel;

  EquipoModel({
    required this.id,
    required this.creadorId,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    this.descripcion,
    required this.jugadoresIds,
    this.nivel = 1,
  });

  // Constructor de copia con parámetros opcionales
  EquipoModel copyWith({
    String? id,
    String? creadorId,
    String? nombre,
    String? tipo,
    String? logoUrl,
    String? descripcion,
    List<String>? jugadoresIds,
    int? nivel,
  }) {
    return EquipoModel(
      id: id ?? this.id,
      creadorId: this.creadorId, // El creadorId no se debe cambiar
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      logoUrl: logoUrl ?? this.logoUrl,
      descripcion: descripcion ?? this.descripcion,
      jugadoresIds: jugadoresIds ?? this.jugadoresIds,
      nivel: nivel ?? this.nivel,
    );
  }

  // Método para crear un EquipoModel desde un Map (por ejemplo, desde JSON)
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'],
      creadorId: json['creadorId'] ?? '', 
      nombre: json['nombre'],
      tipo: json['tipo'],
      logoUrl: json['logoUrl'],
      descripcion: json['descripcion'],
      jugadoresIds: List<String>.from(json['jugadoresIds'] ?? []),
      nivel: json['nivel'] ?? 1,
    );
  }

  // Método para convertir un EquipoModel a un Map (por ejemplo, para JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creadorId': creadorId,
      'nombre': nombre,
      'tipo': tipo,
      'logoUrl': logoUrl,
      'descripcion': descripcion,
      'jugadoresIds': jugadoresIds,
      'nivel': nivel,
    };
  }
}
