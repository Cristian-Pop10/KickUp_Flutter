import 'package:flutter/material.dart';
import 'package:flutter_application/src/preferences/pref_usuarios.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/vista/log_in_screen.dart';
import 'src/vista/partidos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciasUsuario.init(); // Inicializa las preferencias de usuario
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final prefs = PreferenciasUsuario();

  @override
  Widget build(BuildContext context) {
    String email = prefs.userEmail;
    String lastPage = prefs.ultimaPagina;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: (lastPage == '/partidos' && email.isNotEmpty)
          ? PartidosView(userId: email)
          : LogInPage(),
    );
  }
}
