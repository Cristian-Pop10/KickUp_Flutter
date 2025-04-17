class UserModel {
  final String? id;
  final String? username;
  final String? email;
  final String? password;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    this.id,
    this.username,
    this.email,
    this.password,
    this.profileImageUrl,
    this.createdAt,
    this.lastLogin,
  });

  // Constructor para crear un modelo para login
  factory UserModel.forLogin({
    required String username,
    required String password,
  }) {
    return UserModel(
      username: username,
      password: password,
    );
  }

  // Constructor para crear un modelo para registro
  factory UserModel.forRegistration({
    required String email,
    required String password,
    String? username,
  }) {
    return UserModel(
      email: email,
      password: password,
      username: username,
      createdAt: DateTime.now(),
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password, // Nota: en una app real, nunca envíes la contraseña en texto plano
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Método para crear desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  // Método para crear una copia con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}