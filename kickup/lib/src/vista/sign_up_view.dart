import 'package:flutter/material.dart';
import 'package:kickup/src/modelo/user_model.dart';
import '../controlador/auth_controller.dart';
import '../modelo/signup_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'partidos_view.dart';

/** Vista de registro de usuarios.
 * Permite a nuevos usuarios crear una cuenta proporcionando
 * información personal y deportiva. Incluye validación de campos,
 * selección de posición de juego y navegación a la vista principal
 * tras un registro exitoso.
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

  /** Procesa el registro del usuario con los datos del formulario */
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      SignupModel(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Función auxiliar para capitalizar la primera letra
      String _capitalizeFirstLetter(String text) {
        if (text.isEmpty) return text;
        return text[0].toUpperCase() + text.substring(1);
      }

      // Crea el UserModel con los datos del formulario
      final user = UserModel(
        id: null,
        email: _emailController.text,
        password: _passwordController.text,
        edad: int.tryParse(_edadController.text),
        nivel: int.tryParse(_nivelController.text),
        posicion: _posicionController.text,
        telefono: _telefonoController.text,
        nombre: _capitalizeFirstLetter(_nombreController.text),
        apellidos: _capitalizeFirstLetter(_apellidosController.text),
      );

      // Intenta registrar al usuario
      final success = await _authController.registerWithUser(user);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
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
          const SnackBar(content: Text('Error en el registro')),
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
                          
                          // Campo de nombre
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
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Introduce nombre';
                              return null;
                            },
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
                          ),
                          
                          // Campo de apellidos
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
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Introduce tus apellidos';
                              return null;
                            },
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
                          ),
                          const SizedBox(height: 20),
                          
                          // Campo de edad
                          const Text(
                            'Edad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _edadController,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Introduce tu edad';
                              final edad = int.tryParse(value);
                              if (edad == null || edad < 0 || edad > 80)
                                return 'Edad no válida';
                              return null;
                            },
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
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          // Campo de nivel de juego
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
                              if (value == null || value.isEmpty)
                                return 'Introduce tu nivel (1-5)';
                              final nivel = int.tryParse(value);
                              if (nivel == null || nivel < 1 || nivel > 5)
                                return 'Nivel entre 1 y 5';
                              return null;
                            },
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
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          // Selector de posición
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
                            hint: const Text("Selecciona una posición"),
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
                                  style: const TextStyle(fontSize: 16),
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
                              if (value == null || value.isEmpty)
                                return 'Selecciona tu posición';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Campo de teléfono
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
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Introduce tu teléfono';
                              if (value.length < 9) return 'Teléfono no válido';
                              return null;
                            },
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
                          builder: (context) => PartidosView(),
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