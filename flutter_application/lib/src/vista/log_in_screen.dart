import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controlador/auth_controller.dart';
import '../preferences/pref_usuarios.dart';
import 'partidos_screen.dart';

class LogInPage extends StatelessWidget {
  static const String routeName = '/login';
  LogInPage({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

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
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        child: _HeaderSection(),
                      ),
                      Expanded(
                        child: _InputSection(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          onLoginPressed: () async {
                            String email = _emailController.text.trim();
                            String password = _passwordController.text.trim();

                            bool success =
                                await _authController.login(email, password);

                            if (success) {
                              // Guardar datos en SharedPreferences
                              PreferenciasUsuario prefs = PreferenciasUsuario();
                              prefs.userEmail = email;
                              prefs.ultimaPagina = '/partidos';

                              // Redirigir a la vista de partidos
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PartidosView(userId: email),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error al iniciar sesión')),
                              );
                            }
                          },
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
              color: Color.fromARGB(255, 99, 181, 102),
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
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

  const _InputSection({
    required this.emailController,
    required this.passwordController,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
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
          SizedBox(height: 20),
          _InputField(
            label: 'CONTRASEÑA',
            isPassword: true,
            controller: passwordController,
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Color.fromARGB(255, 129, 226, 134),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
    required this.label,
    required this.isPassword,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color.fromARGB(255, 183, 210, 184),
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
