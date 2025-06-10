import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/** Vista de selección de ubicación en mapa interactivo.
 * Permite a los usuarios seleccionar ubicaciones mediante tap en el mapa,
 * búsqueda por dirección, o usando su ubicación actual. Incluye servicios
 * de geocodificación para convertir entre coordenadas y direcciones.
 */
class MapSelectorView extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String title;

  const MapSelectorView({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'Seleccionar ubicación',
  }) : super(key: key);

  @override
  State<MapSelectorView> createState() => _MapSelectorViewState();
}

class _MapSelectorViewState extends State<MapSelectorView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _direccionTexto = 'Toca en el mapa para seleccionar ubicación';
  bool _cargandoUbicacion = false;
  bool _obteniendoDireccion = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Usar coordenadas iniciales si se proporcionan
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _actualizarMarcador();
      _obtenerDireccionDesdeCoordenadas(_selectedLatitude!, _selectedLongitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /** Actualiza el marcador en el mapa con la ubicación seleccionada */
  void _actualizarMarcador() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('ubicacion_seleccionada'),
            position: LatLng(_selectedLatitude!, _selectedLongitude!),
            infoWindow: const InfoWindow(
              title: 'Ubicación seleccionada',
              snippet: 'Toca para cambiar',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
    }
  }

  /** Maneja el evento de tap en el mapa para seleccionar ubicación */
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });
    _actualizarMarcador();
    _obtenerDireccionDesdeCoordenadas(position.latitude, position.longitude);
  }

  /** Obtiene la ubicación actual del usuario usando GPS.
   * Incluye manejo completo de permisos y estados de error.
   */
  Future<void> _obtenerUbicacionActual() async {
    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarMensaje('Los servicios de ubicación están deshabilitados');
        setState(() {
          _cargandoUbicacion = false;
        });
        return;
      }

      // Verificar y solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarMensaje('Permisos de ubicación denegados');
          setState(() {
            _cargandoUbicacion = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarMensaje('Permisos de ubicación denegados permanentemente');
        setState(() {
          _cargandoUbicacion = false;
        });
        return;
      }

      // Obtener posición actual con timeout
      final position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
        // ignore: deprecated_member_use
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _cargandoUbicacion = false;
        });

        _actualizarMarcador();
        
        // Mover cámara a la ubicación actual
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              16,
            ),
          );
        }

        _obtenerDireccionDesdeCoordenadas(position.latitude, position.longitude);
      }
    } catch (e) {
      _mostrarMensaje('Error al obtener ubicación: $e');
      if (mounted) {
        setState(() {
          _cargandoUbicacion = false;
        });
      }
    }
  }

  /** Busca una dirección usando el servicio de geocodificación */
  Future<void> _buscarDireccion() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _mostrarMensaje('Ingresa una dirección para buscar');
      return;
    }

    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        setState(() {
          _selectedLatitude = location.latitude;
          _selectedLongitude = location.longitude;
          _cargandoUbicacion = false;
        });
        
        _actualizarMarcador();
        
        // Mover cámara a la ubicación encontrada
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location.latitude, location.longitude),
              16,
            ),
          );
        }
        
        _obtenerDireccionDesdeCoordenadas(location.latitude, location.longitude);
        _mostrarMensaje('Ubicación encontrada');
      } else {
        _mostrarMensaje('No se encontró la dirección');
        setState(() {
          _cargandoUbicacion = false;
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al buscar: $e');
      setState(() {
        _cargandoUbicacion = false;
      });
    }
  }

  /** Obtiene la dirección legible desde coordenadas usando geocodificación inversa */
  Future<void> _obtenerDireccionDesdeCoordenadas(double lat, double lng) async {
    try {
      setState(() {
        _obteniendoDireccion = true;
        _direccionTexto = 'Obteniendo dirección...';
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final street = placemark.street ?? '';
        final locality = placemark.locality ?? '';
        final country = placemark.country ?? '';
        
        // Construir dirección legible
        String direccion = '';
        if (street.isNotEmpty) direccion += street;
        if (locality.isNotEmpty) {
          if (direccion.isNotEmpty) direccion += ', ';
          direccion += locality;
        }
        if (country.isNotEmpty) {
          if (direccion.isNotEmpty) direccion += ', ';
          direccion += country;
        }
        
        setState(() {
          _direccionTexto = direccion.isNotEmpty 
              ? direccion 
              : 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
          _obteniendoDireccion = false;
        });
      } else {
        setState(() {
          _direccionTexto = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
          _obteniendoDireccion = false;
        });
      }
    } catch (e) {
      setState(() {
        _direccionTexto = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        _obteniendoDireccion = false;
      });
    }
  }

  /** Muestra un mensaje temporal al usuario */
  void _mostrarMensaje(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  /** Confirma la selección y retorna los datos de ubicación */
  void _confirmarSeleccion() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      Navigator.of(context).pop({
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'address': _direccionTexto,
      });
    } else {
      _mostrarMensaje('Por favor selecciona una ubicación en el mapa');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // Botón de confirmar en el AppBar
          TextButton.icon(
            onPressed: _confirmarSeleccion,
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text(
              'Confirmar',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda superior
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _buscarDireccion(),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de ubicación actual
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _cargandoUbicacion ? null : _obtenerUbicacionActual,
                    icon: _cargandoUbicacion
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.my_location, color: Colors.white),
                    tooltip: 'Mi ubicación',
                  ),
                ),
              ],
            ),
          ),
          
          // Mapa principal
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.initialLatitude ?? 40.416775,
                  widget.initialLongitude ?? -3.703790,
                ),
                zoom: 15,
              ),
              markers: _markers,
              onTap: _onMapTap,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),
          
          // Panel de información inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _selectedLatitude != null ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ubicación seleccionada:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Mostrar estado de carga o dirección
                if (_obteniendoDireccion)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Obteniendo dirección...'),
                    ],
                  )
                else
                  Text(
                    _direccionTexto,
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedLatitude != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                
                // Mostrar coordenadas si hay ubicación seleccionada
                if (_selectedLatitude != null && _selectedLongitude != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coordenadas: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Botón de confirmación principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmarSeleccion,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLatitude != null ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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