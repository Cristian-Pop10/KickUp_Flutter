import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickup/src/componentes/app_styles.dart';
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
  // Controlador para manejar la lógica de pistas
  final PistaController _pistaController = PistaController();

  // Variables de estado principales
  PistaModel? _pista;
  bool _isLoading = true;
  bool _mapLoaded = false;
  bool _procesandoReserva = false;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _cargarPista();
  }

  @override
  void dispose() {
    // Limpiar controlador del mapa para evitar memory leaks
    _mapController?.dispose();
    super.dispose();
  }

  /// Carga la información de la pista y configura el marcador del mapa
  Future<void> _cargarPista() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pista = await _pistaController.obtenerPistaPorId(widget.pistaId);

      if (pista != null) {
        // Crear marcador para la pista con color según disponibilidad
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

        if (mounted) {
          setState(() {
            _pista = pista;
            _markers = {marker};
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pista no encontrada')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pista: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Maneja la funcionalidad de reserva de pista
  Future<void> _reservarPista() async {
    if (_procesandoReserva || !_pista!.disponible) return;

    setState(() {
      _procesandoReserva = true;
    });

    try {
      // Simular proceso de reserva (implementar lógica real aquí)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Próximamente podrás reservar esta pista'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reservar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesandoReserva = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pista == null
              ? _buildErrorState()
              : _buildPistaContent(),
    );
  }

  /// Construye el AppBar personalizado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isLoading ? 'Cargando...' : _pista?.nombre ?? 'Detalle de Pista',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Construye el estado de error cuando no se encuentra la pista
  Widget _buildErrorState() {
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
            'Pista no encontrada',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPista,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido principal de la pista
  Widget _buildPistaContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(), // Imagen de la pista
          _buildInfoSection(), // Información detallada
          _buildMapSection(), // Mapa de ubicación
          _buildReserveButton(), // Botón de reserva
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construye la sección de imagen de la pista
  Widget _buildImageSection() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25), // Sombra sutil
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Imagen de la pista
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: _pista!.imagenUrl != null && _pista!.imagenUrl!.isNotEmpty
                  ? DecorationImage(
                      image: _pista!.imagenUrl!.startsWith('assets/')
                          ? AssetImage(_pista!.imagenUrl!) as ImageProvider
                          : NetworkImage(_pista!.imagenUrl!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Manejar error de carga de imagen
                      },
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
          // Overlay con gradiente para mejor legibilidad
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(76), // Gradiente sutil
                ],
              ),
            ),
          ),
          // Badge de disponibilidad
          Positioned(
            top: 16,
            right: 16,
            child: _buildAvailabilityBadge(),
          ),
        ],
      ),
    );
  }

  /// Construye el badge de disponibilidad
  Widget _buildAvailabilityBadge() {
    final isAvailable = _pista!.disponible;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Disponible' : 'No disponible',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de información de la pista
  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
          const SizedBox(height: 16),

          // Información detallada
          if (_pista!.tipo != null && _pista!.tipo!.isNotEmpty)
            _buildInfoRow(Icons.sports_soccer, 'Tipo', _pista!.tipo!),

          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Dirección', _pista!.direccion),

          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.euro,
            'Precio',
            _pista!.precio != null ? '${_pista!.precio}€' : 'Gratis',
            valueColor: Colors.green,
          ),

          // Descripción si existe
          if (_pista!.descripcion != null &&
              _pista!.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 20),
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
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye una fila de información con icono
  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye la sección del mapa
  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_pista!.latitud, _pista!.longitud),
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      setState(() {
                        _mapLoaded = true;
                      });
                    },
                  ),
                  // Overlay de carga del mapa
                  if (!_mapLoaded)
                    Container(
                      color: Colors.white.withAlpha(178), // Semi-transparente
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Cargando mapa...'),
                          ],
                        ),
                      ),
                    ),
                  // Botón para abrir en aplicación de mapas
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(76),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el botón de reserva
  Widget _buildReserveButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _pista!.disponible
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: _pista!.disponible ? 2 : 0,
          ),
          onPressed:
              _pista!.disponible && !_procesandoReserva ? _reservarPista : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_procesandoReserva) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!_procesandoReserva && _pista!.disponible) ...[
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                _procesandoReserva
                    ? 'Procesando reserva...'
                    : _pista!.disponible
                        ? 'Reservar Pista'
                        : 'No disponible',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
