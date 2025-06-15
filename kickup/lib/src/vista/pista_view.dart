import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/crear_pista_view.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'detalle_pista_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/** Vista principal para la gestión de pistas deportivas.
 * Permite visualizar pistas en formato lista o mapa, buscar por
 * diferentes criterios, y para administradores: crear, seleccionar
 * y eliminar pistas. Incluye integración con Google Maps y sistema
 * de tutorial interactivo.
 */
class PistasView extends StatefulWidget {
  final bool showTutorial;
  const PistasView({Key? key, this.showTutorial = false}) : super(key: key);

  @override
  _PistasViewState createState() => _PistasViewState();
}

class _PistasViewState extends State<PistasView> {
  // Controladores para la lógica de negocio y búsqueda
  final PistaController _pistaController = PistaController();
  final TextEditingController _searchController = TextEditingController();

  // Variables de estado principales
  List<PistaModel> _pistas = [];
  List<PistaModel> _pistasFiltradas = [];
  List<String> _pistasSeleccionadas = [];
  bool _isLoading = true;
  bool _mostrarMapa = false; // Toggle entre vista lista/mapa
  Set<Marker> _markers = {}; // Marcadores para Google Maps
  GoogleMapController? _mapController;
  late final String? userId;
  bool _esAdmin = false; // Indica si el usuario es administrador
  bool _modoSeleccion = false; // Modo selección para eliminar pistas

  // Claves globales para el sistema de tutorial
  final GlobalKey _navBarKey = GlobalKey();
  final GlobalKey _verMapaKey = GlobalKey();
  final GlobalKey _detallePistaKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _requestLocationPermission(); // Solicitar permisos de ubicación
    _verificarPermisos();
    _searchController.addListener(_filtrarPistas);

    // Mostrar tutorial si es necesario
    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  @override
  void dispose() {
    // Limpiar controladores para evitar memory leaks
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /** Verifica si el usuario actual es administrador */
  Future<void> _verificarPermisos() async {
    if (userId != null) {
      final esAdmin = await _pistaController.esUsuarioAdmin(userId!);
      setState(() {
        _esAdmin = esAdmin;
      });
    }
    _cargarPistas();
  }

  /** Solicita permisos de ubicación al usuario para funcionalidades del mapa */
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  /** Carga todas las pistas y crea marcadores para el mapa */
  Future<void> _cargarPistas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pistas = await _pistaController.obtenerPistas();

      // Crear marcadores para cada pista con color según disponibilidad
      final markers = pistas.map((pista) {
        return Marker(
          markerId: MarkerId(pista.id),
          position: LatLng(pista.latitud, pista.longitud),
          infoWindow: InfoWindow(
            title: pista.nombre,
            snippet: pista.tipo ?? 'Pista deportiva',
            onTap: () => _navegarADetallePista(pista.id),
          ),
          // Color del marcador según disponibilidad
          icon: BitmapDescriptor.defaultMarkerWithHue(
            pista.disponible
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();

      // Verificar que el widget sigue montado antes de actualizar estado
      if (mounted) {
        setState(() {
          _pistas = pistas;
          _pistasFiltradas = pistas;
          _markers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pistas: $e')),
        );
      }
    }
  }

  /** Filtra pistas basado en el texto de búsqueda */
  void _filtrarPistas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _pistasFiltradas = _pistas
          .where((pista) =>
              pista.nombre.toLowerCase().contains(query) ||
              pista.direccion.toLowerCase().contains(query) ||
              (pista.tipo?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  /** Navega al detalle de la pista y recarga al volver */
  Future<void> _navegarADetallePista(String pistaId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePistaView(
          pistaId: pistaId,
          userId: userId!,
          esAdmin: _esAdmin,
        ),
      ),
    );
    _cargarPistas(); // Recargar pistas al volver
  }

  /** Navega a crear pista y recarga si se creó exitosamente */
  Future<void> _navegarACrearPista() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrearPistaView(userId: userId!),
      ),
    );

    if (result == true) {
      _cargarPistas();
    }
  }

  /** Activa/desactiva modo selección (solo admin) */
  void _toggleModoSeleccion() {
    if (!_esAdmin) return;

    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _pistasSeleccionadas.clear();
      }
    });
  }

  /** Selecciona/deselecciona una pista (solo admin) */
  void _toggleSeleccionPista(String pistaId) {
    if (!_esAdmin || !_modoSeleccion) return;

    setState(() {
      if (_pistasSeleccionadas.contains(pistaId)) {
        _pistasSeleccionadas.remove(pistaId);
      } else {
        _pistasSeleccionadas.add(pistaId);
      }
    });
  }

  /** Elimina las pistas seleccionadas (solo admin) */
  Future<void> _eliminarPistasSeleccionadas() async {
    if (!_esAdmin || _pistasSeleccionadas.isEmpty) return;

    final confirmar = await _mostrarDialogoConfirmacion(
      '¿Eliminar pistas?',
      '¿Estás seguro de que quieres eliminar ${_pistasSeleccionadas.length} pista(s)?',
    );

    if (confirmar) {
      setState(() {
        _isLoading = true;
      });

      final eliminadas = await _pistaController.eliminarPistasMultiples(
        _pistasSeleccionadas,
        userId!,
      );

      setState(() {
        _pistasSeleccionadas.clear();
        _modoSeleccion = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$eliminadas pista(s) eliminada(s)'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarPistas();
    }
  }

  /** Muestra diálogo de confirmación para acciones destructivas */
  Future<bool> _mostrarDialogoConfirmacion(
      String titulo, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /** Maneja la navegación del BottomNavBar */
  void _onNavItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/partidos');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/equipos');
        break;
      case 2:
        break; // Ya estamos en pistas
    }
  }

  /** Configura y muestra el tutorial interactivo */
  void _showTutorial() {
    targets = [
      TargetFocus(
        identify: "ver_mapa",
        keyTarget: _verMapaKey,
        contents: [
          TargetContent(
            child: const Text(
              "Cambia a la vista de mapa aquí.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "detalle_pista",
        keyTarget: _detallePistaKey,
        contents: [
          TargetContent(
            child: const Text(
              "Pulsa aquí para ver los detalles de la pista.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "Saltar",
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Has completado la guía!')),
        );
        return false;
      },
      onSkip: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Has completado la guía!')),
        );
        return false;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_modoSeleccion,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _modoSeleccion) {
          setState(() {
            _modoSeleccion = false;
            _pistasSeleccionadas.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Container(
          margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(), // Header con título y controles
              // Solo mostrar buscador si NO está en modo mapa o si es admin
              if (!_mostrarMapa || _esAdmin) _buildSearchBar(),
              const SizedBox(height: 16),
              _buildActionButtons(), // Botones de acción (solo admin)
              const SizedBox(height: 16),
              _buildContent(), // Contenido principal (lista o mapa)
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          key: _navBarKey,
          currentIndex: 2,
          onTap: _onNavItemTapped,
          isAdmin: _esAdmin,
        ),
        // FloatingActionButton eliminado para evitar duplicación
      ),
    );
  }

  /** Construye el header con título y controles según el tipo de usuario */
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pistas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_esAdmin)
                Text(
                  _modoSeleccion ? 'Modo Eliminación' : 'Administrador',
                  style: TextStyle(
                    fontSize: 14,
                    color: _modoSeleccion ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Mostrar botón de logout solo para admin
          if (_esAdmin)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          // Mostrar controles de vista para usuarios normales
          if (!_esAdmin)
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

                return Row(
                  children: [
                    // Botones de control de vista
                    _buildActionButton(
                      key: _verMapaKey,
                      icon: _mostrarMapa ? Icons.list : Icons.map,
                      onPressed: () {
                        setState(() {
                          _mostrarMapa = !_mostrarMapa;
                        });
                      },
                      tooltip: _mostrarMapa ? 'Ver lista' : 'Ver mapa',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.refresh,
                      onPressed: _cargarPistas,
                      tooltip: 'Refrescar',
                    ),
                    const SizedBox(width: 12),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /** Construye la barra de búsqueda con estilo personalizado */
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar pistas...',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            prefixIcon:
                Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  /** Construye botones de acción pequeños con estilo adaptativo */
  Widget _buildActionButton({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(25) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  /** Construye los botones de acción principales (solo para admin) */
  Widget _buildActionButtons() {
    if (_esAdmin) {
      // Vista de administrador: botones circulares verde (+) y rojo (-)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Botón añadir (verde)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: _modoSeleccion ? null : _navegarACrearPista,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _modoSeleccion ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ),
            // Botón eliminar (rojo)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: _modoSeleccion
                      ? _eliminarPistasSeleccionadas
                      : _toggleModoSeleccion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _modoSeleccion ? Colors.red[700] : Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _modoSeleccion ? Icons.delete : Icons.remove,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Vista de usuario normal: sin botones
      return const SizedBox.shrink();
    }
  }

  /** Construye el contenido principal (lista o mapa) */
  Widget _buildContent() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pistasFiltradas.isEmpty
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
                        _searchController.text.isEmpty
                            ? 'No hay pistas disponibles'
                            : 'No se encontraron pistas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : _mostrarMapa
                  ? _buildMapa()
                  : _buildLista(),
    );
  }

  /** Construye la vista de lista con pull-to-refresh */
  Widget _buildLista() {
    return RefreshIndicator(
        onRefresh: _cargarPistas,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _pistasFiltradas.length,
          itemBuilder: (context, index) {
            final pista = _pistasFiltradas[index];
            return _buildPistaCard(
              pista,
              key: index == 0
                  ? _detallePistaKey
                  : null, // Solo el primero para tutorial
            );
          },
        ));
  }

  /** Construye el mapa de Google Maps con marcadores */
  Widget _buildMapa() {
    // Ubicación por defecto (Madrid)
    const LatLng defaultLocation = LatLng(40.416775, -3.703790);

    // Usar la primera pista como ubicación inicial si está disponible
    final LatLng initialLocation = _pistasFiltradas.isNotEmpty
        ? LatLng(
            _pistasFiltradas.first.latitud, _pistasFiltradas.first.longitud)
        : defaultLocation;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialLocation,
            zoom: 12,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          compassEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;

            if (_pistasFiltradas.isNotEmpty) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_pistasFiltradas.first.latitud,
                      _pistasFiltradas.first.longitud),
                  12,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /** Construye una tarjeta individual de pista con información completa */
  Widget _buildPistaCard(PistaModel pista, {Key? key}) {
    final isSelected = _pistasSeleccionadas.contains(pista.id);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected
              ? BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
        ),
        elevation: 2,
        child: InkWell(
          onTap: () => _modoSeleccion
              ? _toggleSeleccionPista(pista.id)
              : _navegarADetallePista(pista.id),
          onLongPress: _esAdmin ? () => _toggleModoSeleccion() : null,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPistaImage(pista),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPistaInfo(pista),
                ),
                if (_esAdmin && _modoSeleccion)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSeleccionPista(pista.id),
                    activeColor: Colors.blue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /** Construye la imagen de la pista con fallback */
  Widget _buildPistaImage(PistaModel pista) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        image: pista.imagenUrl != null && pista.imagenUrl!.isNotEmpty
            ? DecorationImage(
                image: pista.imagenUrl!.startsWith('assets/')
                    ? AssetImage(pista.imagenUrl!) as ImageProvider
                    : NetworkImage(pista.imagenUrl!),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Manejar error de carga de imagen
                },
              )
            : null,
      ),
      child: pista.imagenUrl == null || pista.imagenUrl!.isEmpty
          ? const Icon(
              Icons.sports_soccer,
              size: 40,
              color: Colors.grey,
            )
          : null,
    );
  }

  /** Construye la información detallada de la pista */
  Widget _buildPistaInfo(PistaModel pista) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre y estado de disponibilidad
        Row(
          children: [
            Expanded(
              child: Text(
                pista.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pista.disponible ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pista.disponible ? 'Disponible' : 'No disponible',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Tipo de pista (si existe)
        if (pista.tipo != null && pista.tipo!.isNotEmpty)
          Text(
            pista.tipo!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 4),

        // Dirección con icono
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                pista.direccion,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Precio (si existe)
        if (pista.precio != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.euro, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${pista.precio}€',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
