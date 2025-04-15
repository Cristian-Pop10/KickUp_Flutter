class PartidoModel {
  final String id;
  final String tipo; // Fútbol Sala, Fútbol 8, Fútbol 11, etc.
  final String lugar;
  final DateTime fecha;
  final int capacidadTotal;
  final int jugadoresActuales;
  final bool completo;
  final String creadorId;

  PartidoModel({
    required this.id,
    required this.tipo,
    required this.lugar,
    required this.fecha,
    required this.capacidadTotal,
    required this.jugadoresActuales,
    required this.completo,
    required this.creadorId,
  });

  // Método para obtener cuántos jugadores faltan
  int get jugadoresFaltantes => capacidadTotal - jugadoresActuales;

  // Método para verificar si el partido está completo
  bool get estaCompleto => jugadoresActuales >= capacidadTotal;

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'lugar': lugar,
      'fecha': fecha.toIso8601String(),
      'capacidadTotal': capacidadTotal,
      'jugadoresActuales': jugadoresActuales,
      'completo': completo,
      'creadorId': creadorId,
    };
  }

  // Método para crear desde JSON
  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      lugar: json['lugar'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      capacidadTotal: json['capacidadTotal'] as int,
      jugadoresActuales: json['jugadoresActuales'] as int,
      completo: json['completo'] as bool,
      creadorId: json['creadorId'] as String,
    );
  }

  // Método para crear una copia con algunos campos modificados
  PartidoModel copyWith({
    String? id,
    String? tipo,
    String? lugar,
    DateTime? fecha,
    int? capacidadTotal,
    int? jugadoresActuales,
    bool? completo,
    String? creadorId,
  }) {
    return PartidoModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      lugar: lugar ?? this.lugar,
      fecha: fecha ?? this.fecha,
      capacidadTotal: capacidadTotal ?? this.capacidadTotal,
      jugadoresActuales: jugadoresActuales ?? this.jugadoresActuales,
      completo: completo ?? this.completo,
      creadorId: creadorId ?? this.creadorId,
    );
  }
}