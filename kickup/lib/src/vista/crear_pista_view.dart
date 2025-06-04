import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../controlador/pista_controller.dart';
import '../modelo/pista_model.dart';
import 'package:uuid/uuid.dart';

class CrearPistaView extends StatefulWidget {
  final String userId;
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
  bool _esAdmin = false; // Variable para verificar si es admin

  // Controladores para los campos del formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _tipoController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _imagenUrlController;
  bool _disponible = true;

  // Variables para ubicación
  double? _latitud;
  double? _longitud;
  bool _cargandoUbicacion = false;
  String _ubicacionTexto = 'No seleccionada';

  @override
  void initState() {
    super.initState();
    
    try {
      // Inicializar controladores
      _nombreController = TextEditingController();
      _direccionController = TextEditingController();
      _tipoController = TextEditingController();
      _descripcionController = TextEditingController();
      _precioController = TextEditingController();
      _imagenUrlController = TextEditingController();

      print('CrearPistaView: Inicializando...');
      print('UserId: ${widget.userId}');
      print('PistaExistente: ${widget.pistaExistente?.id ?? 'null'}');

      // Verificar si el usuario es administrador
      _verificarPermisos();

      // Si estamos editando, cargar los datos de la pista existente
      if (widget.pistaExistente != null) {
        _cargarDatosPista();
      }
    } catch (e, stackTrace) {
      print('Error en initState: $e');
      print('StackTrace: $stackTrace');
      _mostrarError('Error al inicializar la vista: $e');
    }
  }

  /// Verifica si el usuario actual es administrador
  Future<void> _verificarPermisos() async {
    try {
      print('Verificando permisos de administrador para usuario: ${widget.userId}');
      
      final esAdmin = await _pistaController.esUsuarioAdmin(widget.userId);
      
      if (mounted) {
        setState(() {
          _esAdmin = esAdmin;
        });
        print('Usuario es admin: $_esAdmin');
      }
    } catch (e, stackTrace) {
      print('Error al verificar permisos: $e');
      print('StackTrace: $stackTrace');
      // En caso de error, asumir que no es admin
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
      print('CrearPistaView: Disposing...');
      _nombreController.dispose();
      _direccionController.dispose();
      _tipoController.dispose();
      _descripcionController.dispose();
      _precioController.dispose();
      _imagenUrlController.dispose();
    } catch (e) {
      print('Error en dispose: $e');
    }
    super.dispose();
  }

  /// Carga los datos de la pista existente en el formulario
  void _cargarDatosPista() {
    try {
      final pista = widget.pistaExistente;
      if (pista == null) {
        print('Error: pistaExistente es null');
        return;
      }
      
      print('Cargando datos de pista: ${pista.id}');
      
      _nombreController.text = pista.nombre;
      _direccionController.text = pista.direccion;
      _tipoController.text = pista.tipo ?? '';
      _descripcionController.text = pista.descripcion ?? '';
      _precioController.text = pista.precio?.toString() ?? '';
      _imagenUrlController.text = pista.imagenUrl ?? '';
      _disponible = pista.disponible;
      
      // Establecer coordenadas
      _latitud = pista.latitud;
      _longitud = pista.longitud;
      _ubicacionTexto = 'Lat: ${pista.latitud.toStringAsFixed(6)}, Lng: ${pista.longitud.toStringAsFixed(6)}';
      
      print('Datos cargados correctamente');
      print('URL de imagen cargada: ${pista.imagenUrl}');
    } catch (e, stackTrace) {
      print('Error al cargar datos de pista: $e');
      print('StackTrace: $stackTrace');
      _mostrarError('Error al cargar datos de la pista: $e');
    }
  }

  /// Obtiene la ubicación actual del usuario
  Future<void> _obtenerUbicacionActual() async {
    if (!mounted) return;
    
    try {
      print('Obteniendo ubicación actual...');
      
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
        print('Permisos de ubicación denegados permanentemente');
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

      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _latitud = position.latitude;
          _longitud = position.longitude;
          _ubicacionTexto = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          _cargandoUbicacion = false;
        });
        
        // Intentar obtener dirección
        _obtenerDireccionDesdeCoordenadas(position.latitude, position.longitude);
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

  /// Obtiene la dirección a partir de las coordenadas
  Future<void> _obtenerDireccionDesdeCoordenadas(double lat, double lng) async {
    try {
      print('Obteniendo dirección para: $lat, $lng');
      
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
        
        print('Dirección obtenida: $direccion');
        
        // Solo actualizar si el campo está vacío
        if (_direccionController.text.isEmpty) {
          _direccionController.text = direccion.isNotEmpty ? direccion : 'Dirección no disponible';
        }
      }
    } catch (e, stackTrace) {
      print('Error al obtener dirección: $e');
      print('StackTrace: $stackTrace');
      // No mostrar error al usuario, es opcional
    }
  }

  /// Busca una dirección y obtiene sus coordenadas
  Future<void> _buscarDireccion(String direccion) async {
    if (direccion.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa una dirección');
      return;
    }

    try {
      print('Buscando dirección: $direccion');
      
      setState(() {
        _cargandoUbicacion = true;
      });

      List<Location> locations = await locationFromAddress(direccion);
      
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        
        print('Dirección encontrada en: ${location.latitude}, ${location.longitude}');
        
        setState(() {
          _latitud = location.latitude;
          _longitud = location.longitude;
          _ubicacionTexto = 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
          _cargandoUbicacion = false;
        });
        
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

  /// Permite introducir coordenadas manualmente
  Future<void> _introducirCoordenadasManualmente() async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    
    // Si ya hay coordenadas, pre-llenar los campos
    if (_latitud != null && _longitud != null) {
      latController.text = _latitud.toString();
      lngController.text = _longitud.toString();
    }

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Introducir Coordenadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitud',
                hintText: 'Ej: 40.416775',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitud',
                hintText: 'Ej: -3.703790',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              
              if (lat != null && lng != null) {
                Navigator.of(context).pop({'lat': lat, 'lng': lng});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coordenadas inválidas')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitud = result['lat'];
        _longitud = result['lng'];
        _ubicacionTexto = 'Lat: ${_latitud!.toStringAsFixed(6)}, Lng: ${_longitud!.toStringAsFixed(6)}';
      });
      
      // Intentar obtener dirección
      _obtenerDireccionDesdeCoordenadas(_latitud!, _longitud!);
    }
    
    latController.dispose();
    lngController.dispose();
  }

  /// Abre Google Maps en el navegador para ver la ubicación
  void _verEnGoogleMaps() {
    if (_latitud == null || _longitud == null) {
      _mostrarMensaje('No hay ubicación seleccionada');
      return;
    }
    
    final url = 'https://www.google.com/maps/search/?api=1&query=$_latitud,$_longitud';
    _mostrarMensaje('Abriendo Google Maps en el navegador...');
    // Aquí normalmente usaríamos url_launcher para abrir el navegador
    print('URL para abrir: $url');
  }

  /// Previsualiza la imagen en un diálogo
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
                              style: TextStyle(fontSize: 12, color: Colors.grey),
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

  /// Muestra un mensaje al usuario
  void _mostrarMensaje(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  /// Muestra un error al usuario
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

  /// Guarda la pista (nueva o actualizada) - versión mejorada
  Future<void> _guardarPista() async {
    try {
      print('Iniciando guardado de pista...');
      
      // Validar el formulario
      if (!_formKey.currentState!.validate()) {
        print('Formulario no válido');
        return;
      }

      // Verificar que se hayan establecido las coordenadas
      if (_latitud == null || _longitud == null) {
        print('No se han establecido coordenadas');
        _mostrarMensaje('Por favor establece la ubicación de la pista');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Procesar URL de imagen
      String? imagenUrl = _imagenUrlController.text.trim();
      if (imagenUrl.isEmpty) {
        imagenUrl = null;
      } else {
        // Validar URL antes de guardar
        final uri = Uri.tryParse(imagenUrl);
        if (uri == null || !uri.hasScheme) {
          setState(() {
            _isLoading = false;
          });
          _mostrarError('URL de imagen inválida');
          return;
        }
      }

      // Crear modelo de pista con los datos del formulario
      final pistaId = widget.pistaExistente?.id ?? 'pista_${const Uuid().v4()}';
      final precio = _precioController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_precioController.text.trim());
      
      print('Creando modelo de pista con ID: $pistaId');
      print('URL de imagen: $imagenUrl');
      
      final pista = PistaModel(
        id: pistaId,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        latitud: _latitud!,
        longitud: _longitud!,
        tipo: _tipoController.text.trim().isEmpty ? null : _tipoController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        precio: precio,
        disponible: _disponible,
        imagenUrl: imagenUrl, // Usar la URL procesada
      );

      print('Modelo de pista creado: ${pista.toJson()}');

      // Guardar o actualizar la pista
      bool exito;
      if (widget.pistaExistente != null) {
        print('Actualizando pista existente...');
        exito = await _pistaController.actualizarPista(pista);
      } else {
        print('Creando nueva pista...');
        exito = await _pistaController.crearPista(pista);
      }

      print('Resultado del guardado: $exito');

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

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          title: Text(
            // Título normal sin "Gestión de pista" para todos los usuarios
            widget.pistaExistente != null ? 'Editar Pista' : 'Crear Pista',
            style: TextStyle(color: AppColors.textPrimary(context)),
          ),
          backgroundColor: AppColors.background(context),
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
          // Mostrar indicador de admin si corresponde
          actions: _esAdmin ? [
            Container(
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
            ),
          ] : null,
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

  /// Construye la vista del formulario - versión actualizada
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información de ubicación
            _buildLocationInfo(),
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
            
            _buildTextField(
              controller: _tipoController,
              label: 'Tipo',
              hint: 'Ej: Fútbol 7, Fútbol 11, Fútbol Sala',
              icon: Icons.category,
            ),
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
            
            // Campo de imagen mejorado
            _buildImageUrlField(),
            const SizedBox(height: 16),
            
            // Switch para disponibilidad
            _buildAvailabilitySwitch(),
            const SizedBox(height: 100), // Espacio para el bottom bar
          ],
        ),
      ),
    );
  }

  /// Construye un campo de texto con estilo personalizado y validación mejorada para URL de imagen
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
            suffixIcon: _imagenUrlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.preview),
                    onPressed: _previsualizarImagen,
                    tooltip: 'Previsualizar imagen',
                  )
                : null,
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
            // Forzar actualización del estado cuando cambie la URL
            setState(() {
              // Esto asegura que el suffixIcon se actualice
            });
            print('URL de imagen cambiada: $value');
          },
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              // Validar que sea una URL válida
              final uri = Uri.tryParse(value.trim());
              if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                return 'URL inválida. Debe comenzar con http:// o https://';
              }
              // Validar que sea una imagen
              final extension = value.toLowerCase();
              if (!extension.contains('.jpg') && 
                  !extension.contains('.jpeg') && 
                  !extension.contains('.png') && 
                  !extension.contains('.gif') && 
                  !extension.contains('.webp')) {
                return 'La URL debe apuntar a una imagen (jpg, png, gif, webp)';
              }
            }
            return null;
          },
        ),
        // Mostrar previsualización de la imagen si hay URL
        if (_imagenUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildImagePreview(),
        ],
      ],
    );
  }

  /// Construye una previsualización de la imagen
  Widget _buildImagePreview() {
    final url = _imagenUrlController.text.trim();
    if (url.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Error al cargar imagen',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye la información de ubicación
  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Ubicación de la pista',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _ubicacionTexto,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cargandoUbicacion ? null : _obtenerUbicacionActual,
                  icon: _cargandoUbicacion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Mi ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _introducirCoordenadasManualmente,
                  icon: const Icon(Icons.edit_location),
                  label: const Text('Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (_latitud != null && _longitud != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _verEnGoogleMaps,
                icon: const Icon(Icons.map),
                label: const Text('Ver en Google Maps'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye el switch de disponibilidad
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

  /// Construye la barra inferior con el botón de guardar
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
                  widget.pistaExistente != null ? 'ACTUALIZAR PISTA' : 'GUARDAR PISTA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  /// Construye un campo de texto con estilo personalizado
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
