import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controlador/partido_controller.dart';
import '../controlador/pista_controller.dart';
import '../modelo/partido_model.dart';
import '../modelo/user_model.dart';
import '../modelo/pista_model.dart';

class CrearPartidoView extends StatefulWidget {
  final String userId;

  const CrearPartidoView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CrearPartidoView> createState() => _CrearPartidoViewState();
}

class _CrearPartidoViewState extends State<CrearPartidoView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PartidoController _partidoController = PartidoController();
  final PistaController _pistaController = PistaController();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _integrantesController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  // Variables para almacenar los valores seleccionados
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;
  
  // Variables para pistas
  List<PistaModel> _pistas = [];
  PistaModel? _pistaSeleccionada;
  bool _cargandoPistas = true;

  // Lista de tipos de partido con iconos y colores
  final List<Map<String, dynamic>> _tiposPartido = [
    {
      'nombre': 'Fútbol Sala',
      'icono': Icons.sports_soccer,
      'jugadores': '5 vs 5',
      'color': Colors.purple,
      'maxIntegrantes': 10,
    },
    {
      'nombre': 'Fútbol 7',
      'icono': Icons.sports_soccer,
      'jugadores': '7 vs 7',
      'color': Colors.green,
      'maxIntegrantes': 14,
    },
    {
      'nombre': 'Fútbol 11',
      'icono': Icons.sports_soccer,
      'jugadores': '11 vs 11',
      'color': Colors.orange,
      'maxIntegrantes': 22,
    },
  ];

  String _tipoSeleccionado = 'Fútbol Sala';

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();
    
    // Cargar pistas disponibles
    _cargarPistas();
  }

  /// Actualiza el precio por persona basado en la pista seleccionada y el número de jugadores
  void _actualizarPrecioPorPersona() {
    if (_pistaSeleccionada?.precio != null) {
      final maxJugadores = _tipoPartidoSeleccionado['maxIntegrantes'];
      final numJugadores = int.tryParse(_integrantesController.text) ?? maxJugadores;
      
      if (numJugadores > 0) {
        final precioPorPersona = (_pistaSeleccionada!.precio! / numJugadores).toStringAsFixed(2);
        _precioController.text = precioPorPersona;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _integrantesController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _precioController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Carga las pistas disponibles
  Future<void> _cargarPistas() async {
    try {
      final pistas = await _pistaController.obtenerPistas();
      // Filtrar solo las pistas disponibles
      final pistasDisponibles = pistas.where((pista) => pista.disponible).toList();
      
      if (mounted) {
        setState(() {
          _pistas = pistasDisponibles;
          _cargandoPistas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoPistas = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pistas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtiene el tipo de partido seleccionado
  Map<String, dynamic> get _tipoPartidoSeleccionado {
    return _tiposPartido.firstWhere(
      (tipo) => tipo['nombre'] == _tipoSeleccionado,
      orElse: () => _tiposPartido.first,
    );
  }

  /// Muestra el selector de tipo de partido mejorado
  void _mostrarSelectorTipo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    'Seleccionar tipo de partido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Lista de tipos
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tiposPartido.length,
                      itemBuilder: (context, index) {
                        final tipo = _tiposPartido[index];
                        final isSelected = _tipoSeleccionado == tipo['nombre'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tipo['color'].withAlpha(25)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? tipo['color']
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: tipo['color'].withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tipo['icono'],
                                color: tipo['color'],
                                size: 25,
                              ),
                            ),
                            title: Text(
                              tipo['nombre'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? tipo['color']
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                              ),
                            ),
                            subtitle: Text(
                              '${tipo['jugadores']} • Máx: ${tipo['maxIntegrantes']} jugadores',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: tipo['color'],
                                    size: 25,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _tipoSeleccionado = tipo['nombre'];
                                // Actualizar precio si hay una pista seleccionada
                                _actualizarPrecioPorPersona();
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Muestra el selector de pistas
  void _mostrarSelectorPista() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    'Seleccionar pista',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Lista de pistas
                  Expanded(
                    child: _cargandoPistas
                        ? const Center(child: CircularProgressIndicator())
                        : _pistas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sports_soccer,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay pistas disponibles',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _pistas.length,
                                itemBuilder: (context, index) {
                                  final pista = _pistas[index];
                                  final isSelected = _pistaSeleccionada?.id == pista.id;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withAlpha(25)
                                          : Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(13),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withAlpha(51),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: pista.imagenUrl != null && pista.imagenUrl!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.asset(
                                                  pista.imagenUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.place,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      size: 25,
                                                    );
                                                  },
                                                ),
                                              )
                                            : Icon(
                                                Icons.place,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 25,
                                              ),
                                      ),
                                      title: Text(
                                        pista.nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pista.direccion,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (pista.tipo != null) ...[
                                                Text(
                                                  'Tipo: ${pista.tipo}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                              if (pista.precio != null)
                                                Text(
                                                  '€${pista.precio!.toStringAsFixed(0)}/h',
                                                  style: TextStyle(
                                                    color: Colors.green[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _pistaSeleccionada = pista;
                                          
                                          // Actualizar automáticamente el precio por persona basado en el precio de la pista
                                          if (pista.precio != null) {
                                            // Obtener el número máximo de jugadores según el tipo de partido
                                            final maxJugadores = _tipoPartidoSeleccionado['maxIntegrantes'];
                                            
                                            // Calcular precio por persona (precio de la pista dividido entre el número de jugadores)
                                            // Si hay un valor en el campo de integrantes, usarlo; si no, usar el máximo
                                            final numJugadores = int.tryParse(_integrantesController.text) ?? maxJugadores;
                                            final precioPorPersona = (pista.precio! / numJugadores).toStringAsFixed(2);
                                            
                                            // Actualizar el campo de precio
                                            _precioController.text = precioPorPersona;
                                          }
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Método para mostrar el selector de fecha mejorado
  Future<void> _seleccionarFecha() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _fechaSeleccionada = pickedDate;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  /// Método para mostrar el selector de hora mejorado
  Future<void> _seleccionarHora() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _horaSeleccionada = pickedTime;
        _horaController.text = pickedTime.format(context);
      });
    }
  }

  /// Método para guardar el partido
  Future<void> _guardarPartido() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Mostrar progreso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Creando partido...'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Crear la fecha y hora combinadas
        final DateTime fechaHora = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
          _horaSeleccionada!.hour,
          _horaSeleccionada!.minute,
        );

        final int integrantes = int.tryParse(_integrantesController.text) ?? 0;
        final double precio = double.tryParse(_precioController.text) ?? 5.0;

        // Crear el modelo de partido usando el nombre de la pista seleccionada
        final nuevoPartido = PartidoModel(
          id: 'partido_${DateTime.now().millisecondsSinceEpoch}',
          fecha: fechaHora,
          tipo: _tipoSeleccionado,
          lugar: _pistaSeleccionada!.nombre, // Usar el nombre de la pista
          completo: false,
          jugadoresFaltantes: integrantes - 1,
          precio: precio,
          duracion: 90,
          jugadores: [
            UserModel(
              id: widget.userId,
              email: 'usuario@example.com',
              nombre: 'Usuario Actual',
              esAdmin: false
            ),
          ],
        );

        final resultado = await _partidoController.crearPartido(nuevoPartido);

        if (resultado && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('¡Partido creado correctamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          throw Exception('No se pudo crear el partido');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildFormContent(),
    );
  }

  /// Construye el AppBar mejorado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Nuevo Partido',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
    );
  }

  /// Construye el estado de carga
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: 20),
          Text(
            'Creando partido...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido del formulario
  Widget _buildFormContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildTipoField(),
                  const SizedBox(height: 25),
                  _buildPrecioField(),
                  const SizedBox(height: 25),
                  _buildNombreField(),
                  const SizedBox(height: 25),
                  _buildIntegrantesField(),
                  const SizedBox(height: 25),
                  _buildFechaHoraFields(),
                  const SizedBox(height: 25),
                  _buildPistaField(),
                  const SizedBox(height: 40),
                  _buildGuardarButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el campo de tipo
  Widget _buildTipoField() {
    final tipoSeleccionado = _tipoPartidoSeleccionado;

    return _buildFieldContainer(
      label: 'Tipo de partido',
      icon: Icons.sports_soccer,
      child: GestureDetector(
        onTap: _mostrarSelectorTipo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tipoSeleccionado['color'].withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  tipoSeleccionado['icono'],
                  color: tipoSeleccionado['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipoSeleccionado['nombre'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      tipoSeleccionado['jugadores'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el campo de precio
  Widget _buildPrecioField() {
    return _buildFieldContainer(
      label: 'Precio por persona',
      icon: Icons.euro,
      child: _buildTextField(
        controller: _precioController,
        hintText: 'Ej: 5.00',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa el precio';
          }
          final precio = double.tryParse(value);
          if (precio == null || precio < 0) {
            return 'El precio debe ser un número positivo';
          }
          return null;
        },
      ),
    );
  }

  /// Construye el campo de nombre
  Widget _buildNombreField() {
    return _buildFieldContainer(
      label: 'Nombre del partido',
      icon: Icons.title,
      child: _buildTextField(
        controller: _nombreController,
        hintText: 'Ej: Partido de los viernes',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa un nombre';
          }
          if (value.length < 3) {
            return 'El nombre debe tener al menos 3 caracteres';
          }
          return null;
        },
      ),
    );
  }

  /// Construye el campo de integrantes
  Widget _buildIntegrantesField() {
    final maxIntegrantes = _tipoPartidoSeleccionado['maxIntegrantes'];

    return _buildFieldContainer(
      label: 'Número de jugadores',
      icon: Icons.group,
      child: _buildTextField(
        controller: _integrantesController,
        hintText: 'Máximo: $maxIntegrantes jugadores',
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa el número de jugadores';
          }
          final integrantes = int.tryParse(value);
          if (integrantes == null || integrantes < 2) {
            return 'Debe haber al menos 2 jugadores';
          }
          if (integrantes > maxIntegrantes) {
            return 'Máximo para $_tipoSeleccionado: $maxIntegrantes';
          }
          return null;
        },
        onChanged: (value) {
          // Actualizar precio si hay una pista seleccionada
          _actualizarPrecioPorPersona();
        },
      ),
    );
  }

  /// Construye los campos de fecha y hora
  Widget _buildFechaHoraFields() {
    return Row(
      children: [
        Expanded(
          child: _buildFieldContainer(
            label: 'Fecha',
            icon: Icons.calendar_today,
            child: _buildTextField(
              controller: _fechaController,
              hintText: 'Seleccionar fecha',
              readOnly: true,
              onTap: _seleccionarFecha,
              suffixIcon: const Icon(Icons.calendar_today),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona una fecha';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildFieldContainer(
            label: 'Hora',
            icon: Icons.access_time,
            child: _buildTextField(
              controller: _horaController,
              hintText: 'Seleccionar hora',
              readOnly: true,
              onTap: _seleccionarHora,
              suffixIcon: const Icon(Icons.access_time),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona una hora';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el campo de selección de pista
  Widget _buildPistaField() {
    return _buildFieldContainer(
      label: 'Pista',
      icon: Icons.place,
      child: GestureDetector(
        onTap: _cargandoPistas ? null : _mostrarSelectorPista,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: _cargandoPistas
              ? Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      'Cargando pistas...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              : _pistaSeleccionada == null
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.place,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Seleccionar pista',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _pistaSeleccionada!.imagenUrl != null && _pistaSeleccionada!.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    _pistaSeleccionada!.imagenUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.place,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.place,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pistaSeleccionada!.nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                _pistaSeleccionada!.direccion,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  /// Construye un contenedor de campo con etiqueta e icono
  Widget _buildFieldContainer({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  /// Construye el botón de guardar mejorado
  Widget _buildGuardarButton() {
    // Validar que se haya seleccionado una pista
    final bool puedeGuardar = _pistaSeleccionada != null && !_isLoading;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: puedeGuardar
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(204),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: puedeGuardar ? null : Colors.grey,
        borderRadius: BorderRadius.circular(30),
        boxShadow: puedeGuardar
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(102),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: puedeGuardar ? _guardarPartido : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (!_isLoading) ...[
              const Icon(Icons.save, color: Colors.white, size: 24),
              const SizedBox(width: 8),
            ],
            Text(
              _isLoading
                  ? 'Creando partido...'
                  : _pistaSeleccionada == null
                      ? 'SELECCIONA UNA PISTA'
                      : 'CREAR PARTIDO',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un campo de texto mejorado
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 12),
      ),
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
