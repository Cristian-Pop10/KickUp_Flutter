import 'package:flutter/material.dart';
import 'package:flutter_application/src/controlador/auth_controller.dart';
import 'package:flutter_application/src/controlador/perfil_controller.dart';
import 'package:flutter_application/src/modelo/user_model.dart';

class PerfilView extends StatefulWidget {
  final String userId;

  const PerfilView({Key? key, required this.userId}) : super(key: key);

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final PerfilController _perfilController = PerfilController();
  final AuthController _authController = AuthController();
  UserModel? _usuario;
  bool _isLoading = true;
  bool _isEditing = false;

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

  // Color para los campos de formulario en modo edición
  final Color _formFieldColor = Colors.white; // Color blanco para todos los campos en modo edición

  @override
  void initState() {
    super.initState();
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
        if (_posicionSeleccionada != null && !_posiciones.contains(_posicionSeleccionada)) {
          _posicionSeleccionada = null; // Si no está en la lista, establecer como nulo
        }
        
        _telefonoController.text = usuario.telefono ?? '';
        _emailController.text = usuario.email ?? '';
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (_usuario == null) return;

    final usuarioActualizado = _usuario!.copyWith(
      nombre: _nombreController.text,
      apellidos: _apellidosController.text,
      edad: int.tryParse(_edadController.text),
      nivel: int.tryParse(_nivelController.text),
      posicion: _posicionSeleccionada,
      telefono: _telefonoController.text,
      email: _emailController.text,
    );

    final success = await _perfilController.actualizarPerfil(usuarioActualizado);

    if (mounted) {
      if (success) {
        setState(() {
          _usuario = usuarioActualizado;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil')),
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
          'Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
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
                      color: const Color(0xFFE5EFE6), // Mismo color que el fondo
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
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: AssetImage(
                                    _usuario!.profileImageUrl ??
                                        'assets/profile.jpg'),
                              ),
                              const SizedBox(height: 16),
                              _isEditing
                                  ? Column(
                                      children: [
                                        TextField(
                                          controller: _nombreController,
                                          decoration: InputDecoration(
                                            labelText: 'Nombre',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: _formFieldColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _apellidosController,
                                          decoration: InputDecoration(
                                            labelText: 'Apellidos',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: _formFieldColor,
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
                                      _posicionSeleccionada = _usuario!.posicion?.toLowerCase();
                                      _telefonoController.text =
                                          _usuario!.telefono ?? '';
                                      _emailController.text =
                                          _usuario!.email ?? '';
                                    }
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF5A9A7A),
                                ),
                                child: Text(
                                  _isEditing ? 'Cancelar' : 'Editar Perfil',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                'Nivel',
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
                                _usuario!.email ?? '',
                                _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 32),
                              // Botón Guardar cambios (solo visible en modo edición)
                              if (_isEditing)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _guardarCambios,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A9A7A),
                                      foregroundColor: Colors.white,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
                  fillColor: _formFieldColor, // Color blanco para campos en modo edición
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
                  color: const Color(0xFFE8DFC9),
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

  // Método para construir el campo de posición con dropdown
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
                  color: _formFieldColor, // Color blanco para campos en modo edición
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400), // Añadir borde para consistencia
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
                    fillColor: _formFieldColor,
                  ),
                  items: _posiciones.map((String posicion) {
                    return DropdownMenuItem<String>(
                      value: posicion,
                      child: Text(
                        posicion[0].toUpperCase() + posicion.substring(1), // Capitalizar primera letra
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _posicionSeleccionada = newValue;
                    });
                  },
                  dropdownColor: _formFieldColor, // Color del menú desplegable
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DFC9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _usuario!.posicion != null && _usuario!.posicion!.isNotEmpty
                      ? _usuario!.posicion![0].toUpperCase() + _usuario!.posicion!.substring(1) // Capitalizar primera letra
                      : '',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
      ],
    );
  }
}