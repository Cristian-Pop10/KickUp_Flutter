import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/servicio/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickup/src/vista/equipos_view.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  final UserService _userService = UserService();
  
  // Variables de estado principales
  PartidoModel? _partido;
  bool _isLoading = true;
  bool _usuarioInscrito = false;
  bool _procesandoSolicitud = false;

  // Referencias para el tutorial
  final GlobalKey _inscribirseKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _cargarPartido();

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

  /** Procesa la inscripción del usuario al partido.
   * Obtiene los datos del usuario y los envía al controlador
   * para registrar la inscripción en el partido.
   */
  Future<void> _inscribirsePartido() async {
    if (_procesandoSolicitud) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final user = await _userService.getUser(widget.userId);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener el usuario')),
          );
        }
        return;
      }

      final success =
          await _partidoController.inscribirsePartido(widget.partidoId, user);

      if (success && mounted) {
        // Actualizar estado inmediatamente para mejor UX
        setState(() {
          _usuarioInscrito = true;
          if (_partido != null) {
            _partido = _partido!.copyWith(
              jugadoresFaltantes: _partido!.jugadoresFaltantes - 1,
              completo: _partido!.jugadoresFaltantes <= 1,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Te has inscrito al partido correctamente'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        // Volver a la pantalla anterior con resultado
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al inscribirse al partido'),
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

  /** Construye el AppBar personalizado */
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
            _buildActionButton(), // Botón de acción
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
        final puntos = userData['puntos'] ?? 15; // Obtener puntos del usuario

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            '$nombre $apellidos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            posicion,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // Mostrar puntos y indicador de usuario actual
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicar si es el usuario actual (ahora primero)
              if (jugadorId == widget.userId) ...[
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              // Mostrar puntos (ahora después del icono)
              Text(
                '$puntos pts',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /** Construye el botón de acción principal (inscribirse/abandonar) */
  Widget _buildActionButton() {
    final isCompleto = _partido!.completo;
    final puedeInscribirse = !isCompleto || _usuarioInscrito;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: _inscribirseKey, // Key para el tutorial
          onPressed: _procesandoSolicitud || (!puedeInscribirse)
              ? null
              : _usuarioInscrito
                  ? _abandonarPartido
                  : _inscribirsePartido,
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
              Text(
                _procesandoSolicitud
                    ? 'Procesando...'
                    : _usuarioInscrito
                        ? 'Abandonar partido'
                        : isCompleto
                            ? 'Partido completo'
                            : 'Inscribirse al partido',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
