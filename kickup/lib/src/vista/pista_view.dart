import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'detalle_pista_view.dart';

class PistasView extends StatefulWidget {
  final String userId;

  const PistasView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PistasView> createState() => _PistasViewState();
}

class _PistasViewState extends State<PistasView> {
  final PistaController _pistaController = PistaController();
  final TextEditingController _searchController = TextEditingController();

  List<PistaModel> _pistas = [];
  bool _isLoading = true;
  bool _isSearching = false;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Posición inicial del mapa (centro de España)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(
        37.4219, -2.2585), // Coordenadas de la zona mostrada en la imagen
    zoom: 10.0,
  );

  @override
  void initState() {
    super.initState();
    _cargarPistas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _cargarPistas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pistas = await _pistaController.obtenerPistas();

      if (mounted) {
        setState(() {
          _pistas = pistas;
          _isLoading = false;
          _crearMarcadores();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pistas: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _buscarPistas(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final resultados = await _pistaController.buscarPistas(query);

      if (mounted) {
        setState(() {
          _pistas = resultados;
          _isSearching = false;
          _crearMarcadores();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar pistas: ${e.toString()}')),
        );
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _crearMarcadores() {
    final Set<Marker> markers = {};

    for (final pista in _pistas) {
      final marker = Marker(
        markerId: MarkerId(pista.id),
        position: LatLng(pista.latitud, pista.longitud),
        infoWindow: InfoWindow(
          title: pista.nombre,
          snippet: pista.direccion,
          onTap: () => _navegarADetallePista(pista.id),
        ),
        onTap: () {
          // Mostrar información básica al tocar el marcador
          _mapController?.showMarkerInfoWindow(MarkerId(pista.id));
        },
      );

      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  void _navegarADetallePista(String pistaId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetallePistaView(
          pistaId: pistaId,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5EFE6), // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pistas',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Avatar del usuario
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/perfil');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D7D7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _buscarPistas,
                decoration: const InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Mapa
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                    ),
                  ),
          ),

          // Barra de navegación
          BottomNavBar(
            currentIndex: 2, // Índice de la pantalla actual
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.of(context).pushReplacementNamed('/partidos');
                  break;
                case 1:
                  Navigator.of(context).pushReplacementNamed('/equipos');
                  break;
                case 2:
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
//   );
