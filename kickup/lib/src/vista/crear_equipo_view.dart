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

class _CrearEquipoViewState extends State<CrearEquipoView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _nivelController = TextEditingController();

  // Variables para almacenar los valores seleccionados
  File? _logoImage;
  bool _isLoading = false;
  bool _subiendoImagen = false;
  String _tipoSeleccionado = 'Fútbol 7';

  // Opciones de tipos de equipo con iconos y colores
  final List<Map<String, dynamic>> _tiposEquipo = [

    {
      'nombre': 'Fútbol 7',
      'icono': Icons.sports_soccer,
      'jugadores': '7 vs 7',
      'color': Colors.green,
    },
    {
      'nombre': 'Fútbol 11',
      'icono': Icons.sports_soccer,
      'jugadores': '11 vs 11',
      'color': Colors.orange,
    },
    {
      'nombre': 'Fútbol Sala',
      'icono': Icons.sports_soccer,
      'jugadores': '5 vs 5',
      'color': Colors.purple,
    },
  ];

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tipoController.text = _tipoSeleccionado;

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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _descripcionController.dispose();
    _nivelController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Muestra opciones para seleccionar imagen con diseño mejorado
  Future<void> _mostrarOpcionesImagen() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Seleccionar logo del equipo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Opciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageOption(
                        icon: Icons.photo_library,
                        label: 'Galería',
                        color: Colors.blue,
                        onTap: () =>
                            Navigator.of(context).pop(ImageSource.gallery),
                      ),
                      _buildImageOption(
                        icon: Icons.photo_camera,
                        label: 'Cámara',
                        color: Colors.green,
                        onTap: () =>
                            Navigator.of(context).pop(ImageSource.camera),
                      ),
                      if (_logoImage != null)
                        _buildImageOption(
                          icon: Icons.delete,
                          label: 'Eliminar',
                          color: Colors.red,
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() => _logoImage = null);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _seleccionarImagen(source);
    }
  }

  /// Widget para opciones de imagen
  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona una imagen desde la fuente especificada
  Future<void> _seleccionarImagen(ImageSource source) async {
    setState(() => _subiendoImagen = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _logoImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _subiendoImagen = false);
      }
    }
  }

  Future<String?> subirLogoEquipo(File logo, String equipoId) async {
    final storageRef =
        FirebaseStorage.instance.ref().child('equipos').child('$equipoId.jpg');
    final uploadTask = await storageRef.putFile(logo);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Muestra el selector de tipo de equipo mejorado
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
                    'Seleccionar tipo de equipo',
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
                      itemCount: _tiposEquipo.length,
                      itemBuilder: (context, index) {
                        final tipo = _tiposEquipo[index];
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
                              tipo['jugadores'],
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
                                _tipoController.text = tipo['nombre'];
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

  /// Guarda el equipo
  Future<void> _guardarEquipo() async {
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
                Text('Creando equipo...'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('¡Equipo creado correctamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
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
        'Nuevo Equipo',
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
            'Creando equipo...',
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
                  const SizedBox(height: 20),
                  _buildLogoSection(),
                  const SizedBox(height: 40),
                  _buildNombreField(),
                  const SizedBox(height: 25),
                  _buildTipoField(),
                  const SizedBox(height: 25),
                  _buildNivelField(),
                  const SizedBox(height: 25),
                  _buildDescripcionField(),
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

  /// Construye la sección del logo mejorada
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _mostrarOpcionesImagen,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: _logoImage != null
                    ? null
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withAlpha(76),
                          Theme.of(context).colorScheme.primary.withAlpha(25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _subiendoImagen
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : _logoImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: Image.file(
                            _logoImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _logoImage != null
                ? 'Toca para cambiar logo'
                : 'Añadir logo del equipo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el campo de nombre mejorado
  Widget _buildNombreField() {
    return _buildFieldContainer(
      label: 'Nombre del equipo',
      icon: Icons.sports_soccer,
      child: _buildTextField(
        controller: _nombreController,
        hintText: 'Ej: FC Barcelona',
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

  /// Construye el campo de tipo mejorado
  Widget _buildTipoField() {
    return _buildFieldContainer(
      label: 'Tipo de equipo',
      icon: Icons.group,
      child: _buildTextField(
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
    );
  }

  /// Construye el campo de nivel mejorado
  Widget _buildNivelField() {
    return _buildFieldContainer(
      label: 'Nivel del equipo',
      icon: Icons.star,
      child: _buildTextField(
        controller: _nivelController,
        hintText: 'Nivel del 1 al 5',
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
    );
  }

  /// Construye el campo de descripción mejorado
  Widget _buildDescripcionField() {
    return _buildFieldContainer(
      label: 'Descripción',
      icon: Icons.description,
      child: _buildTextField(
        controller: _descripcionController,
        hintText: 'Describe tu equipo, objetivos, horarios...',
        keyboardType: TextInputType.multiline,
        maxLines: 4,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor escribe una descripción';
          }
          if (value.length < 10) {
            return 'La descripción debe tener al menos 10 caracteres';
          }
          return null;
        },
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
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(102),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _guardarEquipo,
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
              _isLoading ? 'Creando equipo...' : 'CREAR EQUIPO',
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
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
    );
  }
}
