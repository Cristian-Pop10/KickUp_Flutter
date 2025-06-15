import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'package:uuid/uuid.dart';
import 'map_selector_view.dart';

/** Vista para crear o editar una pista deportiva.
 * Permite al usuario ingresar información completa de la pista incluyendo
 * ubicación mediante Google Maps, tipos múltiples, imágenes y validación
 * de formulario. Incluye integración con servicios de ubicación y geocodificación.
 */
class CrearPistaView extends StatefulWidget {
  /** ID del usuario que está creando/editando la pista */
  final String userId;

  /** Pista existente para modo edición (null para crear nueva) */
  final PistaModel? pistaExistente;

  const CrearPistaView({
    Key? key,
    required this.userId,
    this.pistaExistente,
  }) : super(key: key);

  @override
  _CrearPistaViewState createState() => _CrearPistaViewState();
}

class _CrearPistaViewState extends State<CrearPistaView> {
  final _formKey = GlobalKey<FormState>();
  final PistaController _pistaController = PistaController();
  bool _isLoading = false;
  bool _esAdmin = false;

  // Controladores para los campos del formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _imagenUrlController;
  bool _disponible = true;

  // Variables para ubicación y mapa
  double? _latitud;
  double? _longitud;
  bool _cargandoUbicacion = false;
  String _ubicacionTexto = 'Toca "Seleccionar en mapa" para elegir ubicación';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  /** Lista de tipos de pista disponibles para selección múltiple */
  final List<String> _tiposDisponibles = [
    'Fútbol 7',
    'Fútbol 11',
    'Fútbol Sala',
  ];
  List<String> _tiposSeleccionados = [];

  @override
  void initState() {
    super.initState();

    try {
      // Inicializar controladores
      _nombreController = TextEditingController();
      _direccionController = TextEditingController();
      _descripcionController = TextEditingController();
      _precioController = TextEditingController();
      _imagenUrlController = TextEditingController();

      // Verificar si el usuario es administrador
      _verificarPermisos();

      // Si estamos editando, cargar los datos de la pista existente
      if (widget.pistaExistente != null) {
        _cargarDatosPista();
      } else {
        // Establecer ubicación por defecto (Madrid)
        _latitud = 40.416775;
        _longitud = -3.703790;
        _actualizarMarcador();
      }
    } catch (e, stackTrace) {
      print('Error en initState: $e');
      print('StackTrace: $stackTrace');
      _mostrarError('Error al inicializar la vista: $e');
    }
  }

  /** Verifica si el usuario actual tiene permisos de administrador.
   * Actualiza el estado _esAdmin según el resultado de la verificación.
   */
  Future<void> _verificarPermisos() async {
    try {
      final esAdmin = await _pistaController.esUsuarioAdmin(widget.userId);

      if (mounted) {
        setState(() {
          _esAdmin = esAdmin;
        });
      }
    } catch (e, stackTrace) {
      print('Error al verificar permisos: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _esAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _nombreController.dispose();
      _direccionController.dispose();
      _descripcionController.dispose();
      _precioController.dispose();
      _imagenUrlController.dispose();
      _mapController?.dispose();
    } catch (e) {
      print('Error en dispose: $e');
    }
    super.dispose();
  }

  /** Carga los datos de la pista existente en el formulario.
   * Utilizado en modo edición para prellenar todos los campos
   * con la información actual de la pista.
   */
  void _cargarDatosPista() {
    try {
      final pista = widget.pistaExistente;
      if (pista == null) {
        print('Error: pistaExistente es null');
        return;
      }

      _nombreController.text = pista.nombre;
      _direccionController.text = pista.direccion;
      _descripcionController.text = pista.descripcion ?? '';
      _precioController.text = pista.precio?.toString() ?? '';
      _imagenUrlController.text = pista.imagenUrl ?? '';
      _disponible = pista.disponible;

      // Cargar tipos seleccionados
      if (pista.tipo != null && pista.tipo!.isNotEmpty) {
        _tiposSeleccionados = pista.tipo!
            .split(', ')
            .where((tipo) => _tiposDisponibles.contains(tipo))
            .toList();
      }

      // Establecer coordenadas
      _latitud = pista.latitud;
      _longitud = pista.longitud;
      _ubicacionTexto =
          'Lat: ${pista.latitud.toStringAsFixed(6)}, Lng: ${pista.longitud.toStringAsFixed(6)}';
      _actualizarMarcador();
    } catch (e, stackTrace) {
      print('Error al cargar datos de pista: $e');
      print('StackTrace: $stackTrace');
      _mostrarError('Error al cargar datos de la pista: $e');
    }
  }

  /** Actualiza el marcador en el mapa con la ubicación actual.
   * Crea un nuevo marcador rojo en las coordenadas especificadas
   * y actualiza el texto de ubicación mostrado.
   */
  void _actualizarMarcador() {
    if (_latitud != null && _longitud != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('ubicacion_pista'),
            position: LatLng(_latitud!, _longitud!),
            infoWindow: const InfoWindow(
              title: 'Ubicación de la pista',
              snippet: 'Toca para cambiar ubicación',
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
        _ubicacionTexto =
            'Lat: ${_latitud!.toStringAsFixed(6)}, Lng: ${_longitud!.toStringAsFixed(6)}';
      });
    }
  }

  /** Abre el selector de mapa en pantalla completa.
   * Navega a MapSelectorView y procesa el resultado para actualizar
   * la ubicación seleccionada y la dirección si es necesario.
   */
  Future<void> _abrirSelectorMapa() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => MapSelectorView(
          initialLatitude: _latitud,
          initialLongitude: _longitud,
          title: 'Seleccionar ubicación de la pista',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitud = result['latitude'];
        _longitud = result['longitude'];
        _ubicacionTexto = result['address'] ?? 'Ubicación seleccionada';
      });

      // Actualizar dirección si está vacía
      if (_direccionController.text.isEmpty && result['address'] != null) {
        _direccionController.text = result['address'];
      }

      _actualizarMarcador();

      // Mover cámara en el mapa pequeño
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_latitud!, _longitud!),
            15,
          ),
        );
      }
    }
  }

  /** Maneja el tap en el mapa pequeño para seleccionar ubicación.
   * Actualiza las coordenadas y obtiene la dirección correspondiente.
   */
  void _onMapTap(LatLng position) {
    setState(() {
      _latitud = position.latitude;
      _longitud = position.longitude;
    });
    _actualizarMarcador();
    _obtenerDireccionDesdeCoordenadas(position.latitude, position.longitude);
  }

  /** Obtiene la ubicación actual del usuario usando GPS.
   * Solicita permisos necesarios y maneja errores de ubicación.
   * Actualiza automáticamente el mapa y obtiene la dirección.
   */
  Future<void> _obtenerUbicacionActual() async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicios de ubicación deshabilitados');
        _mostrarMensaje('Los servicios de ubicación están deshabilitados');
        setState(() {
          _cargandoUbicacion = false;
        });
        return;
      }

      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permisos de ubicación denegados');
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _latitud = position.latitude;
          _longitud = position.longitude;
          _cargandoUbicacion = false;
        });

        _actualizarMarcador();

        // Mover cámara a la nueva ubicación
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15,
            ),
          );
        }

        // Intentar obtener dirección
        _obtenerDireccionDesdeCoordenadas(
            position.latitude, position.longitude);
      }
    } catch (e, stackTrace) {
      print('Error al obtener ubicación: $e');
      print('StackTrace: $stackTrace');
      _mostrarMensaje('Error al obtener ubicación actual: $e');
      if (mounted) {
        setState(() {
          _cargandoUbicacion = false;
        });
      }
    }
  }

  /** Obtiene la dirección legible a partir de coordenadas.
   * Utiliza geocodificación inversa para convertir lat/lng en dirección.
   * Actualiza automáticamente el campo de dirección si está vacío.
   */
  Future<void> _obtenerDireccionDesdeCoordenadas(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final street = placemark.street ?? '';
        final locality = placemark.locality ?? '';
        final country = placemark.country ?? '';

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

        // Actualizar el campo de dirección si está vacío
        if (_direccionController.text.isEmpty && direccion.isNotEmpty) {
          _direccionController.text = direccion;
        }
      }
    } catch (e, stackTrace) {
      print('Error al obtener dirección: $e');
      print('StackTrace: $stackTrace');
    }
  }

  /** Busca una dirección y obtiene sus coordenadas.
   * Utiliza geocodificación para convertir dirección en lat/lng.
   * Actualiza el mapa con la nueva ubicación encontrada.
   */
  Future<void> _buscarDireccion(String direccion) async {
    if (direccion.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa una dirección');
      return;
    }

    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      List<Location> locations = await locationFromAddress(direccion);

      if (locations.isNotEmpty && mounted) {
        final location = locations.first;

        setState(() {
          _latitud = location.latitude;
          _longitud = location.longitude;
          _cargandoUbicacion = false;
        });

        _actualizarMarcador();

        // Mover cámara a la nueva ubicación
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location.latitude, location.longitude),
              15,
            ),
          );
        }

        _mostrarMensaje('Ubicación encontrada correctamente');
      } else {
        _mostrarMensaje('No se pudo encontrar la dirección');
        setState(() {
          _cargandoUbicacion = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error al buscar dirección: $e');
      print('StackTrace: $stackTrace');
      _mostrarMensaje('No se pudo encontrar la dirección: $e');
      if (mounted) {
        setState(() {
          _cargandoUbicacion = false;
        });
      }
    }
  }

  /** Muestra una previsualización de la imagen en un diálogo modal.
   * Permite al usuario verificar que la URL de imagen es correcta
   * antes de guardar la pista.
   */
  void _previsualizarImagen() {
    final url = _imagenUrlController.text.trim();
    if (url.isEmpty) {
      _mostrarMensaje('Por favor ingresa una URL de imagen');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Previsualización'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 64),
                            SizedBox(height: 16),
                            Text('No se pudo cargar la imagen'),
                            SizedBox(height: 8),
                            Text(
                              'Verifica que la URL sea correcta',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /** Muestra un mensaje informativo al usuario */
  void _mostrarMensaje(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  /** Muestra un mensaje de error al usuario con estilo distintivo */
  void _mostrarError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /** Guarda la pista en la base de datos.
   * Valida el formulario, verifica coordenadas y tipos seleccionados,
   * procesa la URL de imagen y crea/actualiza el modelo de pista.
   */
  Future<void> _guardarPista() async {
    try {
      // Validar el formulario
      if (!_formKey.currentState!.validate()) {
        print('Formulario no válido');
        return;
      }

      // Verificar que se hayan establecido las coordenadas
      if (_latitud == null || _longitud == null) {
        print('No se han establecido coordenadas');
        _mostrarMensaje(
            'Por favor establece la ubicación de la pista en el mapa');
        return;
      }

      // Verificar que se haya seleccionado al menos un tipo
      if (_tiposSeleccionados.isEmpty) {
        _mostrarMensaje('Por favor selecciona al menos un tipo de pista');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Procesar URL de imagen con validación más flexible
      String? imagenUrl = _imagenUrlController.text.trim();
      if (imagenUrl.isEmpty) {
        imagenUrl = null;
      } else {
        // Validación más flexible para URLs
        if (!_esUrlValida(imagenUrl)) {
          setState(() {
            _isLoading = false;
          });
          _mostrarError(
              'URL de imagen inválida. Debe ser una URL válida que comience con http:// o https://');
          return;
        }
      }

      // Crear modelo de pista con los datos del formulario
      final pistaId = widget.pistaExistente?.id ?? 'pista_${const Uuid().v4()}';
      final precio = _precioController.text.trim().isEmpty
          ? null
          : double.tryParse(_precioController.text.trim());

      final pista = PistaModel(
        id: pistaId,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        latitud: _latitud!,
        longitud: _longitud!,
        tipo: _tiposSeleccionados.join(', '), // Unir tipos con comas
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        precio: precio,
        disponible: _disponible,
        imagenUrl: imagenUrl,
      );

      // Guardar o actualizar la pista
      bool exito;
      if (widget.pistaExistente != null) {
        exito = await _pistaController.actualizarPista(pista);
      } else {
        exito = await _pistaController.crearPista(pista);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.pistaExistente != null
                  ? 'Pista actualizada correctamente'
                  : 'Pista creada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.pistaExistente != null
                  ? 'Error al actualizar la pista'
                  : 'Error al crear la pista'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error al guardar pista: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _mostrarError('Error al guardar la pista: $e');
      }
    }
  }

  /** Valida si una URL es válida para imágenes.
   * Acepta URLs con o sin protocolo y verifica extensiones de imagen.
   * @param url URL a validar
   * @return true si la URL es válida, false en caso contrario
   */
  bool _esUrlValida(String url) {
    try {
      // Permitir URLs que empiecen con http, https, o incluso sin protocolo
      String urlToValidate = url.trim();

      // Si no tiene protocolo, añadir https por defecto
      if (!urlToValidate.startsWith('http://') &&
          !urlToValidate.startsWith('https://')) {
        urlToValidate = 'https://$urlToValidate';
      }

      final uri = Uri.parse(urlToValidate);

      // Verificar que tenga un host válido
      if (uri.host.isEmpty) return false;

      // Verificar que tenga una extensión de imagen común (opcional)
      final path = uri.path.toLowerCase();
      final hasImageExtension = path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.gif') ||
          path.endsWith('.webp') ||
          path.endsWith('.bmp') ||
          path.contains('image') ||
          path.isEmpty;

      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          hasImageExtension;
    } catch (e) {
      print('Error validando URL: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: Text(
            widget.pistaExistente != null ? 'Editar Pista' : 'Crear Pista',
            style: TextStyle(color: AppColors.textPrimary(context)),
          ),
          backgroundColor: AppColors.background(context),
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
          actions: _esAdmin
              ? [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildFormView(),
        bottomNavigationBar: _buildBottomBar(),
      );
    } catch (e, stackTrace) {
      print('Error en build: $e');
      print('StackTrace: $stackTrace');

      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Ha ocurrido un error'),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }
  }

  /** Construye la vista principal del formulario con todos los campos */
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mapa pequeño con botón para expandir
            _buildMapSection(),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nombreController,
              label: 'Nombre',
              hint: 'Nombre de la pista',
              icon: Icons.sports_soccer,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              hint: 'Dirección de la pista',
              icon: Icons.location_on,
              suffixIcon: IconButton(
                icon: _cargandoUbicacion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                onPressed: _cargandoUbicacion
                    ? null
                    : () => _buscarDireccion(_direccionController.text),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selector múltiple de tipos
            _buildTipoSelector(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Descripción de la pista',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _precioController,
              label: 'Precio (€)',
              hint: 'Ej: 25.0',
              icon: Icons.euro,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (double.tryParse(value.trim()) == null) {
                    return 'Precio inválido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo para URL de imagen
            _buildImageUrlField(),
            const SizedBox(height: 16),

            // Switch para disponibilidad
            _buildAvailabilitySwitch(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /** Construye la sección del mapa con controles integrados */
  Widget _buildMapSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          // Header del mapa con botón expandir
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ubicación de la pista',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Botón para expandir mapa
                ElevatedButton.icon(
                  onPressed: _abrirSelectorMapa,
                  icon: const Icon(Icons.fullscreen, size: 18),
                  label: const Text('Seleccionar en mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _cargandoUbicacion
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  onPressed:
                      _cargandoUbicacion ? null : _obtenerUbicacionActual,
                  tooltip: 'Mi ubicación',
                ),
              ],
            ),
          ),
          // Mapa pequeño
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_latitud ?? 40.416775, _longitud ?? -3.703790),
                  zoom: 13,
                ),
                markers: _markers,
                onTap: _onMapTap,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
              ),
            ),
          ),
          // Info de coordenadas
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _ubicacionTexto,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (_latitud != null && _longitud != null)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /** Construye el selector múltiple de tipos de pista */
  Widget _buildTipoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipos de pista',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            children: [
              if (_tiposSeleccionados.isNotEmpty) ...[
                // Mostrar tipos seleccionados como chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tiposSeleccionados.map((tipo) {
                    return Chip(
                      label: Text(tipo),
                      backgroundColor: Colors.green[100],
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _tiposSeleccionados.remove(tipo);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
              ],
              // Lista de tipos disponibles
              ...(_tiposDisponibles
                  .where((tipo) => !_tiposSeleccionados.contains(tipo))
                  .map((tipo) {
                return CheckboxListTile(
                  title: Text(tipo),
                  value: false,
                  onChanged: (bool? value) {
                    if (value == true) {
                      setState(() {
                        _tiposSeleccionados.add(tipo);
                      });
                    }
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList()),
              if (_tiposSeleccionados.length == _tiposDisponibles.length)
                const Text(
                  'Todos los tipos seleccionados',
                  style: TextStyle(
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

/** Construye el campo de URL de imagen con previsualización */
  Widget _buildImageUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'URL de la imagen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imagenUrlController,
          decoration: InputDecoration(
            hintText: 'https://ejemplo.com/imagen.jpg',
            prefixIcon: const Icon(Icons.image),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imagenUrlController.text.trim().isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        // Forzar reconstrucción de la previsualización
                      });
                    },
                    tooltip: 'Refrescar imagen',
                  ),
                  IconButton(
                    icon: const Icon(Icons.preview),
                    onPressed: _previsualizarImagen,
                    tooltip: 'Previsualizar imagen',
                  ),
                ],
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            // Forzar actualización del estado para mostrar/ocultar previsualización
            setState(() {
              print('URL de imagen cambiada: $value');
            });
          },
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (!_esUrlValida(value.trim())) {
                return 'URL inválida. Debe comenzar con http:// o https://';
              }
            }
            return null;
          },
        ),
        // Mostrar previsualización de la imagen si hay URL
        if (_imagenUrlController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImagePreview(),
        ],
      ],
    );
  }

/** Construye una previsualización de la imagen con controles */
  Widget _buildImagePreview() {
    final url = _imagenUrlController.text.trim();
    if (url.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Imagen principal
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cargando imagen...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error cargando imagen: $error');
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Error al cargar imagen',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verifica que la URL sea correcta',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              // Forzar recarga de la imagen
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Overlay con información
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(178),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Imagen cargada correctamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _previsualizarImagen,
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /** Construye el switch de disponibilidad de la pista */
  Widget _buildAvailabilitySwitch() {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green),
        const SizedBox(width: 16),
        const Text(
          'Disponible',
          style: TextStyle(fontSize: 16),
        ),
        const Spacer(),
        Switch(
          value: _disponible,
          onChanged: (value) {
            setState(() {
              _disponible = value;
            });
          },
          activeColor: Colors.green,
        ),
      ],
    );
  }

  /** Construye la barra inferior con el botón de guardar */
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _guardarPista,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Guardando...'),
                  ],
                )
              : Text(
                  widget.pistaExistente != null
                      ? 'ACTUALIZAR PISTA'
                      : 'GUARDAR PISTA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  /** Construye un campo de texto con estilo personalizado.
   * @param controller Controlador del campo
   * @param label Etiqueta del campo
   * @param hint Texto de ayuda
   * @param icon Icono del campo
   * @param suffixIcon Icono al final del campo
   * @param maxLines Número máximo de líneas
   * @param keyboardType Tipo de teclado
   * @param validator Función de validación
   */
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }
}
