import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'detalle_pista_view.dart';
import 'equipos_view.dart';
import 'partidos_view.dart';
import 'perfil_view.dart';
import 'package:permission_handler/permission_handler.dart';

class PistasView extends StatefulWidget {

  const PistasView({Key? key,}) : super(key: key);

  @override
  _PistasViewState createState() => _PistasViewState();
}

class _PistasViewState extends State<PistasView> {
  final PistaController _pistaController = PistaController();
  List<PistaModel> _pistas = [];
  bool _isLoading = true;
  bool _mostrarMapa = false;
  Set<Marker> _markers = {};
  bool _mapInitialized = false;
  
  // Controlador para el mapa
  GoogleMapController? _mapController;
  
  // Índice actual para el BottomNavBar (2 para la pestaña de pistas)
  final int _currentIndex = 2;

  late final String? userId;
  
  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _requestLocationPermission();
    _cargarPistas();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    await Permission.location.request();
  }
}

  Future<void> _cargarPistas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pistas = await _pistaController.obtenerPistas();
      
      // Crear marcadores para el mapa
      final markers = pistas.map((pista) {
        return Marker(
          markerId: MarkerId(pista.id),
          position: LatLng(pista.latitud, pista.longitud),
          infoWindow: InfoWindow(
            title: pista.nombre,
            snippet: pista.tipo ?? 'Pista deportiva',
            onTap: () => _navegarADetallePista(pista.id),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            pista.disponible ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();
      
      setState(() {
        _pistas = pistas;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar pistas: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pistas: ${e.toString()}')),
        );
      }
    }
  }

  void _navegarADetallePista(String pistaId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePistaView(
          pistaId: pistaId,
          userId: userId!,
        ),
      ),
    );
    
    // Recargar pistas al volver
    _cargarPistas();
  }
  
  // Método para manejar la navegación entre pestañas
  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return; // No hacer nada si ya estamos en esta pestaña
    
    Widget nextScreen;
    
    switch (index) {
      case 0:
        nextScreen = PartidosView();
        break;
      case 1:
        nextScreen = EquiposView();
        break;
      case 2:
        return; // Ya estamos en la pestaña de pistas
      case 3:
        nextScreen = PerfilView();
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5EFE6), // Fondo verde claro
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Altura fija para el AppBar
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFE5EFE6), // Mismo color que el fondo
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título "Pistas"
                const Text(
                  'Pistas',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                
                // Botones de acción
                Row(
                  children: [
                    // Botón para alternar entre lista y mapa
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A9A7A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _mostrarMapa ? Icons.list : Icons.map,
                          color: const Color(0xFF5A9A7A),
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarMapa = !_mostrarMapa;
                          });
                        },
                        tooltip: _mostrarMapa ? 'Ver mapa' : 'Ver lista',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(), // Eliminar restricciones de tamaño
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón para refrescar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A9A7A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF5A9A7A),
                          size: 24,
                        ),
                        onPressed: _cargarPistas,
                        tooltip: 'Refrescar',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(), // Eliminar restricciones de tamaño
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reducir el margen superior
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE6), // Mismo color que el fondo
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pistas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No hay pistas disponibles',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarPistas,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A9A7A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _mostrarMapa
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildMapa(),
                      )
                    : _buildLista(),
      ),
      // Añadir el BottomNavBar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

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

  Widget _buildMapa() {
    // Coordenadas por defecto (Madrid)
    const LatLng defaultLocation = LatLng(40.416775, -3.703790);
    
    // Usar la primera pista como ubicación inicial si está disponible
    LatLng initialLocation = _pistas.isNotEmpty 
        ? LatLng(_pistas.first.latitud, _pistas.first.longitud)
        : defaultLocation;
    
    return Stack(
      children: [
        GoogleMap(
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
            setState(() {
              _mapController = controller;
              _mapInitialized = true;
            });
            
            // Centrar el mapa en la primera pista si hay pistas disponibles
            if (_pistas.isNotEmpty) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_pistas.first.latitud, _pistas.first.longitud),
                  12,
                ),
              );
            }
            
            // Imprimir mensaje de depuración
            print('Mapa creado correctamente');
          },
        ),
        
        // Indicador de carga mientras el mapa se inicializa
        if (!_mapInitialized)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildPistaCard(PistaModel pista) {
    return Card(
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
              // Imagen de la pista
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: pista.imagenUrl != null && pista.imagenUrl!.isNotEmpty
                      ? DecorationImage(
                          image: pista.imagenUrl!.startsWith('assets/')
                              ? AssetImage(pista.imagenUrl!) as ImageProvider
                              : NetworkImage(pista.imagenUrl!),
                          fit: BoxFit.cover,
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
              ),
              const SizedBox(width: 16),
              
              // Información de la pista
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y disponibilidad
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                    
                    // Tipo
                    if (pista.tipo != null && pista.tipo!.isNotEmpty)
                      Text(
                        pista.tipo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    
                    // Dirección
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
                    const SizedBox(height: 4),
                    
                    // Precio
                    if (pista.precio != null)
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
