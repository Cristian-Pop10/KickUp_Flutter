/** Modelo que representa los datos de registro de un nuevo usuario.
   Contiene la información mínima necesaria para crear una cuenta:
   email y contraseña. Utilizado en el proceso de autenticación. */
class SignupModel {
  /** Dirección de correo electrónico del usuario para el registro */
  final String email;
  
  /** Contraseña elegida por el usuario para su cuenta */
  final String password;

  /** Constructor que inicializa los datos de registro.
     Requiere tanto email como contraseña para crear una instancia válida. */
  SignupModel({
    required this.email, 
    required this.password
  });

  /** Convierte la instancia de SignupModel a un mapa de datos.
     Utilizado para enviar los datos de registro a servicios de autenticación
     como Firebase Auth o APIs REST. */
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  /** Crea una instancia de SignupModel a partir de un mapa de datos.
     Utilizado para deserializar datos de formularios o respuestas de API.
     Asume que los campos email y password están presentes en el JSON. */
  factory SignupModel.fromJson(Map<String, dynamic> json) {
    return SignupModel(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}