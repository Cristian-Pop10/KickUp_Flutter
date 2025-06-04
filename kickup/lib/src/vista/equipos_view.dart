import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/crear_equipo_view.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'detalle_equipo_view.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquiposView extends StatefulWidget {
  const EquiposView({Key? key}) : super(key: key);

  @override
  State<EquiposView> createState() => _EquiposViewState();
}

class _EquiposViewState extends State<EquiposView> {
  // Controladores para manejar la lógica
  final EquipoController _equipoController = EquipoController();
  final AuthController _authController = AuthController();
  final TextEditingController _searchController = TextEditingController();

  // Listas para manejar equipos originales y filtrados
  List<EquipoModel> _equipos = [];
  List<EquipoModel> _equiposFiltrados = [];
  List<String> _equiposSeleccionados = [];
  bool _isLoading = true;
  bool _esAdmin = false;
  bool _modoSeleccion = false;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    // Configurar listener para filtrado en tiempo real
    _searchController.addListener(_filtrarEquipos);
    userId = FirebaseAuth.instance.currentUser?.uid;
    _verificarPermisos();
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _searchController.dispose();
    super.dispose();
  }


  /// Verifica si el usuario es admin
  Future<void> _verificarPermisos() async {
    if (userId != null) {
      final esAdmin = await _equipoController.esUsuarioAdmin(userId!);
      setState(() {
        _esAdmin = esAdmin;
      });
    }
    _cargarEquipos();
  }

  /// Carga todos los equipos desde el controlador con manejo de errores
  Future<void> _cargarEquipos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final equipos = await _equipoController.obtenerEquipos();

      // Verificar que el widget sigue montado antes de actualizar estado
      if (mounted) {
        setState(() {
          _equipos = equipos;
          _equiposFiltrados = equipos; // Inicialmente mostrar todos
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar equipos: $e')),
        );
      }
    }
  }

  /// Filtra equipos basado en el texto de búsqueda
  void _filtrarEquipos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _equiposFiltrados = _equipos
          .where((equipo) => equipo.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  /// Navega al detalle del equipo y recarga la lista al volver
  void _navegarADetalleEquipo(String equipoId) {
    // Permitir navegación tanto para usuarios normales como para admin
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => DetalleEquipoView(
              equipoId: equipoId,
              userId: userId!,
            ),
          ),
        )
        .then((_) => _cargarEquipos()); // Recargar al volver
  }

  /// Navega a crear equipo y recarga si se creó exitosamente
  Future<void> _navegarACrearEquipo() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrearEquipoView(userId: userId!),
      ),
    );

    if (result == true) {
      _cargarEquipos();
    }
  }

  /// Activa/desactiva modo selección (solo admin)
  void _toggleModoSeleccion() {
    if (!_esAdmin) return;

    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _equiposSeleccionados.clear();
      }
    });
  }

  /// Selecciona/deselecciona un equipo (solo admin)
  void _toggleSeleccionEquipo(String equipoId) {
    if (!_esAdmin || !_modoSeleccion) return;

    setState(() {
      if (_equiposSeleccionados.contains(equipoId)) {
        _equiposSeleccionados.remove(equipoId);
      } else {
        _equiposSeleccionados.add(equipoId);
      }
    });
  }

  /// Elimina los equipos seleccionados (solo admin)
  Future<void> _eliminarEquiposSeleccionados() async {
    if (!_esAdmin || _equiposSeleccionados.isEmpty) return;

    final confirmar = await _mostrarDialogoConfirmacion(
      '¿Eliminar equipos?',
      '¿Estás seguro de que quieres eliminar ${_equiposSeleccionados.length} equipo(s)?',
    );

    if (confirmar) {
      setState(() {
        _isLoading = true;
      });

      final eliminados = await _equipoController.eliminarEquiposMultiples(
        _equiposSeleccionados,
        userId!,
      );

      setState(() {
        _equiposSeleccionados.clear();
        _modoSeleccion = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$eliminados equipo(s) eliminado(s)'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarEquipos();
    }
  }

  /// Muestra diálogo de confirmación
  Future<bool> _mostrarDialogoConfirmacion(
      String titulo, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return PopScope(
      canPop: !_modoSeleccion, // No permitir cerrar si está en modo selección
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop && _modoSeleccion) {
          // Si no se cerró y está en modo selección, salir del modo
          setState(() {
            _modoSeleccion = false;
            _equiposSeleccionados.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Container(
          margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(), // Header con título
              _buildSearchBar(), // Barra de búsqueda
              const SizedBox(height: 16),
              _buildActionButtons(), // Botones de acción (diferentes según rol)
              const SizedBox(height: 16),
              _buildTeamsList(), // Lista/Grid de equipos
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1, // Índice fijo para la pestaña de equipos
          onTap: (index) {
            // Navegación simplificada usando rutas nombradas
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/partidos');
            } else if (index == 2) {
              Navigator.of(context).pushReplacementNamed('/pistas');
            }
          },
        ),
      ),
    );
  }

  /// Construye el header con título
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_esAdmin)
                Text(
                  _modoSeleccion ? 'Modo Eliminación' : 'Administrador',
                  style: TextStyle(
                    fontSize: 14,
                    color: _modoSeleccion ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Mostrar avatar para usuarios normales, no para admin
          if (!_esAdmin)
            // StreamBuilder para avatar en tiempo real
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  imageUrl = data['profileImageUrl'] as String?;
                }

                return GestureDetector(
                  onTap: () => _authController.navigateToPerfil(context),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Construye la barra de búsqueda con estilo personalizado
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            prefixIcon:
                Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  /// Construye los botones de acción (diferentes para usuario y admin)
  Widget _buildActionButtons() {
    if (_esAdmin) {
      // Vista de administrador: botones circulares verde (+) y rojo (-)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Botón añadir (verde)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: _modoSeleccion ? null : _navegarACrearEquipo, // Deshabilitar en modo selección
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _modoSeleccion ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ),
            // Botón eliminar (rojo)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: _modoSeleccion
                      ? _eliminarEquiposSeleccionados
                      : _toggleModoSeleccion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _modoSeleccion ? Colors.red[700] : Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _modoSeleccion ? Icons.delete : Icons.remove,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Vista de usuario: botón rectangular normal
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _navegarACrearEquipo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'AÑADIR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Construye la lista de equipos con diferentes estados
  Widget _buildTeamsList() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equiposFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Estado vacío con icono y mensaje descriptivo
                      Icon(
                        Icons.group,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // Mensaje diferente según si hay búsqueda activa
                        _searchController.text.isEmpty
                            ? 'No hay equipos disponibles'
                            : 'No se encontraron equipos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarEquipos, // Pull-to-refresh
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columnas
                      childAspectRatio: 0.85, // Proporción de aspecto
                      crossAxisSpacing: 16, // Espacio horizontal
                      mainAxisSpacing: 16, // Espacio vertical
                    ),
                    itemCount: _equiposFiltrados.length,
                    itemBuilder: (context, index) {
                      final equipo = _equiposFiltrados[index];
                      final isSelected =
                          _equiposSeleccionados.contains(equipo.id);

                      return _EquipoCard(
                        nombre: equipo.nombre,
                        tipo: equipo.tipo,
                        logoUrl: equipo.logoUrl,
                        esAdmin: _esAdmin,
                        modoSeleccion: _modoSeleccion,
                        seleccionado: isSelected,
                        onTap: () => _modoSeleccion
                            ? _toggleSeleccionEquipo(equipo.id)
                            : _navegarADetalleEquipo(equipo.id),
                        onLongPress:
                            _esAdmin ? () => _toggleModoSeleccion() : null,
                      );
                    },
                  ),
                ),
    );
  }
}

/// Widget personalizado para mostrar cada tarjeta de equipo
class _EquipoCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final String logoUrl;
  final bool esAdmin;
  final bool modoSeleccion;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _EquipoCard({
    Key? key,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    required this.esAdmin,
    required this.modoSeleccion,
    required this.seleccionado,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contenedor principal de la imagen del equipo
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: seleccionado
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            // Fallback en caso de error al cargar imagen
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.sports_soccer,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.sports_soccer,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tipo del equipo
              Text(
                tipo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              // Nombre del equipo con overflow handling
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Truncar texto largo
              ),
            ],
          ),
          // Checkbox para modo selección (solo admin)
          if (esAdmin && modoSeleccion)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: seleccionado,
                  onChanged: (_) => onTap(),
                  activeColor: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
