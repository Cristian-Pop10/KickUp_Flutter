import '../servicio/auth_service.dart';

class SignupModel {
  final String email;
  final String password;

  SignupModel({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory SignupModel.fromJson(Map<String, dynamic> json) {
    return SignupModel(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}

