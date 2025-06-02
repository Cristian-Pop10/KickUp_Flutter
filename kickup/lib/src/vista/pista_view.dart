import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'detalle_pista_view.dart';
import 'package:permission_handler/permission_handler.dart';

class PistasView extends StatefulWidget {
  const PistasView({Key? key}) : super(key: key);

  @override
  _PistasViewState createState() => _PistasViewState();
}

class _PistasViewState extends State<PistasView> {
  // Controlador para manejar la lógica de pistas
  final PistaController _pistaController = PistaController();
  
  // Variables de estado principales
  List<PistaModel> _pistas = [];
  bool _isLoading = true;
  bool _mostrarMapa = false;        // Toggle entre vista lista/mapa
  Set<Marker> _markers = {};        // Marcadores para Google Maps
  GoogleMapController? _mapController;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _requestLocationPermission();   // Solicitar permisos de ubicación
    _cargarPistas();
  }

  @override
  void dispose() {
    // Limpiar controlador del mapa para evitar memory leaks
    _mapController?.dispose();
    super.dispose();
  }

  /// Solicita permisos de ubicación al usuario
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  /// Carga todas las pistas y crea marcadores para el mapa
  Future<void> _cargarPistas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pistas = await _pistaController.obtenerPistas();
      
      // Crear marcadores para cada pista
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
            pista.disponible ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();
      
      // Verificar que el widget sigue montado antes de actualizar estado
      if (mounted) {
        setState(() {
          _pistas = pistas;
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

  /// Navega al detalle de la pista y recarga al volver
  Future<void> _navegarADetallePista(String pistaId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePistaView(
          pistaId: pistaId,
          userId: userId!,
        ),
      ),
    );
    _cargarPistas(); // Recargar pistas al volver
  }

  /// Maneja la navegación del BottomNavBar
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildAppBar(),
      ),
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Índice fijo para pistas
        onTap: _onNavItemTapped,
      ),
    );
  }

  /// Construye el AppBar personalizado con botones de acción
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título de la pantalla
            Text(
              'Pistas',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            // Botones de acción
            Row(
              children: [
                // Botón toggle lista/mapa
                _buildActionButton(
                  icon: _mostrarMapa ? Icons.list : Icons.map,
                  onPressed: () {
                    setState(() {
                      _mostrarMapa = !_mostrarMapa;
                    });
                  },
                  tooltip: _mostrarMapa ? 'Ver lista' : 'Ver mapa',
                ),
                const SizedBox(width: 12),
                // Botón refrescar
                _buildActionButton(
                  icon: Icons.refresh,
                  onPressed: _cargarPistas,
                  tooltip: 'Refrescar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye botones de acción con soporte para modo oscuro
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    // Detectar si estamos en modo oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        // Color adaptativo según el tema
        color: isDarkMode 
            ? Colors.white.withAlpha(25)  // Blanco semi-transparente para modo oscuro
            : Colors.grey[200],           // Gris claro para modo claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
          size: 24,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  /// Construye el cuerpo principal con diferentes estados
  Widget _buildBody() {
    // Estado de carga
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado vacío
    if (_pistas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay pistas disponibles',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarPistas,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Mostrar mapa o lista según el estado
    return _mostrarMapa
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildMapa(),
          )
        : _buildLista();
  }

  /// Construye la vista de lista con pull-to-refresh
  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarPistas,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _pistas.length,
        itemBuilder: (context, index) {
          final pista = _pistas[index];
          return _buildPistaCard(pista);
        },
      ),
    );
  }

  /// Construye el mapa de Google Maps con marcadores
  Widget _buildMapa() {
    // Ubicación por defecto (Madrid)
    const LatLng defaultLocation = LatLng(40.416775, -3.703790);
    
    // Usar la primera pista como ubicación inicial si está disponible
    final LatLng initialLocation = _pistas.isNotEmpty 
        ? LatLng(_pistas.first.latitud, _pistas.first.longitud)
        : defaultLocation;
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 12,
      ),
      markers: _markers,                    // Marcadores de las pistas
      myLocationEnabled: true,              // Mostrar ubicación del usuario
      myLocationButtonEnabled: true,        // Botón para centrar en ubicación
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      compassEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        
        // Centrar el mapa en la primera pista si hay pistas disponibles
        if (_pistas.isNotEmpty) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_pistas.first.latitud, _pistas.first.longitud),
              12,
            ),
          );
        }
      },
    );
  }

  /// Construye una tarjeta individual de pista
  Widget _buildPistaCard(PistaModel pista) {
    return Card(
      color: AppColors.fieldBackground(context),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () => _navegarADetallePista(pista.id),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPistaImage(pista),      // Imagen de la pista
              const SizedBox(width: 16),
              Expanded(
                child: _buildPistaInfo(pista), // Información de la pista
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la imagen de la pista con fallback
  Widget _buildPistaImage(PistaModel pista) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(8),
        // Mostrar imagen si existe
        image: pista.imagenUrl != null && pista.imagenUrl!.isNotEmpty
            ? DecorationImage(
                image: pista.imagenUrl!.startsWith('assets/')
                    ? AssetImage(pista.imagenUrl!) as ImageProvider
                    : NetworkImage(pista.imagenUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      // Mostrar icono por defecto si no hay imagen
      child: pista.imagenUrl == null || pista.imagenUrl!.isEmpty
          ? const Icon(
              Icons.sports_soccer,
              size: 40,
              color: Colors.grey,
            )
          : null,
    );
  }

  /// Construye la información detallada de la pista
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
            // Badge de disponibilidad
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
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            ),
          ),
        const SizedBox(height: 4),
        
        // Dirección con icono
        Row(
          children: [
            const Icon(Icons.location_on, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                pista.direccion,
                style: const TextStyle(fontSize: 14),
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
              const Icon(Icons.euro, size: 16),
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