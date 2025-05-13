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
  State<DetallePistaView> createState() => _DetallePistaViewState();
}

class _DetallePistaViewState extends State<DetallePistaView> {
  final PistaController _pistaController = PistaController();
  PistaModel? _pista;
  bool _isLoading = true;
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
      
      if (pista != null && mounted) {
        setState(() {
          _pista = pista;
          _isLoading = false;
          
          // Crear marcador para esta pista
          _markers = {
            Marker(
              markerId: MarkerId(pista.id),
              position: LatLng(pista.latitud, pista.longitud),
              infoWindow: InfoWindow(
                title: pista.nombre,
                snippet: pista.direccion,
              ),
            ),
          };
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró la pista')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5EFE6), // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalle de Pista',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetallePista(),
    );
  }

  Widget _buildDetallePista() {
    if (_pista == null) {
      return const Center(child: Text('No se encontró información de la pista'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la pista
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: _pista!.imagenUrl != null
                ? Image.asset(
                    _pista!.imagenUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.sports_soccer,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (_pista!.tipo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _pista!.tipo!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Dirección
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pista!.direccion,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Precio
                if (_pista!.precio != null)
                  Row(
                    children: [
                      const Icon(Icons.euro, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${_pista!.precio!.toStringAsFixed(2)}€ / hora',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                
                // Disponibilidad
                Row(
                  children: [
                    Icon(
                      _pista!.disponible == true ? Icons.check_circle : Icons.cancel,
                      color: _pista!.disponible == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _pista!.disponible == true ? 'Disponible' : 'No disponible',
                      style: TextStyle(
                        fontSize: 16,
                        color: _pista!.disponible == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Descripción
                if (_pista!.descripcion != null) ...[
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pista!.descripcion!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Mapa pequeño
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
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_pista!.latitud, _pista!.longitud),
                        zoom: 15,
                      ),
                      markers: _markers,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón para reservar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _pista!.disponible == true
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funcionalidad de reserva en desarrollo')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9A7A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text(
                      'RESERVAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
