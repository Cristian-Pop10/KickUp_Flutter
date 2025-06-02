import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kickup/src/servicio/notifications_service.dart';
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

import 'package:firebase_messaging/firebase_messaging.dart';

/// Manejador para mensajes de Firebase recibidos cuando la app está en segundo plano
/// Esta función debe ser de nivel superior (no dentro de una clase) y sin estado
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializar Firebase para poder procesar el mensaje
  await Firebase.initializeApp();
  print('Mensaje recibido en background: ${message.messageId}');
}

/// Punto de entrada principal de la aplicación
void main() async {
  // Asegurar que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con las opciones específicas de la plataforma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Inicializar las preferencias de usuario (SharedPreferences)
  await PreferenciasUsuario.init();

  // Registrar el manejador para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Forzar orientación vertical en la app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Verificar si hay un usuario autenticado
  final currentUser = FirebaseAuth.instance.currentUser;
  final isAuthenticated = currentUser != null;
  final userId = currentUser?.uid ?? '';

  // Iniciar la aplicación con el proveedor de tema
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

/// Widget principal de la aplicación KickUp
class KickUpApp extends StatefulWidget {
  final bool isAuthenticated;
  final String userId;

  const KickUpApp({
    Key? key,
    required this.isAuthenticated,
    required this.userId,
  }) : super(key: key);

  @override
  State<KickUpApp> createState() => _KickUpAppState();
}

class _KickUpAppState extends State<KickUpApp> {
  // Servicio para manejar notificaciones
  final NotificacionesService _notificacionesService = NotificacionesService();

  @override
  void initState() {
    super.initState();
    // Inicializar Firebase Messaging cuando se crea el widget
    _initFirebaseMessaging();
  }

  /// Configura Firebase Messaging para notificaciones push
  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos para notificaciones (especialmente importante en iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificación concedidos');

      // Obtener token FCM para identificar este dispositivo
      String? token = await messaging.getToken();
      print('Token FCM: $token');

      // Suscribirse al topic "general" si las notificaciones están activas en preferencias
      bool estadoNotificaciones = await _notificacionesService.getEstado();
      if (estadoNotificaciones) {
        await messaging.subscribeToTopic('general');
      }

      // Configurar listener para mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Mensaje recibido en primer plano: ${message.notification?.title}');
      });
    } else {
      print('Permisos de notificación denegados');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el proveedor de tema para determinar el modo actual
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'KickUp',
      debugShowCheckedModeBanner: false, // Ocultar banner de debug
      theme: _lightTheme(), // Tema claro
      darkTheme: _darkTheme(), // Tema oscuro
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Ruta inicial basada en el estado de autenticación
      initialRoute: widget.isAuthenticated ? '/partidos' : '/login',
      
      // Generador de rutas dinámico para manejar parámetros en URLs
      onGenerateRoute: (settings) {
        // Extraer argumentos y usar ID de usuario si está disponible
        final args = settings.arguments;
        final userIdToUse = args is String ? args : widget.userId;

        // Manejar diferentes rutas
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
            // Rutas dinámicas con parámetros
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
              // Ruta por defecto basada en autenticación
              return MaterialPageRoute(
                builder: (_) =>
                    widget.isAuthenticated ? PartidosView() : LogInPage(),
              );
            }
        }
      },
    );
  }

  /// Define el tema claro de la aplicación
  ThemeData _lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      brightness: Brightness.light,
      // Esquema de colores basado en el color semilla verde
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A9A7A), // Verde principal
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF5A9A7A), // Verde principal
      scaffoldBackgroundColor: const Color(0xFFD7EAD9), // Fondo verde claro
      cardColor: const Color(0xFFD2C9A0), // Color de tarjetas
      
      // Configuración de AppBar transparente
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
      
      // Estilo de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A9A7A), // Verde principal
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Estilo de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8DDBD), // Fondo beige claro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  /// Define el tema oscuro de la aplicación
  ThemeData _darkTheme() {
    final base = ThemeData.dark();

    return base.copyWith(
      brightness: Brightness.dark,
      // Esquema de colores basado en el mismo color semilla pero en modo oscuro
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A9A7A), // Verde principal
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1C1C), // Fondo casi negro
      cardColor: const Color(0xFF2C2C2C), // Color de tarjetas oscuro
      
      // Configuración de AppBar transparente
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
      
      // Estilo de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A9A7A), // Verde principal
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Estilo de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3A3A), // Gris oscuro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}