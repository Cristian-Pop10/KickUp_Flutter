import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/auth_controller.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/vista/crear_partido_view.dart';
import 'package:kickup/src/vista/detalle_partido_view.dart';
import '../componentes/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartidosView extends StatefulWidget {
  const PartidosView({
    Key? key,
  }) : super(key: key);

  @override
  State<PartidosView> createState() => _PartidosViewState();
}

class _PartidosViewState extends State<PartidosView> {
  // Controladores para manejar la lógica 
  final PartidoController _partidoController = PartidoController();
  final AuthController _authController = AuthController(); 
  final TextEditingController _searchController = TextEditingController();
  
  // Variables de estado principales
  List<PartidoModel> _partidos = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    // Obtener el ID del usuario actual desde Firebase Auth
    userId = FirebaseAuth.instance.currentUser?.uid;
    _cargarPartidos();

    // Listener para la búsqueda en tiempo real
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _cargarPartidos(); // Recargar todos los partidos si no hay búsqueda
      } else {
        _buscarPartidos(query); // Buscar partidos específicos
      }
    });
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Carga todos los partidos disponibles desde el controlador
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

  /// Busca partidos específicos basado en la query del usuario
  Future<void> _buscarPartidos(String query) async {
    // Mostrar loading solo si hay partidos para mejorar UX
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

  /// Formatea la fecha del partido en formato legible en español
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day;
    final mes = _obtenerNombreMes(fecha.month);
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia de $mes,$anio - $hora:$minuto';
  }

  /// Convierte el número del mes a su nombre en español
  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  /// Maneja la navegación entre pestañas del BottomNavBar
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navegación usando rutas nombradas para mejor organización
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/partidos');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/equipos');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/pistas');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        // Margen personalizado para crear el efecto de tarjeta
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
                  // StreamBuilder para mostrar la imagen de perfil en tiempo real
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Mostrar loading mientras se carga la imagen
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      
                      // Extraer URL de la imagen del documento de Firestore
                      String? imageUrl;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        imageUrl = data['profileImageUrl'] as String?;
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          _authController.navigateToPerfil(context);
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          // Mostrar imagen de red si existe, sino mostrar icono por defecto
                          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
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
                  // Campo de búsqueda expandible
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
                            color: Theme.of(context).inputDecorationTheme.hintStyle?.color,
                          ),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          filled: true,
                          fillColor: AppColors.background(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón para crear nuevo partido
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navegar a la pantalla de crear partido y esperar resultado
                      final partidoCreado = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => CrearPartidoView(userId: userId!),
                        ),
                      );

                      // Recargar lista si se creó un partido exitosamente
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
                              // Icono y mensaje para estado vacío
                              Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                // Mensaje diferente según si hay búsqueda activa o no
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
                                // Navegar al detalle y recargar si hubo cambios
                                final actualizado = await Navigator.of(context).push<bool>(
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
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}

/// Widget personalizado para mostrar cada tarjeta de partido
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
            // Fecha con icono
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
            // Tipo y lugar del partido
            Text(
              '$tipo $lugar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            // Estado del partido (completo o jugadores faltantes)
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