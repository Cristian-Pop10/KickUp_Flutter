import 'package:flutter/material.dart';
import 'package:kickup/src/modelo/user_model.dart';
import 'package:kickup/src/vista/log_in_view.dart';
import '../controlador/auth_controller.dart';
import '../modelo/signup_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'partidos_view.dart';

/** Vista de registro de usuarios con validaciones.
 * Permite emojis en nombres cuando van acompañados de letras válidas,
 * pero evita nombres compuestos solo de emojis o espacios.
 * Incluye texto negro en formularios para modo oscuro.
 */
class RegistroView extends StatefulWidget {
  const RegistroView({Key? key}) : super(key: key);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  // Clave global para el formulario y controladores para los campos
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _authController = AuthController();
  final _edadController = TextEditingController();
  final _nivelController = TextEditingController();
  final _posicionController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _isLoading = false;

  // Lista de posiciones disponibles para el dropdown
  final List<String> _posiciones = [
    'portero',
    'defensa',
    'centrocampista',
    'delantero',
  ];

  String? _posicionSeleccionada;

  @override
  void dispose() {
    // Liberar recursos de los controladores
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidosController.dispose();
    _edadController.dispose();
    _nivelController.dispose();
    _posicionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  /** Obtiene el color de texto para los formularios según el tema */
  Color _getFormTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.black : Colors.black87;
  }

  /** Obtiene el color de hint text para los formularios según el tema */
  Color _getFormHintColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.black54 : Colors.grey[600]!;
  }

  /** Valida nombres permitiendo emojis cuando van acompañados de letras */
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduce $fieldName';
    }

    final trimmedValue = value.trim();
    
    // Verificar longitud mínima y máxima
    if (trimmedValue.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    
    if (trimmedValue.length > 50) {
      return '$fieldName no puede exceder 50 caracteres';
    }

    // Verificar que no contenga solo espacios
    if (trimmedValue.replaceAll(' ', '').isEmpty) {
      return '$fieldName no puede contener solo espacios';
    }

    // CLAVE: Verificar que contenga al menos algunas letras válidas
    final RegExp letterRegex = RegExp(r'[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]');
    if (!letterRegex.hasMatch(trimmedValue)) {
      return '$fieldName debe contener al menos una letra válida';
    }

    // Contar cuántas letras válidas tiene
    final lettersCount = letterRegex.allMatches(trimmedValue).length;
    if (lettersCount < 2) {
      return '$fieldName debe contener al menos 2 letras válidas';
    }

    // Verificar que no tenga espacios múltiples consecutivos
    if (trimmedValue.contains(RegExp(r'\s{2,}'))) {
      return '$fieldName no puede tener espacios múltiples consecutivos';
    }

    // Verificar que no contenga caracteres peligrosos o de control
    final RegExp dangerousCharsRegex = RegExp(r'[<>{}[\]\\|`~]');
    if (dangerousCharsRegex.hasMatch(trimmedValue)) {
      return '$fieldName contiene caracteres no permitidos';
    }

    // Verificar que empiece con una letra
    if (!RegExp(r'^[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]').hasMatch(trimmedValue)) {
      return '$fieldName debe empezar con una letra';
    }

    return null;
  }

  /** Valida la edad con restricciones */
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduce tu edad';
    }

    final edad = int.tryParse(value.trim());
    
    if (edad == null) {
      return 'La edad debe ser un número válido';
    }

    if (edad < 16) {
      return 'Debes tener al menos 16 años para registrarte';
    }

    if (edad > 80) {
      return 'La edad no puede ser mayor a 80 años';
    }

    return null;
  }

  /** Valida el número de teléfono con formato español */
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduce tu teléfono';
    }

    final trimmedValue = value.trim().replaceAll(' ', '').replaceAll('-', '');
    
    // Verificar que solo contenga números y el símbolo +
    final RegExp phoneRegex = RegExp(r'^(\+34)?[6-9]\d{8}$');
    
    if (!phoneRegex.hasMatch(trimmedValue)) {
      return 'Introduce un teléfono válido (ej: 612345678 o +34612345678)';
    }

    return null;
  }

  /** Procesa el registro del usuario con los datos del formulario */
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      SignupModel(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Función auxiliar para limpiar y capitalizar nombres 
      String _cleanAndCapitalizeName(String text) {
        final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
        
        // Dividir por espacios y capitalizar solo las palabras que empiecen con letra
        return cleaned.split(' ').map((word) {
          if (word.isEmpty) return '';
          
          // Si la palabra empieza con letra, capitalizarla
          if (RegExp(r'^[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]').hasMatch(word)) {
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }
          
          // Si empieza con emoji u otro carácter, devolverla tal como está
          return word;
        }).join(' ');
      }

      // Crea el UserModel con los datos del formulario limpiados
      final user = UserModel(
        id: null,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        edad: int.tryParse(_edadController.text.trim()),
        nivel: int.tryParse(_nivelController.text.trim()),
        posicion: _posicionController.text,
        telefono: _telefonoController.text.trim().replaceAll(' ', '').replaceAll('-', ''),
        nombre: _cleanAndCapitalizeName(_nombreController.text),
        apellidos: _cleanAndCapitalizeName(_apellidosController.text),
      );

      // Intenta registrar al usuario
      final success = await _authController.registerWithUser(user);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro exitoso'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navega a la vista principal si el registro fue exitoso
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PartidosView(showTutorial: true),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error en el registro. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección verde superior con el formulario
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF5A9A7A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'REGISTRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo de email
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            validator: _authController.validateEmail,
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          
                          // Campo de contraseña
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            validator: _authController.validatePassword,
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Nombre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nombreController,
                            validator: (value) => _validateName(value, 'el nombre'),
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              hintStyle: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Apellidos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _apellidosController,
                            validator: (value) => _validateName(value, 'los apellidos'),
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              hintStyle: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Edad (mínimo 16 años)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _edadController,
                            validator: _validateAge,
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              hintStyle: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Nivel (1-5)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nivelController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Introduce tu nivel (1-5)';
                              }
                              final nivel = int.tryParse(value.trim());
                              if (nivel == null || nivel < 1 || nivel > 5) {
                                return 'El nivel debe estar entre 1 y 5';
                              }
                              return null;
                            },
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              hintText: '1 = Principiante, 5 = Experto',
                              hintStyle: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Posición',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _posicionSeleccionada,
                            hint: Text(
                              "Selecciona una posición",
                              style: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            items: _posiciones.map((String posicion) {
                              return DropdownMenuItem<String>(
                                value: posicion,
                                child: Text(
                                  posicion[0].toUpperCase() +
                                      posicion.substring(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _getFormTextColor(context),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _posicionSeleccionada = newValue;
                                _posicionController.text = newValue ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona tu posición';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Teléfono',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _telefonoController,
                            validator: _validatePhone,
                            style: TextStyle(
                              color: _getFormTextColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              hintText: 'Ej: 612345678 o +34612345678',
                              hintStyle: TextStyle(
                                color: _getFormHintColor(context),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sección blanca inferior con botones y logo
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de registro con indicador de carga
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A9A7A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  
                  // Enlace para ir a inicio de sesión
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LogInPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        color: Color(0xFF5A9A7A),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Image.asset(
                    'assets/arbitro.png',
                    width: 150,
                    height: 150,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}