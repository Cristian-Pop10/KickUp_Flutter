import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../componentes/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/** Vista administrativa para la gestión de jugadores.
 * Permite a los administradores visualizar, buscar y sancionar jugadores
 * mediante un sistema de puntos. Incluye funcionalidades para aplicar
 * sanciones individuales y masivas por tardanzas o ausencias, así como
 * bonificaciones por buen comportamiento.
 */
class JugadoresView extends StatefulWidget {
  const JugadoresView({Key? key}) : super(key: key);

  @override
  State<JugadoresView> createState() => _JugadoresViewState();
}

class _JugadoresViewState extends State<JugadoresView> {
  /** Controlador para el campo de búsqueda de jugadores */
  final TextEditingController _searchController = TextEditingController();

  /** Lista completa de jugadores cargados desde Firestore */
  List<Map<String, dynamic>> _jugadores = [];
  
  /** Lista filtrada de jugadores basada en la búsqueda */
  List<Map<String, dynamic>> _jugadoresFiltrados = [];
  
  /** Lista de IDs de jugadores seleccionados para acciones masivas */
  List<String> _jugadoresSeleccionados = [];
  
  /** Indica si la vista está cargando datos */
  bool _isLoading = true;
  
  /** Indica si está activo el modo de selección múltiple */
  bool _modoSeleccion = false;
  
  /** ID del usuario administrador actual */
  late final String? userId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarJugadores);
    userId = FirebaseAuth.instance.currentUser?.uid;
    _cargarJugadores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /** Carga todos los jugadores desde Firestore ordenados por puntos descendente */
  Future<void> _cargarJugadores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .orderBy('puntos', descending: true)
          .get();

      final jugadores = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre'] ?? '',
          'apellidos': data['apellidos'] ?? '',
          'email': data['email'] ?? '',
          'profileImageUrl': data['profileImageUrl'] as String?,
          'puntos': data['puntos'] ?? 15,
          'posicion': data['posicion'] ?? 'Sin posición',
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _jugadores = jugadores;
          _jugadoresFiltrados = jugadores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar jugadores: $e')),
        );
      }
    }
  }

  /** Filtra la lista de jugadores basándose en el texto de búsqueda */
  void _filtrarJugadores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _jugadoresFiltrados = _jugadores.where((jugador) {
        final nombre =
            '${jugador['nombre']} ${jugador['apellidos']}'.toLowerCase();
        final email = jugador['email'].toString().toLowerCase();
        return nombre.contains(query) || email.contains(query);
      }).toList();
    });
  }

  /** Muestra el diálogo de gestión de puntos para un jugador individual */
  Future<void> _mostrarDialogoSanciones(Map<String, dynamic> jugador) async {
    final puntosActuales = jugador['puntos'] ?? 15;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gestionar puntos de ${jugador['nombre']} ${jugador['apellidos']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puntos actuales: $puntosActuales',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text('Selecciona una acción:', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: puntosActuales >= 15 ? null : () => Navigator.of(context).pop('bonus_1'),
            style: TextButton.styleFrom(
              foregroundColor: puntosActuales >= 15 ? Colors.grey : Colors.green,
            ),
            child: const Text('Bonificar +1 punto'),
          ),
          TextButton(
            onPressed: puntosActuales >= 15 ? null : () => Navigator.of(context).pop('bonus_3'),
            style: TextButton.styleFrom(
              foregroundColor: puntosActuales >= 15 ? Colors.grey : Colors.green[700],
            ),
            child: const Text('Bonificar +3 puntos'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('tardanza'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Tardanza (-1 punto)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('ausencia'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('No asistió (-3 puntos)'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _aplicarSancion(jugador['id'], result);
    }
  }

  /** Aplica una sanción o bonificación individual a un jugador específico */
  Future<void> _aplicarSancion(String jugadorId, String tipoAccion) async {
    try {
      int puntosACambiar;
      String descripcion;
      
      switch (tipoAccion) {
        case 'bonus_1':
          puntosACambiar = 1;
          descripcion = 'bonificación de +1 punto';
          break;
        case 'bonus_3':
          puntosACambiar = 3;
          descripcion = 'bonificación de +3 puntos';
          break;
        case 'tardanza':
          puntosACambiar = -1;
          descripcion = 'sanción por tardanza (-1 punto)';
          break;
        case 'ausencia':
          puntosACambiar = -3;
          descripcion = 'sanción por ausencia (-3 puntos)';
          break;
        default:
          return;
      }

      final jugadorRef = FirebaseFirestore.instance.collection('usuarios').doc(jugadorId);

      final doc = await jugadorRef.get();
      final puntosActuales = doc.data()?['puntos'] ?? 15;
      
      if (puntosACambiar > 0 && puntosActuales >= 15) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El jugador ya tiene el máximo de puntos (15)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final nuevosPuntos = (puntosActuales + puntosACambiar).clamp(0, 15);

      final batch = FirebaseFirestore.instance.batch();

      batch.update(jugadorRef, {
        'puntos': nuevosPuntos,
        'lastAction': {
          'type': tipoAccion,
          'points': puntosACambiar,
          'date': FieldValue.serverTimestamp(),
          'appliedBy': userId,
        }
      });

      final equiposSnapshot = await FirebaseFirestore.instance
          .collection('equipos')
          .where('jugadoresIds', arrayContains: jugadorId)
          .get();

      for (final equipoDoc in equiposSnapshot.docs) {
        final data = equipoDoc.data();
        final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
        final jugadoresActualizados = jugadores.map((j) {
          if (j['id'] == jugadorId) {
            return {
              ...j,
              'puntos': nuevosPuntos,
            };
          }
          return j;
        }).toList();

        batch.update(equipoDoc.reference, {'jugadores': jugadoresActualizados});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aplicada $descripcion correctamente'),
            backgroundColor: puntosACambiar > 0 ? Colors.green : Colors.orange,
          ),
        );
      }

      _cargarJugadores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar acción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Activa o desactiva el modo de selección múltiple */
  void _toggleModoSeleccion() {
    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _jugadoresSeleccionados.clear();
      }
    });
  }

  /** Selecciona o deselecciona un jugador en el modo de selección múltiple */
  void _toggleSeleccionJugador(String jugadorId) {
    if (!_modoSeleccion) return;

    setState(() {
      if (_jugadoresSeleccionados.contains(jugadorId)) {
        _jugadoresSeleccionados.remove(jugadorId);
      } else {
        _jugadoresSeleccionados.add(jugadorId);
      }
    });
  }

  /** Muestra el diálogo para aplicar acciones masivas a jugadores seleccionados */
  Future<void> _aplicarAccionesMasivas() async {
    if (_jugadoresSeleccionados.isEmpty) return;

    final jugadoresConMaxPuntos = _jugadoresSeleccionados.where((id) {
      final jugador = _jugadores.firstWhere((j) => j['id'] == id);
      return (jugador['puntos'] ?? 15) >= 15;
    }).length;

    final tipoAccion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gestionar ${_jugadoresSeleccionados.length} jugador(es)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona la acción a aplicar:'),
            if (jugadoresConMaxPuntos > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Nota: $jugadoresConMaxPuntos jugador(es) ya tienen el máximo de puntos',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('bonus_1'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Bonificar +1 punto'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('bonus_3'),
            style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
            child: const Text('Bonificar +3 puntos'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('tardanza'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Tardanza (-1 punto)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('ausencia'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('No asistieron (-3 puntos)'),
          ),
        ],
      ),
    );

    if (tipoAccion != null) {
      await _procesarAccionesMasivas(tipoAccion);
    }
  }

  /** Procesa las acciones masivas aplicándolas a todos los jugadores seleccionados */
  Future<void> _procesarAccionesMasivas(String tipoAccion) async {
    setState(() {
      _isLoading = true;
    });

    try {
      int puntosACambiar;
      String descripcion;
      
      switch (tipoAccion) {
        case 'bonus_1':
          puntosACambiar = 1;
          descripcion = 'bonificación de +1 punto';
          break;
        case 'bonus_3':
          puntosACambiar = 3;
          descripcion = 'bonificación de +3 puntos';
          break;
        case 'tardanza':
          puntosACambiar = -1;
          descripcion = 'sanción por tardanza (-1 punto)';
          break;
        case 'ausencia':
          puntosACambiar = -3;
          descripcion = 'sanción por ausencia (-3 puntos)';
          break;
        default:
          return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final jugadoresSeleccionadosCopia = List<String>.from(_jugadoresSeleccionados);

      final jugadoresData = <String, Map<String, dynamic>>{};
      int jugadoresOmitidos = 0;
      
      for (final jugadorId in jugadoresSeleccionadosCopia) {
        final jugadorDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(jugadorId)
            .get();
        
        if (jugadorDoc.exists) {
          jugadoresData[jugadorId] = jugadorDoc.data() as Map<String, dynamic>;
        }
      }

      for (final jugadorId in jugadoresSeleccionadosCopia) {
        if (!jugadoresData.containsKey(jugadorId)) continue;

        final puntosActuales = jugadoresData[jugadorId]!['puntos'] ?? 15;
        
        if (puntosACambiar > 0 && puntosActuales >= 15) {
          jugadoresOmitidos++;
          continue;
        }
        
        final nuevosPuntos = (puntosActuales + puntosACambiar).clamp(0, 15);

        final jugadorRef = FirebaseFirestore.instance.collection('usuarios').doc(jugadorId);
        batch.update(jugadorRef, {
          'puntos': nuevosPuntos,
          'lastAction': {
            'type': tipoAccion,
            'points': puntosACambiar,
            'date': FieldValue.serverTimestamp(),
            'appliedBy': userId,
          }
        });

        jugadoresData[jugadorId]!['puntos'] = nuevosPuntos;
      }

      await batch.commit();

      await _actualizarEquiposConNuevosPuntos(jugadoresData);

      setState(() {
        _jugadoresSeleccionados.clear();
        _modoSeleccion = false;
        _isLoading = false;
      });

      if (mounted) {
        final jugadoresProcesados = jugadoresSeleccionadosCopia.length - jugadoresOmitidos;
        String mensaje = 'Aplicada $descripcion a $jugadoresProcesados jugador(es)';
        
        if (jugadoresOmitidos > 0) {
          mensaje += '. $jugadoresOmitidos jugador(es) omitido(s) por tener máximo de puntos';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: puntosACambiar > 0 ? Colors.green : Colors.orange,
          ),
        );
      }

      _cargarJugadores();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar acciones masivas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Actualiza los puntos de los jugadores en todos los equipos donde participan */
  Future<void> _actualizarEquiposConNuevosPuntos(Map<String, Map<String, dynamic>> jugadoresData) async {
    try {
      final equiposSnapshot = await FirebaseFirestore.instance
          .collection('equipos')
          .where('jugadoresIds', arrayContainsAny: jugadoresData.keys.toList())
          .get();

      for (final equipoDoc in equiposSnapshot.docs) {
        final data = equipoDoc.data();
        final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
        bool equipoModificado = false;

        final jugadoresActualizados = jugadores.map((j) {
          final jugadorId = j['id'];
          if (jugadoresData.containsKey(jugadorId)) {
            equipoModificado = true;
            return {
              ...j,
              'puntos': jugadoresData[jugadorId]!['puntos'],
            };
          }
          return j;
        }).toList();

        if (equipoModificado) {
          await equipoDoc.reference.update({'jugadores': jugadoresActualizados});
        }
      }
    } catch (e) {
      print('Error al actualizar equipos: $e');
    }
  }

  /** Elimina un usuario del sistema y de todos los equipos donde participa */
  Future<void> _eliminarUsuario(String jugadorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('¿Estás seguro de que deseas eliminar este usuario? Esta acción no se puede deshacer.'),
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
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();

        batch.delete(FirebaseFirestore.instance.collection('usuarios').doc(jugadorId));

        final equiposSnapshot = await FirebaseFirestore.instance
            .collection('equipos')
            .where('jugadoresIds', arrayContains: jugadorId)
            .get();

        for (final equipoDoc in equiposSnapshot.docs) {
          final data = equipoDoc.data();
          final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
          final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

          jugadoresIds.remove(jugadorId);
          final jugadoresActualizados = jugadores.where((j) => j['id'] != jugadorId).toList();

          batch.update(equipoDoc.reference, {
            'jugadoresIds': jugadoresIds,
            'jugadores': jugadoresActualizados,
          });
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado correctamente'), 
              backgroundColor: Colors.green
            ),
          );
          _cargarJugadores();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar usuario: $e'), 
              backgroundColor: Colors.red
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_modoSeleccion,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _modoSeleccion) {
          setState(() {
            _modoSeleccion = false;
            _jugadoresSeleccionados.clear();
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
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildPlayersList(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.of(context).pushReplacementNamed('/equipos');
            } else if (index == 2) {
              Navigator.of(context).pushReplacementNamed('/pistas');
            }
          },
          isAdmin: true,
        ),
      ),
    );
  }

/** Construye la sección del encabezado con título, estado y botón de logout */
Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jugadores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _modoSeleccion ? Icons.checklist : Icons.admin_panel_settings,
                    size: 16,
                    color: _modoSeleccion ? Colors.orange[700] : Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _modoSeleccion 
                          ? _jugadoresSeleccionados.isEmpty
                              ? 'Modo selección'
                              : '${_jugadoresSeleccionados.length} seleccionado${_jugadoresSeleccionados.length == 1 ? '' : 's'}'
                          : 'Administrador',
                      style: TextStyle(
                        fontSize: 14,
                        color: _modoSeleccion ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ),
      ],
    ),
  );
}

  /** Construye la barra de búsqueda con campo de texto y estilo personalizado */
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
            hintText: 'Buscar jugadores...',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
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

  /** Construye los botones de acción para gestión masiva y aplicar cambios */
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _toggleModoSeleccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _modoSeleccion ? Colors.orange[700] : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: Icon(_modoSeleccion ? Icons.close : Icons.group),
                label: Text(
                  _modoSeleccion ? 'Cancelar' : 'Gestión Masiva',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          if (_modoSeleccion)
            Expanded(
              flex: 1,
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: _jugadoresSeleccionados.isNotEmpty
                      ? _aplicarAccionesMasivas
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _jugadoresSeleccionados.isNotEmpty
                        ? Colors.green[700]
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Icon(Icons.check, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /** Construye la lista de jugadores con funcionalidad de pull-to-refresh */
  Widget _buildPlayersList() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jugadoresFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No hay jugadores registrados'
                            : 'No se encontraron jugadores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarJugadores,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _jugadoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final jugador = _jugadoresFiltrados[index];
                      final isSelected = _jugadoresSeleccionados.contains(jugador['id']);

                      return _JugadorCard(
                        jugador: jugador,
                        modoSeleccion: _modoSeleccion,
                        seleccionado: isSelected,
                        onTap: () => _modoSeleccion
                            ? _toggleSeleccionJugador(jugador['id'])
                            : _mostrarDialogoSanciones(jugador),
                        onLongPress: () => _toggleModoSeleccion(),
                        onDelete: () => _eliminarUsuario(jugador['id']),
                      );
                    },
                  ),
                ),
    );
  }
}

/** Widget personalizado para mostrar la información de cada jugador en una tarjeta.
 * Incluye avatar, datos personales, puntos con código de colores y controles de selección.
 */
class _JugadorCard extends StatelessWidget {
  /** Datos del jugador a mostrar */
  final Map<String, dynamic> jugador;
  
  /** Indica si está activo el modo de selección múltiple */
  final bool modoSeleccion;
  
  /** Indica si este jugador está seleccionado */
  final bool seleccionado;
  
  /** Callback ejecutado al tocar la tarjeta */
  final VoidCallback onTap;
  
  /** Callback ejecutado al mantener presionada la tarjeta */
  final VoidCallback onLongPress;
  
  /** Callback ejecutado al presionar el botón de eliminar */
  final VoidCallback? onDelete;

  const _JugadorCard({
    Key? key,
    required this.jugador,
    required this.modoSeleccion,
    required this.seleccionado,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final puntos = jugador['puntos'] ?? 15;
    final isAdmin = jugador['isAdmin'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: seleccionado
              ? BorderSide(color: Colors.orange, width: 2)
              : BorderSide.none,
        ),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                /** Avatar del jugador con imagen de perfil o icono por defecto */
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (jugador['profileImageUrl'] != null &&
                          jugador['profileImageUrl'].isNotEmpty)
                      ? NetworkImage(jugador['profileImageUrl'])
                      : null,
                  child: (jugador['profileImageUrl'] == null ||
                          jugador['profileImageUrl'].isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),

                /** Información personal del jugador */
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${jugador['nombre']} ${jugador['apellidos']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (!isAdmin && 
                              jugador['id'] != FirebaseAuth.instance.currentUser?.uid && 
                              onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar usuario',
                              onPressed: onDelete,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jugador['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jugador['posicion'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                /** Sección de puntos y checkbox de selección */
                Column(
                  children: [
                    /** Indicador de puntos con color según el valor */
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorForPoints(puntos),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            puntos.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /** Checkbox visible solo en modo selección */
                    if (modoSeleccion) ...[
                      const SizedBox(height: 8),
                      Checkbox(
                        value: seleccionado,
                        onChanged: (_) => onTap(),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /** Determina el color del indicador de puntos basado en el valor.
   * Verde: 15+ puntos, Naranja: 10-14 puntos, 
   * Rojo claro: 5-9 puntos, Rojo oscuro: <5 puntos
   */
  Color _getColorForPoints(int puntos) {
    if (puntos >= 15) return Colors.green;
    if (puntos >= 10) return Colors.orange;
    if (puntos >= 5) return Colors.red[400]!;
    return Colors.red[700]!;
  }
}