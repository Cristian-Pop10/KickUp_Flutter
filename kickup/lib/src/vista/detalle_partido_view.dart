import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickup/src/vista/equipos_view.dart';
import 'package:kickup/src/vista/pasarela_pago_equipo_view.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:kickup/src/vista/sanciones_view.dart';
import 'package:kickup/src/modelo/equipo_model.dart';
import 'package:kickup/src/controlador/equipo_controller.dart';
import 'package:kickup/src/vista/pasarela_pago_view.dart';

/** Vista detallada de un partido deportivo.
 * Muestra información completa del partido, lista de jugadores inscritos,
 * y permite inscribirse/abandonar el partido. Incluye funcionalidad
 * de tutorial interactivo para guiar a nuevos usuarios.
 */
class DetallePartidoView extends StatefulWidget {
  /** ID del partido a mostrar */
  final String partidoId;
  
  /** ID del usuario actual */
  final String userId;
  
  /** Indica si se debe mostrar el tutorial */
  final bool showTutorial; 

  const DetallePartidoView({
    Key? key,
    required this.partidoId,
    required this.userId,
    this.showTutorial = false, 
  }) : super(key: key);

  @override
  State<DetallePartidoView> createState() => _DetallePartidoViewState();
}

class _DetallePartidoViewState extends State<DetallePartidoView> {
  // Controladores para manejar la lógica 
  final PartidoController _partidoController = PartidoController();
  final EquipoController _equipoController = EquipoController();
  
  // Variables de estado principales
  PartidoModel? _partido;
  bool _isLoading = true;
  bool _usuarioInscrito = false;
  bool _procesandoSolicitud = false;
  List<EquipoModel> _equiposUsuario = [];

  // Referencias para el tutorial
  final GlobalKey _inscribirseKey = GlobalKey();
  final GlobalKey _inscribirEquipoKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _cargarPartido();
    _cargarEquiposUsuario();

    // Iniciar tutorial si está habilitado
    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  /** Muestra el tutorial interactivo para guiar al usuario.
   * Utiliza la biblioteca TutorialCoachMark para resaltar
   * elementos importantes de la interfaz con explicaciones.
   */
  void _showTutorial() {
    targets = [
      TargetFocus(
        identify: "inscribirse",
        keyTarget: _inscribirseKey,
        contents: [
          TargetContent(
            child: const Text(
              "¡Inscríbete al partido aquí!",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "inscribir_equipo",
        keyTarget: _inscribirEquipoKey,
        contents: [
          TargetContent(
            child: const Text(
              "¡Inscribe a todo tu equipo de una vez!",
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
        // Al terminar, navega a EquiposView con tutorial
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EquiposView(showTutorial: true),
          ),
        );
        return false;
      },
      onSkip: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EquiposView(showTutorial: true),
          ),
        );
        return false;
      },
    ).show(context: context);
  }

  /** Carga la información del partido y verifica si el usuario está inscrito.
   * Obtiene los datos del partido desde el controlador y verifica
   * el estado de inscripción del usuario actual.
   */
  Future<void> _cargarPartido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final partido =
          await _partidoController.obtenerPartidoPorId(widget.partidoId);
      final inscrito = await _partidoController.verificarInscripcion(
          widget.partidoId, widget.userId);

      if (mounted) {
        setState(() {
          _partido = partido;
          _usuarioInscrito = inscrito;
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
              content: Text('Error al cargar el partido: ${e.toString()}')),
        );
      }
    }
  }

  /** Carga los equipos a los que pertenece el usuario actual */
  Future<void> _cargarEquiposUsuario() async {
    setState(() {
    });

    try {
      // Obtener todos los equipos
      final todosEquipos = await _equipoController.obtenerEquipos();
      
      // Filtrar solo los equipos donde el usuario es miembro
      final misEquipos = todosEquipos.where((equipo) => 
        equipo.jugadoresIds.contains(widget.userId)
      ).toList();

      if (mounted) {
        setState(() {
          _equiposUsuario = misEquipos;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        });
        print('Error al cargar equipos del usuario: $e');
      }
    }
  }

  /** Verifica si el usuario actual es el creador del partido */
  bool _esCreadorDelPartido() {
    // Aquí deberías verificar si el usuario actual creó el partido
    // Por ahora, asumiremos que el primer jugador de la lista es el creador
    if (_partido?.jugadores.isNotEmpty == true) {
      return _partido!.jugadores.first.id == widget.userId;
    }
    return false;
  }

  /** Elimina el partido con confirmación del usuario */
  Future<void> _eliminarPartido() async {
    // Mostrar diálogo de confirmación
    final confirmar = await _mostrarDialogoConfirmacionEliminar();
    if (confirmar != true) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final success = await _partidoController.eliminarPartido(widget.partidoId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Partido eliminado correctamente'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el partido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
        setState(() {
          _procesandoSolicitud = false;
        });
      }
    }
  }

  /** Muestra un diálogo de confirmación para eliminar el partido */
  Future<bool?> _mostrarDialogoConfirmacionEliminar() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este partido?\n\n'
          'Esta acción no se puede deshacer y todos los jugadores inscritos serán notificados.',
        ),
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
  }

  /** Navega a la pasarela de pago para procesar la inscripción.
   * Navega a la pasarela de pago en lugar de inscribirse directamente.
   */
  Future<void> _navegarAPasarelaPago() async {
    if (_procesandoSolicitud || _partido == null) return;

    try {
      // Navegar a la pasarela de pago
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PasarelaPagoView(
            partidoId: widget.partidoId,
            userId: widget.userId,
            partido: _partido!,
          ),
        ),
      );

      // Si el pago fue exitoso, actualizar la vista
      if (resultado == true && mounted) {
        // Recargar los datos del partido para reflejar la inscripción
        await _cargarPartido();
        
        // Volver a la pantalla anterior con resultado exitoso
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Muestra un diálogo para seleccionar un equipo y registrar a todos sus miembros */
  Future<void> _mostrarDialogoSeleccionEquipo() async {
    if (_equiposUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No perteneces a ningún equipo. Crea o únete a un equipo primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final EquipoModel? equipoSeleccionado = await showDialog<EquipoModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar equipo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _equiposUsuario.length,
            itemBuilder: (context, index) {
              final equipo = _equiposUsuario[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: equipo.logoUrl.isNotEmpty 
                      ? NetworkImage(equipo.logoUrl) 
                      : null,
                  child: equipo.logoUrl.isEmpty 
                      ? const Icon(Icons.group) 
                      : null,
                ),
                title: Text(equipo.nombre),
                subtitle: Text('${equipo.jugadoresIds.length} jugadores'),
                onTap: () => Navigator.of(context).pop(equipo),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (equipoSeleccionado != null) {
      _navegarAPasarelaEquipo(equipoSeleccionado);
    }
  }

  /** Navega a la pasarela de pago para inscribir un equipo completo */
  Future<void> _navegarAPasarelaEquipo(EquipoModel equipo) async {
    if (_procesandoSolicitud || _partido == null) return;

    // Calcular el precio total para el equipo
    final int jugadoresAInscribir = _partido!.jugadoresFaltantes >= equipo.jugadoresIds.length 
        ? equipo.jugadoresIds.length 
        : _partido!.jugadoresFaltantes;
    
    final double precioTotal = _partido!.precio * jugadoresAInscribir;

    // Crear un partido temporal con el precio total para el equipo
    final partidoEquipo = _partido!.copyWith(precio: precioTotal);

    try {
      // Mostrar diálogo de confirmación con detalles del pago
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar inscripción de equipo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equipo: ${equipo.nombre}'),
              Text('Jugadores a inscribir: $jugadoresAInscribir'),
              Text('Precio por jugador: ${_partido!.precio.toStringAsFixed(2)}€'),
              const Divider(),
              Text(
                'Total a pagar: ${precioTotal.toStringAsFixed(2)}€',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar al pago'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmar) return;

      // Navegar a la pasarela de pago con el precio del equipo
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PasarelaPagoEquipoView(
            partidoId: widget.partidoId,
            userId: widget.userId,
            partido: partidoEquipo,
            equipo: equipo,
            jugadoresAInscribir: jugadoresAInscribir,
          ),
        ),
      );

      // Si el pago fue exitoso, actualizar la vista
      if (resultado == true && mounted) {
        // Recargar los datos del partido para reflejar las inscripciones
        await _cargarPartido();
        
        // Volver a la pantalla anterior con resultado exitoso
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago del equipo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /** Procesa el abandono del partido con confirmación.
   * Muestra un diálogo de confirmación antes de proceder
   * a eliminar al usuario de la lista de jugadores.
   */
  Future<void> _abandonarPartido() async {
    if (_procesandoSolicitud) return;

    // Mostrar diálogo de confirmación
    final confirmar = await _mostrarDialogoConfirmacion();
    if (confirmar != true) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final success = await _partidoController.abandonarPartido(
          widget.partidoId, widget.userId);

      if (success && mounted) {
        // Actualizar estado inmediatamente
        setState(() {
          _usuarioInscrito = false;
          if (_partido != null) {
            _partido = _partido!.copyWith(
              jugadoresFaltantes: _partido!.jugadoresFaltantes + 1,
              completo: false,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Has abandonado el partido correctamente'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abandonar el partido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
        setState(() {
          _procesandoSolicitud = false;
        });
      }
    }
  }

  /** Muestra un diálogo de confirmación para abandonar el partido.
   * @return true si el usuario confirma, false en caso contrario
   */
  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar partido'),
        content:
            const Text('¿Estás seguro de que quieres abandonar este partido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
  }

  /** Formatea la fecha del partido en formato legible español.
   * @param fecha Fecha del partido a formatear
   * @return Cadena con formato "día de mes, año - hora:minuto"
   */
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day;
    final mes = _obtenerNombreMes(fecha.month);
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia de $mes, $anio - $hora:$minuto';
  }

  /** Obtiene el nombre del mes en español.
   * @param mes Número del mes (1-12)
   * @return Nombre del mes en español
   */
  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
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
              : _buildPartidoContent(),
    );
  }

  /** Construye el AppBar personalizado con opción de eliminar para el creador */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Detalle del partido',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Mostrar botón de eliminar solo si es el creador del partido
        if (_esCreadorDelPartido())
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).iconTheme.color,
            ),
            onSelected: (value) {
              if (value == 'eliminar') {
                _eliminarPartido();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar partido',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  /** Construye el estado de error cuando no se encuentra el partido */
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Partido no encontrado',
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

  /** Construye el contenido principal del partido */
  Widget _buildPartidoContent() {
    return SingleChildScrollView(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(), // Encabezado con fecha y tipo
            _buildPartidoInfo(), // Información del partido
            _buildPlayersSection(), // Lista de jugadores
            // Botón de gestionar asistencia (solo para el creador)
            if (_esCreadorDelPartido()) _buildGestionarAsistenciaButton(),
            _buildActionButtons(), // Botones de acción
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /** Construye el encabezado con fecha y tipo de partido */
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatearFecha(_partido!.fecha),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_partido!.tipo} ${_partido!.lugar}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  /** Construye la información detallada del partido */
  Widget _buildPartidoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del partido
          _buildEstadoPartido(),
          const SizedBox(height: 24),

          // Detalles del partido
          _buildInfoSection('Ubicación', _partido!.lugar, Icons.location_on),
          const SizedBox(height: 16),
          _buildInfoSection(
              'Precio', '${_partido!.precio}€ por persona', Icons.euro),
          const SizedBox(height: 16),
          _buildInfoSection(
              'Duración', '${_partido!.duracion} minutos', Icons.timer),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /** Construye el indicador de estado del partido (completo/incompleto) */
  Widget _buildEstadoPartido() {
    final isCompleto = _partido!.completo;
    final jugadoresFaltantes = _partido!.jugadoresFaltantes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleto ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleto ? Colors.red.shade300 : Colors.green.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleto ? Icons.group : Icons.group_add,
            color: isCompleto ? Colors.red.shade800 : Colors.green.shade800,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isCompleto
                ? 'Partido completo'
                : 'Faltan $jugadoresFaltantes jugadores',
            style: TextStyle(
              color: isCompleto ? Colors.red.shade800 : Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /** Construye la sección de jugadores inscritos */
  Widget _buildPlayersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jugadores inscritos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlayersList(),
        ],
      ),
    );
  }

  /** Construye el botón para gestionar asistencia (solo visible para el creador) */
  Widget _buildGestionarAsistenciaButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final resultado = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => SancionesView(
                  partidoId: widget.partidoId,
                  creadorId: widget.userId,
                ),
              ),
            );
            
            if (resultado == true) {
              // Recargar datos si se guardaron cambios
              _cargarPartido();
            }
          },
          icon: const Icon(Icons.checklist, size: 20),
          label: const Text(
            'Gestionar Asistencia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  /** Construye la lista de jugadores con actualizaciones en tiempo real */
  Widget _buildPlayersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('partidos')
          .doc(widget.partidoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Text('No se pudo cargar la información de jugadores.');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (jugadores.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'No hay jugadores inscritos.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jugadores.length,
          itemBuilder: (context, index) {
            final jugador = jugadores[index];
            return _buildPlayerTile(jugador);
          },
        );
      },
    );
  }

  /** Construye un tile individual de jugador con avatar y datos */
  Widget _buildPlayerTile(Map<String, dynamic> jugador) {
    final jugadorId = jugador['id'] as String?;

    if (jugadorId == null) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        title: const Text('Jugador no válido'),
        subtitle: const Text('ID no encontrado'),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(jugadorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            title: const Text('Cargando jugador...'),
          );
        }

        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            userSnapshot.data!.data() == null) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.grey),
            ),
            title: const Text('Error al cargar jugador'),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final imageUrl = userData['profileImageUrl'] as String?;
        final nombre = userData['nombre'] ?? '';
        final apellidos = userData['apellidos'] ?? '';
        final posicion = userData['posicion'] ?? 'Sin posición';
        final puntos = userData['puntos'] ?? 15;

        // StreamBuilder adicional para obtener el equipo del jugador
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('equipos')
              .where('jugadoresIds', arrayContains: jugadorId)
              .snapshots(),
          builder: (context, equiposSnapshot) {
            String equipoNombre = 'Sin equipo';
            
            if (equiposSnapshot.hasData && equiposSnapshot.data!.docs.isNotEmpty) {
              // Tomar el primer equipo encontrado
              final equipoData = equiposSnapshot.data!.docs.first.data() as Map<String, dynamic>;
              equipoNombre = equipoData['nombre'] ?? 'Sin equipo';
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: jugadorId == widget.userId 
                    ? Theme.of(context).colorScheme.primary.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: jugadorId == widget.userId 
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary.withAlpha(102),
                        width: 1,
                      )
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                title: Text(
                  '$nombre $apellidos',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: jugadorId == widget.userId 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    // Mostrar posición
                    Text(
                      posicion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Mostrar equipo con icono
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            equipoNombre,
                            style: TextStyle(
                              fontSize: 12,
                              color: equipoNombre == 'Sin equipo' 
                                  ? Colors.grey[500]
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: equipoNombre == 'Sin equipo' 
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontStyle: equipoNombre == 'Sin equipo' 
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicar si es el usuario actual
                    if (jugadorId == widget.userId) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tú',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Mostrar puntos en formato vertical
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$puntos',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'pts',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /** Construye los botones de acción (inscribirse/abandonar e inscribir equipo) */
  Widget _buildActionButtons() {
    final isCompleto = _partido!.completo;
    final puedeInscribirse = !isCompleto || _usuarioInscrito;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Botón principal (inscribirse/abandonar) 
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: _inscribirseKey, // Key para el tutorial
              onPressed: _procesandoSolicitud || (!puedeInscribirse)
                  ? null
                  : _usuarioInscrito
                      ? _abandonarPartido
                      : _navegarAPasarelaPago, 
              style: ElevatedButton.styleFrom(
                backgroundColor: _usuarioInscrito
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_procesandoSolicitud) ...[
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
                  if (_usuarioInscrito && !_procesandoSolicitud) ...[
                    const Icon(Icons.exit_to_app, size: 20),
                    const SizedBox(width: 8),
                  ],
                  if (!_usuarioInscrito && !_procesandoSolicitud) ...[
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _procesandoSolicitud
                        ? 'Procesando...'
                        : _usuarioInscrito
                            ? 'Abandonar partido'
                            : isCompleto
                                ? 'Partido completo'
                                : 'Pagar e inscribirse',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón para inscribir equipo completo (solo si no está inscrito y hay plazas)
          if (!_usuarioInscrito && !isCompleto && _partido!.jugadoresFaltantes > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: _inscribirEquipoKey, // Key para el tutorial
                onPressed: _procesandoSolicitud ? null : _mostrarDialogoSeleccionEquipo,
                icon: const Icon(Icons.group_add, size: 20),
                label: const Text(
                  'Pagar e inscribir equipo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /** Construye una sección de información con icono.
   * @param title Título de la información
   * @param value Valor a mostrar
   * @param icon Icono a mostrar junto al título
   */
  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

