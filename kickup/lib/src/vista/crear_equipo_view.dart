import 'package:flutter/material.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CrearEquipoView extends StatefulWidget {
  final String userId;

  const CrearEquipoView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CrearEquipoView> createState() => _CrearEquipoViewState();
}

class _CrearEquipoViewState extends State<CrearEquipoView> {
  final _formKey = GlobalKey<FormState>();
  final EquipoController _equipoController = EquipoController();
  
  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _nivelController = TextEditingController();
  
  // Variables para almacenar los valores seleccionados
  File? _logoImage;
  bool _isLoading = false;
  String _tipoSeleccionado = 'Fútbol 7';
  final List<String> _tiposEquipo = ['Fútbol 5', 'Fútbol 7', 'Fútbol 11', 'Fútbol Sala'];

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _descripcionController.dispose();
    _nivelController.dispose();
    super.dispose();
  }

  // Método para seleccionar una imagen de la galería
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
    }
  }

  // Método para mostrar el selector de tipo de equipo
  void _mostrarSelectorTipo() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: ListView.builder(
            itemCount: _tiposEquipo.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_tiposEquipo[index]),
                onTap: () {
                  setState(() {
                    _tipoSeleccionado = _tiposEquipo[index];
                    _tipoController.text = _tiposEquipo[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  // Método para guardar el equipo
  Future<void> _guardarEquipo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear el modelo de equipo
        final nuevoEquipo = EquipoModel(
          id: 'equipo_${DateTime.now().millisecondsSinceEpoch}',
          nombre: _nombreController.text,
          tipo: _tipoSeleccionado,
          logoUrl: '', // URL de la imagen (se puede subir después)
          descripcion: _descripcionController.text,
          jugadoresIds: [widget.userId], // El creador es el primer miembro
          nivel: int.tryParse(_nivelController.text) ?? 1,
        );

        // Guardar el equipo
        final resultado = await _equipoController.crearEquipo(nuevoEquipo , widget.userId);

        if (resultado && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipo creado correctamente')),
          );
          Navigator.pop(context, true); // Volver a la pantalla anterior con resultado positivo
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear el equipo')),
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
          'Crear Equipo',
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
                          'Nuevo equipo',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Logo del equipo
                      Center(
                        child: GestureDetector(
                          onTap: _seleccionarImagen,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8DDBD),
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _logoImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.file(
                                      _logoImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Center(
                        child: Text(
                          'Añadir logo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Campo Nombre
                      const Text(
                        'Nombre del equipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nombreController,
                        hintText: 'Nombre del equipo',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo Tipo
                      const Text(
                        'Tipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _tipoController,
                        hintText: 'Selecciona el tipo de equipo',
                        readOnly: true,
                        onTap: _mostrarSelectorTipo,
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona un tipo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo Nivel
                      const Text(
                        'Nivel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nivelController,
                        hintText: 'Nivel del equipo (1-5)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nivel';
                          }
                          final nivel = int.tryParse(value);
                          if (nivel == null || nivel < 1 || nivel > 5) {
                            return 'El nivel debe ser un número entre 1 y 5';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8DDBD), // Color beige claro para los campos
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextFormField(
                          controller: _descripcionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Describe tu equipo',
                            hintStyle: TextStyle(color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _guardarEquipo,
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
