import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickup/src/vista/partidos_view.dart';
import 'package:kickup/src/vista/sign_up_view.dart';
import '../preferences/pref_usuarios.dart';

class LogInPage extends StatefulWidget {
  static const String routeName = '/login';
  
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Usar directamente Firebase Auth para iniciar sesión
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        
        // Guardar información del usuario en preferencias
        PreferenciasUsuario.userEmail = email;
        PreferenciasUsuario.userId = userId;
        PreferenciasUsuario.ultimaPagina = '/partidos';
        
        print('✅ Sesión guardada con ID de usuario: $userId');
        
        // Verificar si el usuario existe en Firestore
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = await firestore.collection('usuarios').doc(userId).get();
          
          if (!userDoc.exists) {
            // Si el usuario no existe en Firestore, crearlo con datos básicos
            await firestore.collection('usuarios').doc(userId).set({
              'email': email,
              'id': userId,
            });
            print('✅ Usuario creado en Firestore durante login');
          }
        } catch (firestoreError) {
          print('⚠️ Error al verificar/crear usuario en Firestore: $firestoreError');
          // Continuar con la navegación aunque haya error en Firestore
        }
        
        if (mounted) {
          // Navegar a la pantalla de partidos
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PartidosView(userId: userId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al iniciar sesión')),
          );
        }
      }
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      
      String errorMessage = 'Error al iniciar sesión';
      
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Usuario no encontrado';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email inválido';
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = 'Usuario deshabilitado';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Demasiados intentos fallidos. Inténtalo más tarde';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        child: const _HeaderSection(),
                      ),
                      Expanded(
                        child: _InputSection(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isLoading: _isLoading,
                          onLoginPressed: _handleLogin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LOG  IN',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 99, 181, 102),
              shadows: const [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            'assets/logo.png',
            width: 120,
            height: 120,
          ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLoginPressed;
  final bool isLoading;

  const _InputSection({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.onLoginPressed,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF5A9A7A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InputField(
            label: 'USUARIO',
            isPassword: false,
            controller: emailController,
          ),
          const SizedBox(height: 20),
          _InputField(
            label: 'CONTRASEÑA',
            isPassword: true,
            controller: passwordController,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: isLoading ? null : onLoginPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color.fromARGB(255, 129, 226, 134),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistroView()),
                );
              },
              child: const Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;

  const _InputField({
    Key? key,
    required this.label,
    required this.isPassword,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 183, 210, 184),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
