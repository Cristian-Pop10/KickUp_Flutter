class UserModel {
  final String? id;
  final String email; // No nulo
  final String? password;
  final String? nombre;
  final String? apellidos;
  final int? edad;
  final int? nivel;
  final String? posicion;
  final String? telefono;
  final int? puntos;
  final String? profileImageUrl;
  final bool esAdmin; 
  // Podemos agregar createdAt si lo necesitas, pero como DateTime?
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.email,
    this.password,
    this.nombre,
    this.apellidos,
    this.edad,
    this.nivel,
    this.posicion,
    this.telefono,
    this.puntos,
    this.profileImageUrl,
    this.esAdmin = false, 
    this.createdAt, // Opcional
  });

  // Constructor de copia con parámetros opcionales
  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? nombre,
    String? apellidos,
    int? edad,
    int? nivel,
    String? posicion,
    String? telefono,
    int? puntos,
    String? profileImageUrl,
    bool? esAdmin,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      edad: edad ?? this.edad,
      nivel: nivel ?? this.nivel,
      posicion: posicion ?? this.posicion,
      telefono: telefono ?? this.telefono,
      puntos: puntos ?? this.puntos,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      esAdmin: esAdmin ?? this.esAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Método para crear un UserModel desde un Map (por ejemplo, desde JSON)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      password: json['password'],
      nombre: json['nombre'],
      apellidos: json['apellidos'],
      edad: json['edad'] != null ? int.parse(json['edad'].toString()) : null,
      nivel: json['nivel'] != null ? int.parse(json['nivel'].toString()) : null,
      posicion: json['posicion'],
      telefono: json['telefono'],
      puntos: json['puntos'] != null ? int.parse(json['puntos'].toString()) : null,
      profileImageUrl: json['profileImageUrl'] as String?,
      esAdmin: json['esAdmin'] ?? false, // Por defecto es false
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  // Método para convertir un UserModel a un Map (por ejemplo, para JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nombre': nombre,
      'apellidos': apellidos,
      'edad': edad,
      'nivel': nivel,
      'posicion': posicion,
      'telefono': telefono,
      'puntos': puntos,
      'profileImageUrl': profileImageUrl,
      'esAdmin': esAdmin,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}