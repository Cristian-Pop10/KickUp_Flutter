import 'package:flutter/material.dart';

class LogInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Parte superior con el título y el logo
          Expanded(
            flex: 1,
            child: _HeaderSection(),
          ),

          // Parte inferior con los campos de texto
          Expanded(
            flex: 1,
            child: _InputSection(),
          ),
        ],
      ),
    );
  }
}

// Widget para la sección del encabezado (título y logo)
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
       children: [
          
        Text(
          'LOG  IN',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF396B3B),
            shadows: [
              Shadow( 
                offset: Offset(2, 2),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        Image.asset(
          'assets/logo.png',
          width: 120,
          height: 120,
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

// Widget para la sección de entrada (campos de texto)
class _InputSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _InputField(label: 'USUARIO', isPassword: false),
          SizedBox(height: 20),
          _InputField(label: 'CONTRASEÑA', isPassword: true),
        ],
      ),
    );
  }
}

// Widget reutilizable para los campos de texto
class _InputField extends StatelessWidget {
  final String label;
  final bool isPassword;

  const _InputField({required this.label, required this.isPassword});

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
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF388E3C),
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
