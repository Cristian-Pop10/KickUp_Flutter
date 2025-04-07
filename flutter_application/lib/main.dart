// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_application/src/vista/log_in_screen.dart';
import 'package:flutter_application/src/vista/sign_up_screen.dart';
import 'firebase_options.dart';  // Este archivo es el que genera la configuración de Firebase
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Asegura que el entorno esté listo para la inicialización de Firebase

  // Inicialización de Firebase con la configuración que genera flutterfire
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Usando la configuración generada
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Aplicación Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: RegistroView(),
      home: LogInPage(),
    );
  }
}
