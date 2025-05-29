import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/auth_controller.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kickup/src/controlador/perfil_controller.dart';
import 'package:kickup/src/modelo/user_model.dart';
import 'package:kickup/src/vista/configuracion_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({
    Key? key,
  }) : super(key: key);

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final PerfilController _perfilController = PerfilController();
  final AuthController _authController = AuthController();
  UserModel? _usuario;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;

  // Lista de posiciones disponibles
  final List<String> _posiciones = [
    'portero',
    'defensa',
    'centrocampista',
    'delantero',
  ];

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _nivelController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Variable para almacenar la posición seleccionada
  String? _posicionSeleccionada;

  late final String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _cargarUsuario();
  }

  @override
  void dispose() {
    // Guardar cambios automáticamente al salir de la pantalla
    if (_isEditing) {
      _guardarCambios();
    }

    // Liberar los controladores de texto
    _nombreController.dispose();
    _apellidosController.dispose();
    _edadController.dispose();
    _nivelController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    setState(() {
      _isLoading = true;
    });

    final usuario = await _perfilController.obtenerUsuarioActual();

    setState(() {
      _usuario = usuario;
      _isLoading = false;

      // Inicializar controladores con los datos del usuario
      if (usuario != null) {
        _nombreController.text = usuario.nombre ?? '';
        _apellidosController.text = usuario.apellidos ?? '';
        _edadController.text = usuario.edad?.toString() ?? '';
        _nivelController.text = usuario.nivel?.toString() ?? '';

        // Asegurarse de que la posición esté en minúsculas para coincidir con la lista
        _posicionSeleccionada = usuario.posicion?.toLowerCase();

        // Verificar que la posición seleccionada esté en la lista
        if (_posicionSeleccionada != null &&
            !_posiciones.contains(_posicionSeleccionada)) {
          _posicionSeleccionada =
              null; // Si no está en la lista, establecer como nulo
        }

        _telefonoController.text = usuario.telefono ?? '';
        _emailController.text = usuario.email;
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (_usuario == null) return;

    // Validar campos obligatorios
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email es obligatorio')),
      );
      return;
    }

    // Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de email inválido')),
      );
      return;
    }

    final usuarioActualizado = _usuario!.copyWith(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      edad: int.tryParse(_edadController.text),
      nivel: int.tryParse(_nivelController.text),
      posicion: _posicionSeleccionada,
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
    );

    final success =
        await _perfilController.actualizarPerfil(usuarioActualizado);

    if (mounted) {
      if (success) {
        setState(() {
          _usuario = usuarioActualizado;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Usar el AuthController para cerrar sesión
      await _authController.logout(context);
    }
  }

  void _mostrarOpcionesImagen() async {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya hay una subida en progreso')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cambiar foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF5A9A7A)),
                title: const Text('Elegir de la galería'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagen =
                      await _perfilController.seleccionarImagenGaleria();
                  if (imagen != null) {
                    await _subirYActualizarFoto(imagen);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5A9A7A)),
                title: const Text('Hacer una foto'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagen = await _perfilController.tomarFoto();
                  if (imagen != null) {
                    await _subirYActualizarFoto(imagen);
                  }
                },
              ),
              if (_usuario?.profileImageUrl != null &&
                  _usuario!.profileImageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto actual'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _eliminarFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subirYActualizarFoto(File imagen) async {
    if (_usuario == null || _isUploadingImage) return;

    setState(() => _isUploadingImage = true);

    try {
      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Subiendo imagen...'),
              const SizedBox(height: 8),
              Text(
                'Por favor, mantén la aplicación abierta',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );

      final exito =
          await _perfilController.actualizarFotoPerfil(imagen, _usuario!.id!);

      // Cerrar diálogo de progreso
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (exito) {
        await _cargarUsuario();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo actualizar la foto. Inténtalo de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al subir imagen: $e');

      // Cerrar diálogo de progreso si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _eliminarFoto() async {
    if (_usuario?.id == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final success = await _perfilController.eliminarFotoPerfil(_usuario!.id!);

      if (success) {
        await _cargarUsuario();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil eliminada')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error al eliminar la foto de perfil')),
          );
        }
      }
    } catch (e) {
      print('Error al eliminar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Perfil',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usuario == null
              ? const Center(child: Text('Usuario no encontrado'))
              : SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto de perfil y nombre
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _isUploadingImage
                                    ? null
                                    : _mostrarOpcionesImagen,
                                child: Stack(
                                  children: [
                                    _isUploadingImage
                                        ? const CircleAvatar(
                                            radius: 60,
                                            backgroundColor: Colors.grey,
                                            child: CircularProgressIndicator(),
                                          )
                                        : CircleAvatar(
                                            radius: 60,
                                            backgroundColor: Colors.grey,
                                            backgroundImage: (_usuario!
                                                            .profileImageUrl !=
                                                        null &&
                                                    _usuario!.profileImageUrl!
                                                        .isNotEmpty)
                                                ? CachedNetworkImageProvider(
                                                    _usuario!.profileImageUrl!)
                                                : null, // Sin imagen si no hay URL
                                            child: (_usuario!.profileImageUrl ==
                                                        null ||
                                                    _usuario!.profileImageUrl!
                                                        .isEmpty)
                                                ? const Icon(Icons.person,
                                                    size: 60,
                                                    color: Colors.white)
                                                : null,
                                          ),
                                    if (!_isUploadingImage)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5A9A7A),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isUploadingImage) const SizedBox(height: 8),
                              if (!_isUploadingImage)
                                const SizedBox(height: 16),
                              _isEditing
                                  ? Column(
                                      children: [
                                        TextField(
                                          controller: _nombreController,
                                          decoration: InputDecoration(
                                            labelText: 'Nombre *',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor:
                                                AppColors.fieldBackground(
                                                    context),
                                            errorText: _nombreController.text
                                                    .trim()
                                                    .isEmpty
                                                ? 'Campo obligatorio'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _apellidosController,
                                          decoration: InputDecoration(
                                            labelText: 'Apellidos',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor:
                                                AppColors.fieldBackground(
                                                    context),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Text(
                                          _usuario!.nombre ?? '',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _usuario!.apellidos ?? '',
                                          style: const TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 16),
                              // Botón Editar Perfil
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = !_isEditing;
                                        if (!_isEditing) {
                                          // Si estábamos editando y cancelamos, restauramos los valores originales
                                          _nombreController.text =
                                              _usuario!.nombre ?? '';
                                          _apellidosController.text =
                                              _usuario!.apellidos ?? '';
                                          _edadController.text =
                                              _usuario!.edad?.toString() ?? '';
                                          _nivelController.text =
                                              _usuario!.nivel?.toString() ?? '';
                                          _posicionSeleccionada =
                                              _usuario!.posicion?.toLowerCase();
                                          _telefonoController.text =
                                              _usuario!.telefono ?? '';
                                          _emailController.text =
                                              _usuario!.email;
                                        }
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text(
                                      _isEditing ? 'Cancelar' : 'Editar Perfil',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.settings,
                                        color:
                                            Theme.of(context).iconTheme.color),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (_) =>
                                            const ConfiguracionView(),
                                      ));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Campos de información personal
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoField(
                                'Edad',
                                _usuario!.edad?.toString() ?? '',
                                _edadController,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                'Nivel (1-5)',
                                _usuario!.nivel?.toString() ?? '',
                                _nivelController,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              _buildPosicionField(),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                'Teléfono',
                                _usuario!.telefono ?? '',
                                _telefonoController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                'Email',
                                _usuario!.email,
                                _emailController,
                                keyboardType: TextInputType.emailAddress,
                                isRequired: true,
                              ),
                              const SizedBox(height: 32),
                              // Botón Guardar cambios (solo visible en modo edición)
                              if (_isEditing)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _guardarCambios,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      'Guardar Cambios',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground(context),
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPosicionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Posición',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonFormField<String>(
                  value: _posicionSeleccionada,
                  hint: const Text("Selecciona una posición"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.fieldBackground(context),
                  ),
                  items: _posiciones.map((String posicion) {
                    return DropdownMenuItem<String>(
                      value: posicion,
                      child: Text(
                        posicion[0].toUpperCase() + posicion.substring(1),
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _posicionSeleccionada = newValue;
                    });
                  },
                  dropdownColor:
                      Theme.of(context).inputDecorationTheme.fillColor,
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground(context),
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _usuario!.posicion != null && _usuario!.posicion!.isNotEmpty
                      ? _usuario!.posicion![0].toUpperCase() +
                          _usuario!.posicion!.substring(1)
                      : '',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
              ),
      ],
    );
  }
}
