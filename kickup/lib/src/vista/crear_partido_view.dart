import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../controlador/partido_controller.dart';
import '../modelo/partido_model.dart';
import '../modelo/user_model.dart';

class CrearPartidoView extends StatefulWidget {
  final String userId;

  const CrearPartidoView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CrearPartidoView> createState() => _CrearPartidoViewState();
}

class _CrearPartidoViewState extends State<CrearPartidoView> {
  final _formKey = GlobalKey<FormState>();
  final PartidoController _partidoController = PartidoController();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _integrantesController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _precioController =
      TextEditingController();
  // Variables para almacenar los valores seleccionados
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;

  // Nuevo: lista y valor seleccionado para tipo de partido
  final List<String> _tiposPartido = ['Fútbol Sala', 'Fútbol 7', 'Fútbol 11'];
  String _tipoSeleccionado = 'Fútbol Sala';

  // Nuevo: mapa con el número máximo de integrantes por tipo de partido
  final Map<String, int> maxIntegrantesPorTipo = {
    'Fútbol Sala': 10,
    'Fútbol 7': 14,
    'Fútbol 11': 22,
  };

  @override
  void dispose() {
    _nombreController.dispose();
    _integrantesController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _ubicacionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Método para mostrar el selector de fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A9A7A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

  // Método para mostrar el selector de hora
  Future<void> _seleccionarHora() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A9A7A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

  // Método para guardar el partido
  Future<void> _guardarPartido() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
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

        // Crear el modelo de partido
        final nuevoPartido = PartidoModel(
          id: 'partido_${DateTime.now().millisecondsSinceEpoch}',
          fecha: fechaHora,
          tipo: _tipoSeleccionado,
          lugar: _ubicacionController.text,
          completo: false,
          jugadoresFaltantes: integrantes - 1,
          precio: precio,
          duracion: 90,
          jugadores: [
            UserModel(
              id: widget.userId,
              email: 'usuario@example.com',
              nombre: 'Usuario Actual',
            ),
          ],
        );

        final resultado = await _partidoController.crearPartido(nuevoPartido);

        if (resultado && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partido creado correctamente')),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear el partido')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nuevo Partido',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      const SizedBox(height: 30),

                      // Campo Tipo de Partido
                      Text(
                        'Tipo de Partido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _tipoSeleccionado,
                        items: _tiposPartido
                            .map((tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo,
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 16,
                                      )),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipoSeleccionado = value!;
                          });
                        },
                        decoration: InputDecoration(
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                          filled: true,
                          fillColor: AppColors.fieldBackground(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo Precio
                      Text(
                        'Precio (€)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _precioController,
                        hintText: 'Precio por persona',
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
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
                      const SizedBox(height: 20),

                      // Campo Nombre
                      Text(
                        'Nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nombreController,
                        hintText: 'Nombre del partido',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo Integrantes
                      Text(
                        'Integrantes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _integrantesController,
                        hintText: 'Número de jugadores necesarios',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el número de integrantes';
                          }
                          final integrantes = int.tryParse(value);
                          final maxIntegrantes =
                              maxIntegrantesPorTipo[_tipoSeleccionado] ?? 22;
                          if (integrantes == null || integrantes < 2) {
                            return 'Debe haber al menos 2 integrantes';
                          }
                          if (integrantes > maxIntegrantes) {
                            return 'Máximo para $_tipoSeleccionado: $maxIntegrantes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo Fecha
                      Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _fechaController,
                        hintText: 'Selecciona la fecha',
                        readOnly: true,
                        onTap: _seleccionarFecha,
                        suffixIcon: const Icon(Icons.calendar_today),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una fecha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo Hora
                      Text(
                        'Hora',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _horaController,
                        hintText: 'Selecciona la hora',
                        readOnly: true,
                        onTap: _seleccionarHora,
                        suffixIcon: const Icon(Icons.access_time),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una hora';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo Ubicación
                      Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _ubicacionController,
                        hintText: 'Dirección o nombre del lugar',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa la ubicación';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _guardarPartido,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'GUARDAR',
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
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary(context),
        ),
        filled: true,
        fillColor:
            AppColors.fieldBackground(context), // Color de fondo adaptativo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: suffixIcon,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary(context),
        fontSize: 16,
      ),
      validator: validator,
    );
  }
}
