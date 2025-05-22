import 'package:flutter/material.dart';
import 'package:flutter_application/src/modelo/user_model.dart';
import '../controlador/auth_controller.dart';
import '../modelo/signup_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'perfil_view.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({Key? key}) : super(key: key);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
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

  @override
  void dispose() {
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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final signupModel = SignupModel(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Crea el UserModel con los nuevos campos
      final user = UserModel(
        id: null, // Se puede asignar después del registro en Firebase Auth
        email: _emailController.text,
        password: _passwordController.text,
        edad: int.tryParse(_edadController.text),
        nivel: int.tryParse(_nivelController.text),
        posicion: _posicionController.text,
        telefono: _telefonoController.text,
        nombre: _nombreController.text,
        apellidos: _apellidosController.text,
        // Puedes agregar nombre, apellidos, etc. si los pides en el formulario
      );

      final success = await _authController.registerWithUser(user);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
        // Obtén el UID del usuario actual
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PerfilView(userId: currentUser.uid),
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
            // Sección verde superior
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
                              if (edad == null || edad < 0)
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
                          const Text(
                            'Nivel',
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
                                return 'Introduce tu nivel';
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
                          const Text(
                            'Posición',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _posicionController,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Introduce tu posición';
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

            // Sección blanca inferior
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
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
