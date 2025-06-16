import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'package:uuid/uuid.dart';
import 'map_selector_view.dart';

/** Vista para crear o editar pistas deportivas con integración de Google Maps.
 * Permite seleccionar ubicación mediante tap en mapa, gestión de tipos múltiples,
 * validación de formularios y previsualización de imágenes. Incluye funcionalidad
 * de geocodificación inversa para obtener direcciones automáticamente.
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
  // Controladores para manejar la lógica de negocio
  final _formKey = GlobalKey<FormState>();
  final PistaController _pistaController = PistaController();
  
  // Variables de estado principales
  bool _isLoading = false;
  bool _esAdmin = false;
  bool _disponible = true;

  // Controladores de campos de texto del formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _imagenUrlController;

  // Variables para manejo de ubicación y mapa
  double? _latitud;
  double? _longitud;
  bool _cargandoUbicacion = false;
  String _ubicacionTexto = 'Toca en el mapa para seleccionar ubicación';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Configuración de tipos de pista disponibles
  final List<String> _tiposDisponibles = [
    'Fútbol 7',
    'Fútbol 11',
    'Fútbol Sala',
  ];
  List<String> _tiposSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _inicializarVista();
  }

  /** Inicializa la vista y sus componentes principales.
   * Configura controladores, verifica permisos y carga datos existentes
   * si se está editando una pista.
   */
  void _inicializarVista() {
    try {
      _inicializarControladores();
      _verificarPermisos();

      if (widget.pistaExistente != null) {
        _cargarDatosPista();
      } else {
        _establecerUbicacionPorDefecto();
      }
    } catch (e, stackTrace) {
      _manejarError('Error al inicializar la vista', e, stackTrace);
    }
  }

  /** Inicializa todos los controladores de texto del formulario */
  void _inicializarControladores() {
    _nombreController = TextEditingController();
    _direccionController = TextEditingController();
    _descripcionController = TextEditingController();
    _precioController = TextEditingController();
    _imagenUrlController = TextEditingController();
  }

  /** Establece Madrid como ubicación por defecto para nuevas pistas */
  void _establecerUbicacionPorDefecto() {
    _latitud = 40.416775;
    _longitud = -3.703790;
    _actualizarMarcador();
  }

  /** Verifica si el usuario actual tiene permisos de administrador.
   * Los administradores tienen acceso a funcionalidades adicionales
   * como crear pistas sin restricciones.
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
      _manejarError('Error al verificar permisos', e, stackTrace);
      if (mounted) {
        setState(() {
          _esAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _liberarRecursos();
    super.dispose();
  }

  /** Libera todos los recursos utilizados para evitar memory leaks */
  void _liberarRecursos() {
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
  }

  /** Carga los datos de la pista existente en el formulario (modo edición).
   * Rellena todos los campos del formulario con la información de la pista
   * y configura el mapa con la ubicación actual.
   */
  void _cargarDatosPista() {
    try {
      final pista = widget.pistaExistente;
      if (pista == null) {
        print('Error: pistaExistente es null');
        return;
      }

      _cargarCamposTexto(pista);
      _cargarTiposSeleccionados(pista);
      _cargarUbicacionExistente(pista);
    } catch (e, stackTrace) {
      _manejarError('Error al cargar datos de pista', e, stackTrace);
    }
  }

  /** Carga los campos de texto con los datos de la pista existente */
  void _cargarCamposTexto(PistaModel pista) {
    _nombreController.text = pista.nombre;
    _direccionController.text = pista.direccion;
    _descripcionController.text = pista.descripcion ?? '';
    _precioController.text = pista.precio?.toString() ?? '';
    _imagenUrlController.text = pista.imagenUrl ?? '';
    _disponible = pista.disponible;
  }

  /** Carga los tipos de pista seleccionados desde la cadena almacenada */
  void _cargarTiposSeleccionados(PistaModel pista) {
    if (pista.tipo != null && pista.tipo!.isNotEmpty) {
      _tiposSeleccionados = pista.tipo!
          .split(', ')
          .where((tipo) => _tiposDisponibles.contains(tipo))
          .toList();
    }
  }

  /** Carga la ubicación existente de la pista en el mapa */
  void _cargarUbicacionExistente(PistaModel pista) {
    _latitud = pista.latitud;
    _longitud = pista.longitud;
    _ubicacionTexto =
        'Lat: ${pista.latitud.toStringAsFixed(6)}, Lng: ${pista.longitud.toStringAsFixed(6)}';
    _actualizarMarcador();
  }

  /** Actualiza el marcador en el mapa con la ubicación actual.
   * Crea un nuevo marcador rojo en las coordenadas especificadas
   * y actualiza el texto de ubicación mostrado al usuario.
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
   * Permite al usuario seleccionar una ubicación con mayor precisión
   * en una vista de mapa expandida con más herramientas de navegación.
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
      _procesarResultadoSelectorMapa(result);
    }
  }

  /** Procesa el resultado del selector de mapa en pantalla completa */
  void _procesarResultadoSelectorMapa(Map<String, dynamic> result) {
    setState(() {
      _latitud = result['latitude'];
      _longitud = result['longitude'];
    });

    _actualizarMarcador();
    _obtenerDireccionDesdeCoordenadas(_latitud!, _longitud!);
    _moverCamaraAUbicacion();
  }

  /** Mueve la cámara del mapa a la ubicación seleccionada con animación */
  void _moverCamaraAUbicacion() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_latitud!, _longitud!),
          15,
        ),
      );
    }
  }

  /** Maneja el tap en el mapa para seleccionar una nueva ubicación.
   * Actualiza las coordenadas, el marcador y obtiene la dirección
   * correspondiente mediante geocodificación inversa.
   * @param position Posición seleccionada en el mapa
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
   * Solicita permisos necesarios y maneja todos los casos de error
   * posibles como servicios deshabilitados o permisos denegados.
   */
  Future<void> _obtenerUbicacionActual() async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoUbicacion = true;
      });

      if (!await _verificarServiciosUbicacion()) return;
      if (!await _verificarPermisosUbicacion()) return;

      final position = await _obtenerPosicionGPS();
      _procesarUbicacionObtenida(position);
    } catch (e, stackTrace) {
      _manejarErrorUbicacion('Error al obtener ubicación actual', e, stackTrace);
    }
  }

  /** Verifica si los servicios de ubicación están habilitados en el dispositivo */
  Future<bool> _verificarServiciosUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicios de ubicación deshabilitados');
      _mostrarMensaje('Los servicios de ubicación están deshabilitados');
      setState(() {
        _cargandoUbicacion = false;
      });
      return false;
    }
    return true;
  }

  /** Verifica y solicita permisos de ubicación al usuario */
  Future<bool> _verificarPermisosUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permisos de ubicación denegados');
        _mostrarMensaje('Permisos de ubicación denegados');
        setState(() {
          _cargandoUbicacion = false;
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _mostrarMensaje('Permisos de ubicación denegados permanentemente');
      setState(() {
        _cargandoUbicacion = false;
      });
      return false;
    }

    return true;
  }

  /** Obtiene la posición GPS actual con alta precisión */
  Future<Position> _obtenerPosicionGPS() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /** Procesa la ubicación obtenida del GPS y actualiza la interfaz */
  void _procesarUbicacionObtenida(Position position) {
    if (mounted) {
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _cargandoUbicacion = false;
      });

      _actualizarMarcador();
      _moverCamaraAUbicacion();
      _obtenerDireccionDesdeCoordenadas(position.latitude, position.longitude);
    }
  }

  /** Obtiene la dirección legible a partir de coordenadas (geocodificación inversa).
   * Utiliza el servicio de geocoding para convertir coordenadas en una
   * dirección legible que se muestra automáticamente en el campo de dirección.
   * @param lat Latitud de la ubicación
   * @param lng Longitud de la ubicación
   */
  Future<void> _obtenerDireccionDesdeCoordenadas(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty && mounted) {
        final direccion = _construirDireccionLegible(placemarks.first);
        if (direccion.isNotEmpty) {
          _direccionController.text = direccion;
        }
      }
    } catch (e, stackTrace) {
      print('Error al obtener dirección: $e');
      print('StackTrace: $stackTrace');
    }
  }

  /** Construye una dirección legible a partir de un Placemark.
   * Combina calle, localidad y país en una cadena formateada.
   * @param placemark Información de ubicación obtenida del geocoding
   * @return Dirección formateada como cadena
   */
  String _construirDireccionLegible(Placemark placemark) {
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

    return direccion;
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
      builder: (context) => _construirDialogoPreview(url),
    );
  }

  /** Construye el diálogo de previsualización de imagen */
  Widget _construirDialogoPreview(String url) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _construirAppBarPreview(),
            _construirContenidoPreview(url),
          ],
        ),
      ),
    );
  }

  /** Construye el AppBar del diálogo de previsualización */
  Widget _construirAppBarPreview() {
    return AppBar(
      title: const Text('Previsualización'),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /** Construye el contenido del diálogo con la imagen */
  Widget _construirContenidoPreview(String url) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => _construirErrorImagen(),
        ),
      ),
    );
  }

  /** Construye el widget de error para imágenes que no cargan */
  Widget _construirErrorImagen() {
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
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /** Muestra un mensaje informativo al usuario mediante SnackBar */
  void _mostrarMensaje(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  /** Muestra un mensaje de error con estilo distintivo */
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

  /** Maneja errores relacionados con la ubicación */
  void _manejarErrorUbicacion(String mensaje, dynamic error, StackTrace stackTrace) {
    print('$mensaje: $error');
    print('StackTrace: $stackTrace');
    _mostrarMensaje('$mensaje: $error');
    if (mounted) {
      setState(() {
        _cargandoUbicacion = false;
      });
    }
  }

  /** Maneja errores generales con logging detallado */
  void _manejarError(String mensaje, dynamic error, StackTrace stackTrace) {
    print('$mensaje: $error');
    print('StackTrace: $stackTrace');
    _mostrarError('$mensaje: $error');
  }

  /** Guarda la pista en la base de datos después de validar todos los campos.
   * Realiza validaciones completas del formulario, ubicación y tipos seleccionados
   * antes de proceder con la operación de guardado (crear o actualizar).
   */
  Future<void> _guardarPista() async {
    try {
      if (!_validarFormularioCompleto()) return;

      setState(() {
        _isLoading = true;
      });

      final imagenUrl = await _procesarUrlImagen();
      if (imagenUrl == null && _imagenUrlController.text.trim().isNotEmpty) {
        return; // Error en validación de URL
      }

      final pista = _construirModeloPista(imagenUrl);
      final exito = await _ejecutarOperacionGuardado(pista);
      
      _manejarResultadoGuardado(exito);
    } catch (e, stackTrace) {
      _manejarErrorGuardado(e, stackTrace);
    }
  }

  /** Valida todo el formulario incluyendo campos, ubicación y tipos */
  bool _validarFormularioCompleto() {
    if (!_formKey.currentState!.validate()) {
      print('Formulario no válido');
      return false;
    }

    if (_latitud == null || _longitud == null) {
      print('No se han establecido coordenadas');
      _mostrarMensaje(
          'Por favor selecciona la ubicación de la pista en el mapa');
      return false;
    }

    if (_tiposSeleccionados.isEmpty) {
      _mostrarMensaje('Por favor selecciona al menos un tipo de pista');
      return false;
    }

    return true;
  }

  /** Procesa y valida la URL de imagen ingresada */
  Future<String?> _procesarUrlImagen() async {
    String? imagenUrl = _imagenUrlController.text.trim();
    if (imagenUrl.isEmpty) {
      return null;
    }

    if (!_esUrlValida(imagenUrl)) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError(
          'URL de imagen inválida. Debe ser una URL válida que comience con http:// o https://');
      return null;
    }

    return imagenUrl;
  }

  /** Construye el modelo de pista con todos los datos del formulario */
  PistaModel _construirModeloPista(String? imagenUrl) {
    final pistaId = widget.pistaExistente?.id ?? 'pista_${const Uuid().v4()}';
    final precio = _precioController.text.trim().isEmpty
        ? null
        : double.tryParse(_precioController.text.trim());

    return PistaModel(
      id: pistaId,
      nombre: _nombreController.text.trim(),
      direccion: _direccionController.text.trim(),
      latitud: _latitud!,
      longitud: _longitud!,
      tipo: _tiposSeleccionados.join(', '),
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      precio: precio,
      disponible: _disponible,
      imagenUrl: imagenUrl,
    );
  }

  /** Ejecuta la operación de guardado (crear o actualizar) según el contexto */
  Future<bool> _ejecutarOperacionGuardado(PistaModel pista) async {
    if (widget.pistaExistente != null) {
      return await _pistaController.actualizarPista(pista);
    } else {
      return await _pistaController.crearPista(pista);
    }
  }

  /** Maneja el resultado de la operación de guardado y muestra feedback */
  void _manejarResultadoGuardado(bool exito) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (exito) {
        _mostrarExitoGuardado();
        Navigator.of(context).pop(true);
      } else {
        _mostrarErrorGuardado();
      }
    }
  }

  /** Muestra mensaje de éxito al guardar */
  void _mostrarExitoGuardado() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.pistaExistente != null
            ? 'Pista actualizada correctamente'
            : 'Pista creada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /** Muestra mensaje de error al guardar */
  void _mostrarErrorGuardado() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.pistaExistente != null
            ? 'Error al actualizar la pista'
            : 'Error al crear la pista'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /** Maneja errores durante el proceso de guardado */
  void _manejarErrorGuardado(dynamic error, StackTrace stackTrace) {
    print('Error al guardar pista: $error');
    print('StackTrace: $stackTrace');

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al guardar la pista: $error');
    }
  }

  /** Valida si una URL es válida para imágenes.
   * Verifica el esquema HTTP/HTTPS y extensiones de imagen comunes.
   * @param url URL a validar
   * @return true si la URL es válida para imágenes
   */
  bool _esUrlValida(String url) {
    try {
      String urlToValidate = url.trim();

      if (!urlToValidate.startsWith('http://') &&
          !urlToValidate.startsWith('https://')) {
        urlToValidate = 'https://$urlToValidate';
      }

      final uri = Uri.parse(urlToValidate);

      if (uri.host.isEmpty) return false;

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
        appBar: _construirAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildFormView(),
        bottomNavigationBar: _buildBottomBar(),
      );
    } catch (e, stackTrace) {
      return _construirPantallaError(e, stackTrace);
    }
  }

  /** Construye el AppBar con título dinámico y badge de administrador */
  PreferredSizeWidget _construirAppBar() {
    return AppBar(
      title: Text(
        widget.pistaExistente != null ? 'Editar Pista' : 'Crear Pista',
        style: TextStyle(color: AppColors.textPrimary(context)),
      ),
      backgroundColor: AppColors.background(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
      actions: _esAdmin ? [_construirBadgeAdmin()] : null,
    );
  }

  /** Construye el badge de administrador en el AppBar */
  Widget _construirBadgeAdmin() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  /** Construye la pantalla de error cuando ocurre una excepción */
  Widget _construirPantallaError(dynamic error, StackTrace stackTrace) {
    print('Error en build: $error');
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
            Text('$error'),
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

  /** Construye la vista principal del formulario con todos los campos */
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMapSection(),
            const SizedBox(height: 24),
            _construirCampoNombre(),
            const SizedBox(height: 16),
            _construirCampoDireccion(),
            const SizedBox(height: 16),
            _buildTipoSelector(),
            const SizedBox(height: 16),
            _construirCampoDescripcion(),
            const SizedBox(height: 16),
            _construirCampoPrecio(),
            const SizedBox(height: 16),
            _buildImageUrlField(),
            const SizedBox(height: 16),
            _buildAvailabilitySwitch(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /** Construye el campo de nombre con validación obligatoria */
  Widget _construirCampoNombre() {
    return _buildTextField(
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
    );
  }

  /** Construye el campo de dirección (solo lectura, se actualiza automáticamente) */
  Widget _construirCampoDireccion() {
    return _buildTextField(
      controller: _direccionController,
      label: 'Dirección',
      hint: 'Se actualizará automáticamente al seleccionar ubicación',
      icon: Icons.location_on,
      readOnly: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor selecciona una ubicación en el mapa';
        }
        return null;
      },
    );
  }

  /** Construye el campo de descripción (opcional) */
  Widget _construirCampoDescripcion() {
    return _buildTextField(
      controller: _descripcionController,
      label: 'Descripción',
      hint: 'Descripción de la pista',
      icon: Icons.description,
      maxLines: 3,
    );
  }

  /** Construye el campo de precio con validación numérica */
  Widget _construirCampoPrecio() {
    return _buildTextField(
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
    );
  }

  /** Construye la sección del mapa con controles integrados.
   * Incluye el mapa interactivo, botones para pantalla completa y ubicación actual,
   * y información de coordenadas en la parte inferior.
   */
  Widget _buildMapSection() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          _construirHeaderMapa(),
          _construirMapaInteractivo(),
          _construirInfoUbicacion(),
        ],
      ),
    );
  }

  /** Construye el header del mapa con controles de navegación */
  Widget _construirHeaderMapa() {
    return Container(
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
              'Toca en el mapa para seleccionar ubicación',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          _construirBotonMapaCompleto(),
          const SizedBox(width: 8),
          _construirBotonMiUbicacion(),
        ],
      ),
    );
  }

  /** Construye el botón para abrir el mapa en pantalla completa */
  Widget _construirBotonMapaCompleto() {
    return ElevatedButton.icon(
      onPressed: _abrirSelectorMapa,
      icon: const Icon(Icons.fullscreen, size: 18),
      label: const Text('Mapa completo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  /** Construye el botón para obtener la ubicación actual del usuario */
  Widget _construirBotonMiUbicacion() {
    return IconButton(
      icon: _cargandoUbicacion
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      onPressed: _cargandoUbicacion ? null : _obtenerUbicacionActual,
      tooltip: 'Mi ubicación',
    );
  }

  /** Construye el mapa interactivo de Google Maps */
  Widget _construirMapaInteractivo() {
    return Expanded(
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
          zoomControlsEnabled: true,
          mapType: MapType.normal,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),
      ),
    );
  }

  /** Construye la información de ubicación en la parte inferior del mapa */
  Widget _construirInfoUbicacion() {
    return Container(
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
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  /** Construye el selector múltiple de tipos de pista.
   * Permite seleccionar uno o más tipos de pista de una lista predefinida,
   * mostrando chips para los tipos seleccionados y checkboxes para los disponibles.
   */
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
                _construirChipsTiposSeleccionados(),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
              ],
              ..._construirListaTiposDisponibles(),
              if (_tiposSeleccionados.length == _tiposDisponibles.length)
                _construirMensajeTodosSeleccionados(),
            ],
          ),
        ),
      ],
    );
  }

  /** Construye los chips de tipos seleccionados con opción de eliminar */
  Widget _construirChipsTiposSeleccionados() {
    return Wrap(
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
    );
  }

  /** Construye la lista de tipos disponibles como checkboxes */
  List<Widget> _construirListaTiposDisponibles() {
    return _tiposDisponibles
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
    }).toList();
  }

  /** Construye el mensaje cuando todos los tipos están seleccionados */
  Widget _construirMensajeTodosSeleccionados() {
    return const Text(
      'Todos los tipos seleccionados',
      style: TextStyle(
        color: Colors.green,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /** Construye el campo de URL de imagen con previsualización.
   * Incluye validación de URL, botones de refrescar y previsualizar,
   * y una vista previa automática de la imagen cuando la URL es válida.
   */
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
        _construirCampoUrlImagen(),
        if (_imagenUrlController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImagePreview(),
        ],
      ],
    );
  }

  /** Construye el campo de texto para la URL de imagen */
  Widget _construirCampoUrlImagen() {
    return TextFormField(
      controller: _imagenUrlController,
      decoration: InputDecoration(
        hintText: 'https://ejemplo.com/imagen.jpg',
        prefixIcon: const Icon(Icons.image),
        suffixIcon: _construirBotonesUrlImagen(),
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
    );
  }

  /** Construye los botones de acción para el campo URL (refrescar y previsualizar) */
  Widget? _construirBotonesUrlImagen() {
    if (_imagenUrlController.text.trim().isEmpty) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {});
          },
          tooltip: 'Refrescar imagen',
        ),
        IconButton(
          icon: const Icon(Icons.preview),
          onPressed: _previsualizarImagen,
          tooltip: 'Previsualizar imagen',
        ),
      ],
    );
  }

  /** Construye la previsualización de la imagen con manejo de estados */
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
            _construirImagenPreview(url),
            _construirOverlayImagen(),
          ],
        ),
      ),
    );
  }

  /** Construye la imagen de previsualización con manejo de carga y errores */
  Widget _construirImagenPreview(String url) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: _construirIndicadorCarga,
        errorBuilder: (context, error, stackTrace) => _construirErrorImagenPreview(),
      ),
    );
  }

  /** Construye el indicador de carga para la imagen */
  Widget _construirIndicadorCarga(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
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
  }

  /** Construye el widget de error para la previsualización de imagen */
  Widget _construirErrorImagenPreview() {
    print('Error cargando imagen');
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
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _construirBotonReintentar(),
        ],
      ),
    );
  }

  /** Construye el botón de reintentar para cargar la imagen */
  Widget _construirBotonReintentar() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {});
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
    );
  }

  /** Construye el overlay de información sobre la imagen cargada */
  Widget _construirOverlayImagen() {
    return Positioned(
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

  /** Construye la barra inferior con el botón de guardar.
   * Incluye indicador de carga y texto dinámico según el estado
   * de la operación (crear/actualizar).
   */
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
          child: _isLoading ? _construirIndicadorGuardando() : _construirTextoBoton(),
        ),
      ),
    );
  }

  /** Construye el indicador de carga durante el guardado */
  Widget _construirIndicadorGuardando() {
    return const Row(
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
    );
  }

  /** Construye el texto del botón según el modo (crear/actualizar) */
  Widget _construirTextoBoton() {
    return Text(
      widget.pistaExistente != null
          ? 'ACTUALIZAR PISTA'
          : 'GUARDAR PISTA',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /** Construye un campo de texto personalizado reutilizable.
   * Proporciona un diseño consistente para todos los campos del formulario
   * con validación, iconos y estilos personalizables.
   * @param controller Controlador del campo de texto
   * @param label Etiqueta del campo
   * @param hint Texto de ayuda
   * @param icon Icono a mostrar
   * @param suffixIcon Icono adicional al final (opcional)
   * @param maxLines Número máximo de líneas
   * @param keyboardType Tipo de teclado
   * @param validator Función de validación
   * @param readOnly Si el campo es de solo lectura
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
    bool readOnly = false,
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
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
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