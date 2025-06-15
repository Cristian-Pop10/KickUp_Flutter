import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/controlador/sancion_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/modelo/sancion_model.dart';
import 'package:kickup/src/modelo/user_model.dart';
import 'package:kickup/src/vista/historial_sanciones_view.dart';

/** Vista para gestionar sanciones y asistencia de jugadores.
 * Permite al creador del partido marcar la asistencia de cada jugador
 * inscrito, indicando si llegó a tiempo, tarde o no asistió.
 * Incluye sistema de puntuación y penalizaciones.
 */
class SancionesView extends StatefulWidget {
  /** ID del partido */
  final String partidoId;
  
  /** ID del usuario creador del partido */
  final String creadorId;

  const SancionesView({
    Key? key,
    required this.partidoId,
    required this.creadorId,
  }) : super(key: key);

  @override
  State<SancionesView> createState() => _SancionesViewState();
}

class _SancionesViewState extends State<SancionesView>
    with TickerProviderStateMixin {
  final PartidoController _partidoController = PartidoController();
  final SancionesController _sancionesController = SancionesController();
  
  // Variables de estado
  PartidoModel? _partido;
  bool _isLoading = true;
  bool _guardandoCambios = false;
  bool _sancionesYaAplicadas = false;
  
  // Mapa para almacenar el estado de asistencia de cada jugador
  Map<String, EstadoAsistencia> _estadosAsistencia = {};
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _cargarPartido();
    
    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /** Carga la información del partido y verifica si ya se aplicaron sanciones */
  Future<void> _cargarPartido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final partido = await _partidoController.obtenerPartidoPorId(widget.partidoId);
      final sancionesAplicadas = await _sancionesController.sancionesYaAplicadas(widget.partidoId);
      
      if (mounted && partido != null) {
        setState(() {
          _partido = partido;
          _sancionesYaAplicadas = sancionesAplicadas;
          
          // Inicializar todos los jugadores como "Sin marcar" si no se han aplicado sanciones
          if (!sancionesAplicadas) {
            _estadosAsistencia = {
              for (var jugador in partido.jugadores)
                jugador.id!: EstadoAsistencia.sinMarcar
            };
          } else {
            // Si ya se aplicaron, cargar los estados existentes
            _cargarEstadosExistentes();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el partido: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Carga los estados de asistencia ya aplicados */
  Future<void> _cargarEstadosExistentes() async {
    try {
      final sanciones = await _sancionesController.obtenerSancionesPartido(widget.partidoId);
      
      setState(() {
        _estadosAsistencia = {
          for (var sancion in sanciones)
            sancion.jugadorId: sancion.estadoAsistencia
        };
      });
    } catch (e) {
      print('Error al cargar estados existentes: $e');
    }
  }

  /** Guarda los cambios de asistencia en la base de datos */
  Future<void> _guardarCambios() async {
    if (_sancionesYaAplicadas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las sanciones ya fueron aplicadas para este partido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _guardandoCambios = true;
    });

    try {
      final exito = await _sancionesController.aplicarSanciones(
        widget.partidoId,
        _estadosAsistencia,
        widget.creadorId,
      );
      
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Sanciones aplicadas correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        Navigator.pop(context, true);
      } else if (mounted) {
        throw Exception('No se pudieron aplicar las sanciones');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardandoCambios = false;
        });
      }
    }
  }

  /** Cambia el estado de asistencia de un jugador */
  void _cambiarEstadoAsistencia(String jugadorId, EstadoAsistencia nuevoEstado) {
    if (_sancionesYaAplicadas) return;
    
    setState(() {
      _estadosAsistencia[jugadorId] = nuevoEstado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partido == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: !_sancionesYaAplicadas ? _buildBottomBar() : null,
    );
  }

  /** Construye el AppBar personalizado */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Gestionar Asistencia',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  /** Construye el estado de error */
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el partido',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPartido,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /** Construye el contenido principal */
  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildJugadoresList()),
            ],
          ),
        ),
      ),
    );
  }

  /** Construye el encabezado con información del partido */
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBeige(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_partido!.tipo} - ${_partido!.lugar}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _sancionesYaAplicadas 
                  ? const Color.fromARGB(255, 107, 99, 88).withAlpha(25)
                  : Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _sancionesYaAplicadas 
                  ? 'Sanciones ya aplicadas - Solo lectura'
                  : 'Marca la asistencia de cada jugador',
              style: TextStyle(
                color: _sancionesYaAplicadas 
                    ? const Color.fromARGB(255, 255, 0, 0)
                    : Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /** Construye la lista de jugadores con opciones de asistencia */
  Widget _buildJugadoresList() {
    if (_partido?.jugadores.isEmpty ?? true) {
      return const Center(
        child: Text('No hay jugadores inscritos en este partido.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _partido!.jugadores.length,
      itemBuilder: (context, index) {
        final jugador = _partido!.jugadores[index];
        return _buildJugadorCard(jugador);
      },
    );
  }

  /** Construye la tarjeta de un jugador con opciones de asistencia */
  Widget _buildJugadorCard(UserModel jugador) {
    if (jugador.id == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(jugador.id!)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          // Muestra un loader o el estado anterior
          return _buildJugadorCardContent(jugador);
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final nombre = userData['nombre'] ?? '';
        final apellidos = userData['apellidos'] ?? '';
        final puntos = userData['puntos'] ?? 15;
        final profileImageUrl = userData['profileImageUrl'] ?? '';

        // Crea un nuevo UserModel actualizado
        final jugadorActualizado = jugador.copyWith(
          nombre: nombre,
          apellidos: apellidos,
          puntos: puntos,
          profileImageUrl: profileImageUrl,
        );
        return _buildJugadorCardContent(jugadorActualizado);
      },
    );
  }

  // Extrae el contenido de la tarjeta aquí para reutilizarlo
  Widget _buildJugadorCardContent(UserModel jugador) {
    final estadoActual = _estadosAsistencia[jugador.id!] ?? EstadoAsistencia.sinMarcar;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: estadoActual.color.withAlpha(102),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Información del jugador
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: (jugador.profileImageUrl != null && jugador.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(jugador.profileImageUrl!)
                      : null,
                  child: (jugador.profileImageUrl == null || jugador.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${jugador.nombre ?? ''} ${jugador.apellidos ?? ''}'.trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${jugador.puntos ?? 15} puntos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => HistorialSancionesView(
                                      jugadorId: jugador.id!,
                                      nombreJugador: '${jugador.nombre ?? ''} ${jugador.apellidos ?? ''}'.trim(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ver historial',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Estado actual en una fila aparte
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estadoActual.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estadoActual.icono,
                      color: estadoActual.color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estadoActual.descripcion,
                      style: TextStyle(
                        color: estadoActual.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            if (!_sancionesYaAplicadas) ...[
              const SizedBox(height: 16),
              
              // Opciones de asistencia
              Row(
                children: [
                  Expanded(
                    child: _buildOpcionAsistencia(
                      jugador.id!,
                      EstadoAsistencia.aTiempo,
                      'A tiempo',
                      EstadoAsistencia.aTiempo.icono,
                      EstadoAsistencia.aTiempo.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOpcionAsistencia(
                      jugador.id!,
                      EstadoAsistencia.tarde,
                      'Tarde',
                      EstadoAsistencia.tarde.icono,
                      EstadoAsistencia.tarde.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOpcionAsistencia(
                      jugador.id!,
                      EstadoAsistencia.noAsistio,
                      'No vino',
                      EstadoAsistencia.noAsistio.icono,
                      EstadoAsistencia.noAsistio.color,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /** Construye un botón de opción de asistencia */
  Widget _buildOpcionAsistencia(
    String jugadorId,
    EstadoAsistencia estado,
    String texto,
    IconData icono,
    Color color,
  ) {
    final isSelected = _estadosAsistencia[jugadorId] == estado;
    
    return GestureDetector(
      onTap: () => _cambiarEstadoAsistencia(jugadorId, estado),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /** Construye la barra inferior con el botón de guardar */
  Widget _buildBottomBar() {
    final jugadoresMarcados = _estadosAsistencia.values
        .where((estado) => estado != EstadoAsistencia.sinMarcar)
        .length;
    final totalJugadores = _estadosAsistencia.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progreso
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progreso: $jugadoresMarcados/$totalJugadores jugadores',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botón guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardandoCambios ? null : _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_guardandoCambios) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (!_guardandoCambios) ...[
                    const Icon(Icons.save, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _guardandoCambios ? 'Aplicando sanciones...' : 'Aplicar Sanciones',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
