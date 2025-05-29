import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:kickup/src/preferences/pref_usuarios.dart';
import 'package:kickup/src/providers/theme_provider.dart';
import 'package:kickup/src/vista/detalle_equipo_view.dart';
import 'package:kickup/src/vista/detalle_partido_view.dart';
import 'package:kickup/src/vista/detalle_pista_view.dart';
import 'package:kickup/src/vista/equipos_view.dart';
import 'package:kickup/src/vista/log_in_view.dart';
import 'package:kickup/src/vista/partidos_view.dart';
import 'package:kickup/src/vista/perfil_view.dart';
import 'package:kickup/src/vista/pista_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenciasUsuario.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final currentUser = FirebaseAuth.instance.currentUser;
  final isAuthenticated = currentUser != null;
  final userId = currentUser?.uid ?? '';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: KickUpApp(
        isAuthenticated: isAuthenticated,
        userId: userId,
      ),
    ),
  );
}

class KickUpApp extends StatelessWidget {
  final bool isAuthenticated;
  final String userId;

  const KickUpApp({
    Key? key,
    required this.isAuthenticated,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'KickUp',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: isAuthenticated ? '/partidos' : '/login',
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        final userIdToUse = args is String ? args : userId;

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => LogInPage());
          case '/partidos':
            return MaterialPageRoute(builder: (_) => PartidosView());
          case '/equipos':
            return MaterialPageRoute(builder: (_) => EquiposView());
          case '/pistas':
            return MaterialPageRoute(builder: (_) => PistasView());
          case '/perfil':
            return MaterialPageRoute(builder: (_) => PerfilView());
          default:
            if (settings.name!.startsWith('/detalle-partido/')) {
              final id = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (_) =>
                    DetallePartidoView(partidoId: id, userId: userIdToUse),
              );
            } else if (settings.name!.startsWith('/detalle-equipo/')) {
              final id = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (_) =>
                    DetalleEquipoView(equipoId: id, userId: userIdToUse),
              );
            } else if (settings.name!.startsWith('/detalle-pista/')) {
              final id = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (_) =>
                    DetallePistaView(pistaId: id, userId: userIdToUse),
              );
            } else {
              return MaterialPageRoute(
                builder: (_) => isAuthenticated ? PartidosView() : LogInPage(),
              );
            }
        }
      },
    );
  }

  ThemeData _lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A9A7A),
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF5A9A7A),
      scaffoldBackgroundColor: const Color(0xFFD7EAD9),
      cardColor: const Color(0xFFD2C9A0),
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
        fillColor: const Color(0xFFE8DDBD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

ThemeData _darkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A9A7A),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1C1C1C),
    cardColor: const Color(0xFF2C2C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
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
      fillColor: const Color(0xFF3A3A3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
