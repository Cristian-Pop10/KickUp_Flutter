import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Variables para almacenar los valores seleccionados
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _integrantesController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _ubicacionController.dispose();
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

        // Determinar el tipo de partido basado en el número de integrantes
        final int integrantes = int.tryParse(_integrantesController.text) ?? 0;
        String tipo = 'Fútbol Sala';
        if (integrantes > 10) {
          tipo = 'Fútbol 11';
        } else if (integrantes > 5) {
          tipo = 'Fútbol 7';
        }

        // Crear el modelo de partido
        final nuevoPartido = PartidoModel(
          id: 'partido_${DateTime.now().millisecondsSinceEpoch}',
          fecha: fechaHora,
          tipo: tipo,
          lugar: _ubicacionController.text,
          completo: false,
          jugadoresFaltantes: integrantes - 1, // Restar el creador
          precio: 5.0, // Valor por defecto
          duracion: 90, // Duración por defecto en minutos
          descripcion: 'Partido organizado por ${_nombreController.text}',
          jugadores: [
            UserModel(
              id: widget.userId,
              email: 'usuario@example.com', // Valor por defecto
              nombre: 'Usuario Actual', // Valor por defecto
            ),
          ],
        );

        // Guardar el partido
        final resultado = await _partidoController.crearPartido(nuevoPartido);

        if (resultado && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partido creado correctamente')),
          );
          Navigator.pop(context,
              true); // Volver a la pantalla anterior con resultado positivo
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
      backgroundColor: const Color(0xFFE5EFE6), // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crear Partido',
          style: TextStyle(
            color: Colors.black,
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
                      const Center(
                        child: Text(
                          'Nuevo partido',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Campo Nombre
                      const Text(
                        'Nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                      const Text(
                        'Integrantes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                          if (integrantes == null || integrantes < 2) {
                            return 'Debe haber al menos 2 integrantes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo Fecha
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                      const Text(
                        'Hora',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                      const Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                            backgroundColor: const Color(0xFF5A9A7A),
                            foregroundColor: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8DDBD), // Color beige claro para los campos
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15 ),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        validator: validator,
      ),
    );
  }
}
