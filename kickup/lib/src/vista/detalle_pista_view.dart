import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';

class DetallePistaView extends StatefulWidget {
  final String pistaId;
  final String userId;

  const DetallePistaView({
    Key? key,
    required this.pistaId,
    required this.userId,
  }) : super(key: key);

  @override
  _DetallePistaViewState createState() => _DetallePistaViewState();
}

class _DetallePistaViewState extends State<DetallePistaView> {
  final PistaController _pistaController = PistaController();

  PistaModel? _pista;
  bool _isLoading = true;
  bool _mapLoaded = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _cargarPista();
  }

  Future<void> _cargarPista() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pista = await _pistaController.obtenerPistaPorId(widget.pistaId);

      if (pista != null) {
        // Crear marcador para la pista
        final marker = Marker(
          markerId: MarkerId(pista.id),
          position: LatLng(pista.latitud, pista.longitud),
          infoWindow: InfoWindow(
            title: pista.nombre,
            snippet: pista.tipo ?? 'Pista deportiva',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            pista.disponible
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        );

        setState(() {
          _pista = pista;
          _markers = {marker};
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pista no encontrada')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error al cargar pista: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pista: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isLoading ? 'Cargando...' : _pista?.nombre ?? 'Detalle de Pista'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pista == null
              ? const Center(child: Text('Pista no encontrada'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Imagen de la pista
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: _pista!.imagenUrl != null && _pista!.imagenUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: _pista!.imagenUrl!.startsWith('assets/')
                                      ? AssetImage(_pista!.imagenUrl!) as ImageProvider
                                      : NetworkImage(_pista!.imagenUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _pista!.imagenUrl == null || _pista!.imagenUrl!.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.sports_soccer,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),

                      // Información de la pista
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Estado de disponibilidad
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _pista!.disponible
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _pista!.disponible
                                    ? 'Disponible'
                                    : 'No disponible',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nombre de la pista
                            Text(
                              _pista!.nombre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Tipo de pista
                            if (_pista!.tipo != null &&
                                _pista!.tipo!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.sports_soccer, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _pista!.tipo!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),

                            // Dirección
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pista!.direccion,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Precio
                            Row(
                              children: [
                                const Icon(Icons.euro, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _pista!.precio != null
                                      ? '${_pista!.precio}€'
                                      : 'Gratis',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            // Descripción
                            if (_pista!.descripcion != null &&
                                _pista!.descripcion!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_pista!.descripcion!),
                            ],

                            // Mapa
                            const SizedBox(height: 24),
                            const Text(
                              'Ubicación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                            _pista!.latitud, _pista!.longitud),
                                        zoom: 15,
                                      ),
                                      markers: _markers,
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: false,
                                      mapType: MapType.normal,
                                      zoomControlsEnabled: false,
                                      compassEnabled: false,
                                      onMapCreated: (controller) {
                                        setState(() {
                                          _mapLoaded = true;
                                        });
                                      },
                                    ),
                                    if (!_mapLoaded)
                                      Container(
                                        color: Colors.white70,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Botón para reservar
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _pista!.disponible
                                    ? () {
                                        // Aquí iría la lógica para reservar la pista
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Funcionalidad de reserva no implementada'),
                                          ),
                                        );
                                      }
                                    : null,
                                child: const Text('Reservar Pista'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
