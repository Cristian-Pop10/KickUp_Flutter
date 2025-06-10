import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../componentes/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/** Vista administrativa para la gestión de jugadores.
 * Permite a los administradores visualizar, buscar y sancionar jugadores
 * mediante un sistema de puntos. Incluye funcionalidades para aplicar
 * sanciones individuales y masivas por tardanzas o ausencias.
 */
class JugadoresView extends StatefulWidget {
  const JugadoresView({Key? key}) : super(key: key);

  @override
  State<JugadoresView> createState() => _JugadoresViewState();
}

class _JugadoresViewState extends State<JugadoresView> {
  final TextEditingController _searchController = TextEditingController();

  // Variables de estado principales
  List<Map<String, dynamic>> _jugadores = [];
  List<Map<String, dynamic>> _jugadoresFiltrados = [];
  List<String> _jugadoresSeleccionados = [];
  bool _isLoading = true;
  bool _modoSeleccion = false;
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

  /** Carga todos los jugadores desde Firestore ordenados por puntos */
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

  /** Filtra jugadores basado en el texto de búsqueda en tiempo real */
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

  /** Muestra diálogo de sanciones para un jugador individual */
  Future<void> _mostrarDialogoSanciones(Map<String, dynamic> jugador) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sancionar a ${jugador['nombre']} ${jugador['apellidos']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puntos actuales: ${jugador['puntos']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Selecciona el tipo de sanción:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
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

  /** Aplica una sanción individual al jugador especificado.
   * @param jugadorId ID del jugador a sancionar
   * @param tipoSancion Tipo de sanción ('tardanza' o 'ausencia')
   */
  Future<void> _aplicarSancion(String jugadorId, String tipoSancion) async {
    try {
      final puntosARestar = tipoSancion == 'ausencia' ? 3 : 1;
      final jugadorRef =
          FirebaseFirestore.instance.collection('usuarios').doc(jugadorId);

      // Obtener puntos actuales
      final doc = await jugadorRef.get();
      final puntosActuales = doc.data()?['puntos'] ?? 15;
      final nuevosPuntos =
          (puntosActuales - puntosARestar).clamp(0, double.infinity);

      // Actualizar puntos
      await jugadorRef.update({
        'puntos': nuevosPuntos,
        'lastSanction': {
          'type': tipoSancion,
          'points': puntosARestar,
          'date': FieldValue.serverTimestamp(),
          'appliedBy': userId,
        }
      });

      // Actualizar los puntos en el array 'jugadores' de cada equipo donde esté el jugador
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

        await equipoDoc.reference.update({'jugadores': jugadoresActualizados});
      }

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sanción aplicada: -$puntosARestar puntos por ${tipoSancion == 'ausencia' ? 'no asistir' : 'tardanza'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recargar lista
      _cargarJugadores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar sanción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Activa/desactiva el modo de selección múltiple */
  void _toggleModoSeleccion() {
    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) {
        _jugadoresSeleccionados.clear();
      }
    });
  }

  /** Selecciona/deselecciona un jugador en modo selección múltiple */
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

  /** Aplica sanciones masivas a todos los jugadores seleccionados */
  Future<void> _aplicarSancionesMasivas() async {
    if (_jugadoresSeleccionados.isEmpty) return;

    final tipoSancion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sancionar ${_jugadoresSeleccionados.length} jugador(es)'),
        content: const Text('Selecciona el tipo de sanción:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
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

    if (tipoSancion != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final batch = FirebaseFirestore.instance.batch();
        final puntosARestar = tipoSancion == 'ausencia' ? 3 : 1;

        for (final jugadorId in _jugadoresSeleccionados) {
          final jugador = _jugadores.firstWhere((j) => j['id'] == jugadorId);
          final puntosActuales = jugador['puntos'] ?? 15;
          final nuevosPuntos = (puntosActuales - puntosARestar).clamp(0, double.infinity);

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

            await equipoDoc.reference.update({'jugadores': jugadoresActualizados});
          }
        }

        await batch.commit();

        setState(() {
          _jugadoresSeleccionados.clear();
          _modoSeleccion = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sanciones aplicadas: -$puntosARestar puntos a ${_jugadoresSeleccionados.length} jugador(es)',
              ),
              backgroundColor: Colors.green,
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
              content: Text('Error al aplicar sanciones: $e'),
              backgroundColor: Colors.red,
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

  /** Construye el header con título y botón de logout */
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
                'Jugadores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _modoSeleccion ? 'Modo Sanción Masiva' : 'Administrador',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      _modoSeleccion ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
            hintText: 'Buscar jugadores...',
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

  /** Construye los botones de acción para sanciones */
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Botón modo sanción masiva
          Expanded(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _toggleModoSeleccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _modoSeleccion ? Colors.orange[700] : Colors.orange,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  _modoSeleccion ? Icons.close : Icons.warning,
                  size: 24,
                ),
              ),
            ),
          ),
          // Botón aplicar sanciones (solo visible en modo selección)
          if (_modoSeleccion)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: _jugadoresSeleccionados.isNotEmpty
                      ? _aplicarSancionesMasivas
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _jugadoresSeleccionados.isNotEmpty
                        ? Colors.red[700]
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.gavel, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /** Construye la lista de jugadores con pull-to-refresh */
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
                      final isSelected =
                          _jugadoresSeleccionados.contains(jugador['id']);

                      return _JugadorCard(
                        jugador: jugador,
                        modoSeleccion: _modoSeleccion,
                        seleccionado: isSelected,
                        onTap: () => _modoSeleccion
                            ? _toggleSeleccionJugador(jugador['id'])
                            : _mostrarDialogoSanciones(jugador),
                        onLongPress: () => _toggleModoSeleccion(),
                      );
                    },
                  ),
                ),
    );
  }
}

/** Widget personalizado para mostrar cada tarjeta de jugador.
 * Incluye avatar, información personal, puntos con código de colores
 * y funcionalidad de selección para sanciones masivas.
 */
class _JugadorCard extends StatelessWidget {
  final Map<String, dynamic> jugador;
  final bool modoSeleccion;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _JugadorCard({
    Key? key,
    required this.jugador,
    required this.modoSeleccion,
    required this.seleccionado,
    required this.onTap,
    required this.onLongPress,
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
                // Avatar del jugador
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

                // Información del jugador
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

                // Puntos y checkbox
                Column(
                  children: [
                    // Puntos con color según el valor
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

                    // Checkbox en modo selección
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

  /** Obtiene el color según los puntos del jugador.
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
