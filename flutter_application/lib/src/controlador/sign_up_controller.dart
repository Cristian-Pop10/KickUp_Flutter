import 'package:flutter/material.dart';
import '../modelo/signup_model.dart';

class AuthController {
  // Simulación de autenticación
  Future<bool> register(UserModel user) async {
    // Aquí iría la lógica para registrar al usuario con un servicio de backend
    // Por ahora, simplemente simulamos un retraso y retornamos true
    await Future.delayed(const Duration(seconds: 2));
    
    // Validación básica
    if (user.email.isEmpty || !user.email.contains('@')) {
      return false;
    }
    
    if (user.password.isEmpty || user.password.length < 6) {
      return false;
    }
    
    return true;
  }
  
  // Validadores para los campos del formulario
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (!value.contains('@')) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }
  
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}