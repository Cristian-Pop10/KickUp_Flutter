import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/crear_equipo_view.dart';
import 'package:kickup/src/vista/pista_view.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'detalle_equipo_view.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/auth_controller.dart';
import '../componentes/equipo_card.dart'; // Importamos el nuevo componente
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/** Vista principal para la gestión de equipos deportivos.
 * Permite visualizar, buscar, crear y administrar equipos.
 * Incluye funcionalidades diferenciadas para usuarios normales y administradores,
 * así como un sistema de tutorial interactivo para nuevos usuarios.
 */
class EquiposView extends StatefulWidget {
  /** Indica si se debe mostrar el tutorial al cargar la vista */
  final bool showTutorial;
  
  const EquiposView({Key? key, this.showTutorial = false}) : super(key: key);

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

  // Claves globales para el tutorial
  final GlobalKey _navBarKey = GlobalKey();
  final GlobalKey _addTeamKey = GlobalKey();
  final GlobalKey _primerEquipoKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    // Configurar listener para filtrado en tiempo real
    _searchController.addListener(_filtrarEquipos);
    userId = FirebaseAuth.instance.currentUser?.uid;
    _verificarPermisos();

    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /** Verifica si el usuario actual es administrador */
  Future<void> _verificarPermisos() async {
    if (userId != null) {
      final esAdmin = await _equipoController.esUsuarioAdmin(userId!);
      setState(() {
        _esAdmin = esAdmin;
      });
    }
    _cargarEquipos();
  }

  /** Carga todos los equipos desde el controlador con manejo de errores */
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

  /** Filtra equipos basado en el texto de búsqueda en tiempo real */
  void _filtrarEquipos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _equiposFiltrados = _equipos
          .where((equipo) => equipo.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  /** Navega al detalle del equipo y recarga la lista al volver */
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

  /** Navega a crear equipo y recarga si se creó exitosamente */
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

  /** Activa/desactiva modo selección múltiple (solo administradores) */
  void _toggleModoSeleccion() {
    if (!_esAdmin) return;

    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _equiposSeleccionados.clear();
      }
    });
  }

  /** Selecciona/deselecciona un equipo en modo selección (solo administradores) */
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

  /** Elimina los equipos seleccionados después de confirmación (solo administradores) */
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

  /** Muestra diálogo de confirmación para acciones destructivas */
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

  /** Muestra el tutorial interactivo para nuevos usuarios */
  void _showTutorial() {
    targets = [
      TargetFocus(
        identify: "primer_equipo",
        keyTarget: _primerEquipoKey,
        contents: [
          TargetContent(
            child: const Text(
              "Aquí puedes ver los equipos.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "add_team",
        keyTarget: _addTeamKey,
        contents: [
          TargetContent(
            child: const Text(
              "Añade un equipo aquí.",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "Saltar",
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {
        if (_equiposFiltrados.isNotEmpty && userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetalleEquipoView(
                equipoId: _equiposFiltrados.first.id,
                userId: userId!,
                showTutorial: true, // <-- Añade esto
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PistasView(showTutorial: true),
            ),
          );
        }
        return false;
      },
      onSkip: () {
        if (_equiposFiltrados.isNotEmpty && userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetalleEquipoView(
                equipoId: _equiposFiltrados.first.id,
                userId: userId!,
                showTutorial: true, 
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PistasView(showTutorial: true),
            ),
          );
        }
        return false;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return PopScope(
      canPop: !_modoSeleccion, // No permitir cerrar si está en modo selección
      onPopInvokedWithResult: (didPop, result) {
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
          key: _navBarKey,
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/partidos');
            } else if (index == 2) {
              Navigator.of(context).pushReplacementNamed('/pistas');
            }
          },
          isAdmin: _esAdmin,
        ),
        floatingActionButton: FloatingActionButton(
          key: _addTeamKey,
          onPressed: _navegarACrearEquipo,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /** Construye el header con título y controles según el tipo de usuario */
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Equipos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (_esAdmin)
                    Text(
                      _modoSeleccion ? 'Modo Eliminación' : 'Administrador',
                      style: TextStyle(
                        fontSize: 14,
                        color: _modoSeleccion
                            ? Colors.red[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // SOLO mostrar el botón de logout si es admin
          if (_esAdmin)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          // Mostrar avatar para usuarios normales, no para admin
          if (!_esAdmin)
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

  /** Construye la barra de búsqueda con estilo personalizado */
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

  /** Construye los botones de acción diferenciados por tipo de usuario */
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
                  onPressed: _modoSeleccion ? null : _navegarACrearEquipo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _modoSeleccion ? Colors.grey : Colors.green,
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
      return const SizedBox.shrink();
    }
  }

  /** Construye la lista de equipos en formato grid con diferentes estados */
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
                  onRefresh: _cargarEquipos,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _equiposFiltrados.length,
                    itemBuilder: (context, index) {
                      final equipo = _equiposFiltrados[index];
                      final isSelected =
                          _equiposSeleccionados.contains(equipo.id);

                      return EquipoCard(
                        key: index == 0 ? _primerEquipoKey : null,
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