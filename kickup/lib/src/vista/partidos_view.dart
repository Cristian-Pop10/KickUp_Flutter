import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/auth_controller.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/vista/crear_partido_view.dart';
import 'package:kickup/src/vista/detalle_partido_view.dart';
import 'package:kickup/src/vista/pista_view.dart';
import '../componentes/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'equipos_view.dart';
import 'dart:async';

/** Vista principal para la gestión de partidos de fútbol.
 * Permite visualizar, buscar y crear partidos. Incluye sistema de tutorial
 * interactivo para nuevos usuarios y navegación entre las diferentes
 * secciones de la aplicación (partidos, equipos, pistas).
 */
class PartidosView extends StatefulWidget {
  final bool showTutorial;
  const PartidosView({Key? key, this.showTutorial = false}) : super(key: key);

  @override
  State<PartidosView> createState() => _PartidosViewState();
}

class _PartidosViewState extends State<PartidosView> {
  final PartidoController _partidoController = PartidoController();
  final AuthController _authController = AuthController();
  final TextEditingController _searchController = TextEditingController();

  List<PartidoModel> _partidos = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late final String? userId;

  // Timer para limpiar partidos expirados
  Timer? _cleanupTimer;

  // Claves globales para el sistema de tutorial
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _navBarKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _cargarPartidos();

    // Configurar búsqueda en tiempo real
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _cargarPartidos();
      } else {
        _buscarPartidos(query);
      }
    });

    // Configurar timer para limpiar partidos expirados cada 30 minutos
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _limpiarPartidosExpirados();
    });

    // Mostrar tutorial si es necesario
    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  /** Limpia automáticamente los partidos que ya han pasado su fecha */
  Future<void> _limpiarPartidosExpirados() async {
    try {
      await _partidoController.limpiarPartidosExpirados();
      // Recargar la lista después de la limpieza
      if (mounted) {
        _cargarPartidos();
      }
    } catch (e) {
      print('Error al limpiar partidos expirados: $e');
    }
  }

  /** Carga todos los partidos desde el controlador */
  Future<void> _cargarPartidos() async {
    setState(() {
      _isLoading = true;
    });

    final partidos = await _partidoController.obtenerPartidos();

    setState(() {
      _partidos = partidos;
      _isLoading = false;
    });
  }

  /** Busca partidos basado en el texto de consulta */
  Future<void> _buscarPartidos(String query) async {
    if (_partidos.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final resultados = await _partidoController.buscarPartidos(query);

    setState(() {
      _partidos = resultados;
      _isLoading = false;
    });
  }

  /** Formatea la fecha del partido en formato legible */
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day;
    final mes = _obtenerNombreMes(fecha.month);
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia de $mes,$anio - $hora:$minuto';
  }

  /** Obtiene el nombre del mes en español */
  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

  /** Maneja la navegación entre pestañas de la barra inferior */
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (widget.showTutorial) {
      // Navegación durante el tutorial
      switch (index) {
        case 0:
          // Ya estamos en Partidos, no hacer nada
          break;
        case 1:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EquiposView(showTutorial: true),
            ),
          );
          break;
        case 2:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PistasView(showTutorial: true),
            ),
          );
          break;
      }
    } else {
      // Navegación normal usando rutas nombradas
      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.of(context).pushReplacementNamed('/equipos');
          break;
        case 2:
          Navigator.of(context).pushReplacementNamed('/pistas');
          break;
      }
    }
  }

  /** Configura y muestra el tutorial interactivo para nuevos usuarios */
  void _showTutorial() {
    targets = [
      TargetFocus(
        identify: "crear_partido",
        keyTarget: _fabKey,
        contents: [
          TargetContent(
            child: const Text(
              "¡Crea un partido aquí!",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "avatar",
        keyTarget: _avatarKey,
        contents: [
          TargetContent(
            child: const Text(
              "Accede a tu perfil desde aquí.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "nav_bar",
        keyTarget: _navBarKey,
        contents: [
          TargetContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Barra de navegación",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Navega entre Partidos, Equipos y Pistas.",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "Saltar tutorial",
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {
        // Al completar el tutorial, continuar al siguiente paso
        if (_partidos.isNotEmpty && userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetallePartidoView(
                partidoId: _partidos.first.id,
                userId: userId!,
                showTutorial: true,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EquiposView(showTutorial: true),
            ),
          );
        }
        return false;
      },
      onSkip: () {
        // Al saltar, ir directamente al final del tutorial
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorial saltado. ¡Explora la app por tu cuenta!'),
            backgroundColor: Colors.blue,
          ),
        );
        // No navegar a ningún sitio, quedarse en la vista actual
        return true;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground(context),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // HEADER: Título y avatar del usuario
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Listado partidos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Avatar del usuario con datos en tiempo real
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      String? imageUrl;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        imageUrl = data['profileImageUrl'] as String?;
                      }

                      return GestureDetector(
                        key: _avatarKey,
                        onTap: () {
                          _authController.navigateToPerfil(context);
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // BARRA DE BÚSQUEDA Y BOTÓN CREAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 208, 208, 208),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .inputDecorationTheme
                                .hintStyle
                                ?.color,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: Theme.of(context).iconTheme.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15),
                          filled: true,
                          fillColor: AppColors.background(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón crear partido
                  ElevatedButton.icon(
                    key: _fabKey,
                    onPressed: () async {
                      final partidoCreado =
                          await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) =>
                              CrearPartidoView(userId: userId!),
                        ),
                      );

                      if (partidoCreado == true) {
                        _cargarPartidos();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'crear partido',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // LISTA DE PARTIDOS
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _partidos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.trim().isEmpty
                                    ? 'No hay partidos disponibles'
                                    : 'No se encontraron partidos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _partidos.length,
                          itemBuilder: (context, index) {
                            final partido = _partidos[index];
                            return _PartidoCard(
                              fecha: _formatearFecha(partido.fecha),
                              tipo: partido.tipo,
                              lugar: partido.lugar,
                              completo: partido.completo,
                              faltantes: partido.jugadoresFaltantes,
                              onTap: () async {
                                final actualizado =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (context) => DetallePartidoView(
                                      partidoId: partido.id,
                                      userId: userId!,
                                    ),
                                  ),
                                );

                                if (actualizado == true) {
                                  _cargarPartidos();
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        key: _navBarKey,
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        isAdmin: false,
      ),
    );
  }
}

/** Widget personalizado para mostrar información de cada partido.
 * Incluye fecha, tipo, ubicación y estado de disponibilidad
 * con diseño adaptativo según el tema de la aplicación.
 */
class _PartidoCard extends StatelessWidget {
  final String fecha;
  final String tipo;
  final String lugar;
  final bool completo;
  final int faltantes;
  final VoidCallback onTap;

  const _PartidoCard({
    Key? key,
    required this.fecha,
    required this.tipo,
    required this.lugar,
    required this.completo,
    required this.faltantes,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveBeige(context),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$tipo $lugar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              completo ? 'Completo' : 'Faltan $faltantes',
              style: TextStyle(
                color: completo ? Colors.grey : Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}