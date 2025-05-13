import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/src/preferences/pref_usuarios.dart';
import 'package:flutter_application/src/vista/detalle_equipo_view.dart';
import 'package:flutter_application/src/vista/detalle_partido_view.dart';
import 'package:flutter_application/src/vista/detalle_pista_view.dart';
import 'package:flutter_application/src/vista/equipos_view.dart';
import 'package:flutter_application/src/vista/log_in_screen.dart';
import 'package:flutter_application/src/vista/partidos_screen.dart';
import 'package:flutter_application/src/vista/perfil_view.dart';
import 'package:flutter_application/src/vista/pista_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciasUsuario.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storedUserId = PreferenciasUsuario.userId;
  final isAuthenticated = storedUserId.isNotEmpty;
  final userId = storedUserId.isNotEmpty ? storedUserId : 'user_1';

  runApp(MyApp(
    isAuthenticated: isAuthenticated,
    userId: userId,
  ));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  final String userId;

  const MyApp({
    Key? key,
    required this.isAuthenticated,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KickUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5A9A7A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A9A7A),
        ),
        scaffoldBackgroundColor: const Color(0xFFE5EFE6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A9A7A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
      initialRoute: isAuthenticated ? '/partidos' : '/login',
      onGenerateRoute: (settings) {
        // Extraer argumentos si existen
        final args = settings.arguments;
        final userIdToUse = args is String ? args : userId;
        
        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (context) => LogInPage(),
          );
        } else if (settings.name == '/partidos') {
          return MaterialPageRoute(
            builder: (context) => PartidosView(userId: userIdToUse),
          );
        } else if (settings.name == '/equipos') {
          return MaterialPageRoute(
            builder: (context) => EquiposView(userId: userIdToUse),
          );
        } else if (settings.name == '/pistas') {
          return MaterialPageRoute(
            builder: (context) => PistasView(userId: userIdToUse),
          );
        } else if (settings.name == '/perfil') {
          return MaterialPageRoute(
            builder: (context) => const PerfilView(),
          );
        } else if (settings.name!.startsWith('/detalle-partido/')) {
          final partidoId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => DetallePartidoView(
              partidoId: partidoId,
              userId: userIdToUse,
            ),
          );
        } else if (settings.name!.startsWith('/detalle-equipo/')) {
          final equipoId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => DetalleEquipoView(
              equipoId: equipoId,
              userId: userIdToUse,
            ),
          );
        } else if (settings.name!.startsWith('/detalle-pista/')) {
          final pistaId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => DetallePistaView(
              pistaId: pistaId,
              userId: userIdToUse,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) =>
              isAuthenticated ? PartidosView(userId: userIdToUse) : LogInPage(),
        );
      },
    );
  }
}
