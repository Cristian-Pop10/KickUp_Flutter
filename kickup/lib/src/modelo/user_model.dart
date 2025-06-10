/** Modelo que representa un usuario completo en la aplicación deportiva.
   Contiene toda la información del perfil del usuario, incluyendo datos
   personales, estadísticas deportivas y configuraciones de cuenta. */
class UserModel {
  /** Identificador único del usuario en la base de datos */
  final String? id;
  
  /** Dirección de correo electrónico del usuario (campo obligatorio) */
  final String email;
  
  /** Contraseña del usuario (opcional, no se almacena en algunos casos por seguridad) */
  final String? password;
  
  /** Nombre del usuario */
  final String? nombre;
  
  /** Apellidos del usuario */
  final String? apellidos;
  
  /** Edad del usuario en años */
  final int? edad;
  
  /** Nivel de habilidad deportiva del usuario */
  final int? nivel;
  
  /** Posición preferida del usuario en el deporte (ej: "Delantero", "Defensa") */
  final String? posicion;
  
  /** Número de teléfono de contacto del usuario */
  final String? telefono;
  
  /** Puntos de reputación del usuario (por defecto 15, se modifica según comportamiento) */
  final int? puntos;
  
  /** URL de la imagen de perfil del usuario */
  final String? profileImageUrl;
  
  /** Indica si el usuario tiene privilegios de administrador */
  final bool esAdmin;
  
  /** Fecha y hora de creación de la cuenta del usuario */
  final DateTime? createdAt;

  /** Constructor principal que inicializa un usuario con sus propiedades.
     Solo el email es obligatorio, el resto de campos son opcionales.
     Los puntos se inicializan en 15 y esAdmin en false por defecto. */
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
    this.puntos = 15, 
    this.profileImageUrl,
    this.esAdmin = false, 
    this.createdAt, 
  });

  /** Crea una copia del usuario con propiedades específicas modificadas.
     Útil para actualizar información del usuario sin modificar el original. */
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

  /** Crea una instancia de UserModel a partir de un mapa de datos.
     Utilizado para deserializar datos de Firestore o JSON.
     Maneja conversiones de tipos y valores nulos de forma segura.
     Los campos numéricos se convierten usando int.parse() para mayor flexibilidad. */
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

  /** Convierte la instancia de UserModel a un mapa de datos.
     Utilizado para serializar el usuario para almacenamiento en Firestore o JSON.
     La fecha se convierte a formato ISO 8601 para compatibilidad. */
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