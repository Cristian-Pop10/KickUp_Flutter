import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _nivelController = TextEditingController();

  // Variables para almacenar los valores seleccionados
  File? _logoImage;
  bool _isLoading = false;
  String _tipoSeleccionado = 'Fútbol 7';
  final List<String> _tiposEquipo = [
    'Fútbol 5',
    'Fútbol 7',
    'Fútbol 11',
    'Fútbol Sala'
  ];

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

  Future<String?> subirLogoEquipo(File logo, String equipoId) async {
    final storageRef =
        FirebaseStorage.instance.ref().child('equipos').child('$equipoId.jpg');
    final uploadTask = await storageRef.putFile(logo);
    return await uploadTask.ref.getDownloadURL();
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
  // ...existing code...
  Future<void> _guardarEquipo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Genera el ID del equipo
        final equipoId = 'equipo_${DateTime.now().millisecondsSinceEpoch}';

        // 2. Sube el logo si existe
        String logoUrl = '';
        if (_logoImage != null) {
          logoUrl = await subirLogoEquipo(_logoImage!, equipoId) ?? '';
        }

        // 3. Obtén los datos del usuario creador
        final usuarioDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.userId)
            .get();
        final userData = usuarioDoc.data();

        // 4. Crea el modelo/mapa de equipo con jugadores y jugadoresIds
        final equipoMap = {
          'id': equipoId,
          'nombre': _nombreController.text,
          'tipo': _tipoSeleccionado,
          'logoUrl': logoUrl,
          'descripcion': _descripcionController.text,
          'nivel': int.tryParse(_nivelController.text) ?? 1,
          'jugadoresIds': [widget.userId],
          'jugadores': [
            {
              'id': widget.userId,
              'nombre': userData?['nombre'] ?? '',
              'apellidos': userData?['apellidos'] ?? '',
              'posicion': userData?['posicion'] ?? '',
              'profileImageUrl': userData?['profileImageUrl'] ?? '',
            }
          ],
        };

        // 5. Guarda el equipo en Firestore
        await FirebaseFirestore.instance
            .collection('equipos')
            .doc(equipoId)
            .set(equipoMap);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipo creado correctamente')),
          );
          Navigator.pop(context, true);
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
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nuevo Equipo',
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

                      // Logo del equipo
                      Center(
                        child: GestureDetector(
                          onTap: _seleccionarImagen,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary, // Fondo claro
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2),
                            ),
                            child: _logoImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.file(
                                      _logoImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Theme.of(context)
                                        .primaryColor, // Icono de añadir foto
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Añadir logo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Campo Nombre
                      Text(
                        'Nombre del equipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      Text(
                        'Tipo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      Text(
                        'Nivel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descripcionController,
                        hintText: 'Describe tu equipo',
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor escribe una descripción';
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
                          onPressed: _guardarEquipo,
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).inputDecorationTheme.hintStyle?.color ??
              Colors.grey, // Color del hint
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: suffixIcon,
      ),
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      validator: validator,
    );
  }
// This method builds a text field with the provided parameters.
}
