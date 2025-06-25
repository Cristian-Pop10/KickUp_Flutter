import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickup/src/vista/partidos_view.dart';
import 'package:kickup/src/vista/jugadores_view.dart';
import 'package:kickup/src/vista/sign_up_view.dart';
import '../preferences/pref_usuarios.dart';

/** Página de inicio de sesión de la aplicación KickUp.
 * Proporciona autenticación mediante Firebase Auth con validación
 * de credenciales, manejo de errores específicos y navegación
 * automática según el tipo de usuario (admin/jugador).
 * Incluye texto negro en formularios para modo oscuro.
 */
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

  /** Maneja el proceso de inicio de sesión con Firebase Auth.
   * Verifica si el usuario es admin antes de navegar.
   * Incluye validación de credenciales, creación automática de documento
   * en Firestore si no existe, y navegación a la vista correcta según el tipo de usuario.
   */
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
        PreferenciasUsuario.ultimaPagina = '/partidos';

        // Verificar si el usuario existe en Firestore
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc =
              await firestore.collection('usuarios').doc(userId).get();

          if (!userDoc.exists) {
            // Si el usuario no existe en Firestore, crearlo con datos básicos
            await firestore.collection('usuarios').doc(userId).set({
              'email': email,
              'id': userId,
            });
          }

          // Verificar si es admin antes de navegar
          await _navigateBasedOnUserType(userId);
        } catch (firestoreError) {
          // En caso de error, ir a partidos por defecto
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PartidosView(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al iniciar sesión'),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en el inicio de sesión: $e');

      String errorMessage = 'Error al iniciar sesión';

      // Mapeo de errores específicos de Firebase Auth
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
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
          ),
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

  /** Navega a la pantalla correcta según el tipo de usuario.
   * Verifica en Firestore si el usuario es admin y navega en consecuencia.
   */
  Future<void> _navigateBasedOnUserType(String userId) async {
    try {
      // Consultar Firestore para verificar si es admin
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PartidosView(),
            ),
          );
        }
        return;
      }

      final userData = doc.data() as Map<String, dynamic>;
      final isAdmin =
          userData['isAdmin'] == true || userData['esAdmin'] == true;

      if (mounted) {
        if (isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const JugadoresView(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PartidosView(),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error verificando tipo de usuario en login: $e');
      if (mounted) {
        // En caso de error, ir a partidos por defecto
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PartidosView(),
          ),
        );
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

/** Sección superior de la pantalla de login.
 * Contiene el título de la aplicación y el logo corporativo
 * con efectos de sombra para mejorar la presentación visual.
 */
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

/** Sección de entrada de datos con formulario de login.
 * Incluye campos de email y contraseña, botón de inicio de sesión
 * con estado de carga, y enlace para registro de nuevos usuarios.
 */
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

  /** Obtiene el color de texto para los formularios según el tema */
  Color _getFormTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.black : Colors.black87;
  }

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
            textColor: _getFormTextColor(context),
          ),
          const SizedBox(height: 20),
          _InputField(
            label: 'CONTRASEÑA',
            isPassword: true,
            controller: passwordController,
            textColor: _getFormTextColor(context),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: isLoading ? null : onLoginPressed,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color.fromARGB(255, 129, 226, 134),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
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
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/** Campo de entrada personalizado con etiqueta y estilo consistente.
 * Soporta modo de contraseña para ocultar texto y aplica
 * el esquema de colores de la aplicación con texto negro en modo oscuro.
 */
class _InputField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;
  final Color textColor;

  const _InputField({
    Key? key,
    required this.label,
    required this.isPassword,
    required this.controller,
    required this.textColor,
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
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 183, 210, 184),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}