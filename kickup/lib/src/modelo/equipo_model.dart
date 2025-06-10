/** Modelo que representa un equipo deportivo en la aplicación.
   Contiene toda la información relacionada con un equipo, incluyendo
   sus datos básicos, miembros y nivel. */
class EquipoModel {
  /** Identificador único del equipo */
  final String id;
  
  /** Identificador del usuario que creó el equipo */
  final String creadorId;
  
  /** Nombre del equipo */
  final String nombre;
  
  /** Tipo o categoría del equipo */
  final String tipo;
  
  /** URL de la imagen del logo del equipo */
  final String logoUrl;
  
  /** Descripción opcional del equipo */
  final String? descripcion;
  
  /** Lista de IDs de los jugadores que pertenecen al equipo */
  final List<String> jugadoresIds;
  
  /** Nivel de habilidad del equipo */
  final int nivel;

  /** Constructor principal que inicializa un equipo con sus propiedades.
     Requiere los campos obligatorios y permite valores opcionales. */
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

  /** Crea una copia del equipo con propiedades específicas modificadas.
     Útil para actualizar un equipo sin modificar el original. */
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
      creadorId: this.creadorId,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      logoUrl: logoUrl ?? this.logoUrl,
      descripcion: descripcion ?? this.descripcion,
      jugadoresIds: jugadoresIds ?? this.jugadoresIds,
      nivel: nivel ?? this.nivel,
    );
  }

  /** Crea una instancia de EquipoModel a partir de un mapa de datos.
     Utilizado para deserializar datos de Firestore o JSON. */
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

  /** Convierte la instancia de EquipoModel a un mapa de datos.
     Utilizado para serializar el equipo para almacenamiento en Firestore o JSON. */
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