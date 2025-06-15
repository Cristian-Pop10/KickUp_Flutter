import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/sancion_controller.dart';
import 'package:kickup/src/modelo/sancion_model.dart';
import 'package:intl/intl.dart';

/** Vista para mostrar el historial de sanciones de un jugador.
 * Muestra todas las sanciones y bonificaciones recibidas por el jugador
 * con información detallada incluyendo nombres de usuarios.
 * Utiliza streams para actualizaciones en tiempo real.
 */
class HistorialSancionesView extends StatefulWidget {
  /** ID del jugador para mostrar su historial */
  final String jugadorId;
  
  /** Nombre del jugador para mostrar en el título */
  final String nombreJugador;

  const HistorialSancionesView({
    Key? key,
    required this.jugadorId,
    required this.nombreJugador,
  }) : super(key: key);

  @override
  State<HistorialSancionesView> createState() => _HistorialSancionesViewState();
}

class _HistorialSancionesViewState extends State<HistorialSancionesView>
    with TickerProviderStateMixin {
  final SancionesController _sancionesController = SancionesController();
  
  // Controladores de animación
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /** Formatea la fecha en formato legible */
  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<SancionModel>>(
        stream: _sancionesController.streamHistorialJugador(widget.jugadorId),
        builder: (context, snapshot) {
          // Manejo de estados de conexión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          final sanciones = snapshot.data!;
          return _buildContent(sanciones);
        },
      ),
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
        'Historial de ${widget.nombreJugador}',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  /** Construye el contenido principal */
  Widget _buildContent(List<SancionModel> sanciones) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildEstadisticasCard(sanciones),
              const SizedBox(height: 20),
              _buildHistorialCard(sanciones),
            ],
          ),
        ),
      ),
    );
  }

  /** Construye la tarjeta de estadísticas */
  Widget _buildEstadisticasCard(List<SancionModel> sanciones) {
    final estadisticas = _sancionesController.calcularEstadisticas(sanciones);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Estadísticas de Asistencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Grid de estadísticas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8, 
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildEstadisticaItem(
                '',
                '${estadisticas['totalPartidos'] ?? 0}',
                Icons.sports_soccer,
                Colors.blue,
              ),
              _buildEstadisticaItem(
                '',
                '${estadisticas['aTiempo'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildEstadisticaItem(
                ' ',
                '${estadisticas['tarde'] ?? 0}',
                Icons.access_time,
                Colors.orange,
              ),
              _buildEstadisticaItem(
                '',
                '${estadisticas['noAsistio'] ?? 0}',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /** Construye un item de estadística */
  Widget _buildEstadisticaItem(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /** Construye la tarjeta del historial */
  Widget _buildHistorialCard(List<SancionModel> sanciones) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Historial de Sanciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (sanciones.isEmpty)
            _buildEmptyState()
          else
            _buildHistorialList(sanciones),
        ],
      ),
    );
  }

  /** Construye el estado vacío */
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historial de sanciones',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /** Construye la lista del historial */
  Widget _buildHistorialList(List<SancionModel> sanciones) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sanciones.length,
      itemBuilder: (context, index) {
        final sancion = sanciones[index];
        return _buildSancionItem(sancion);
      },
    );
  }

  /** Construye un item de sanción */
  Widget _buildSancionItem(SancionModel sancion) {
    final esPositivo = sancion.puntosAplicados > 0;
    final color = esPositivo ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y puntos
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sancion.estadoAsistencia.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sancion.estadoAsistencia.icono,
                      color: sancion.estadoAsistencia.color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sancion.estadoAsistencia.descripcion,
                      style: TextStyle(
                        color: sancion.estadoAsistencia.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${esPositivo ? '+' : ''}${sancion.puntosAplicados} pts',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Información del partido y fecha
          Text(
            'Partido ID: ${sancion.partidoId}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Fecha: ${_formatearFecha(sancion.fechaAplicacion)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Información de quién aplicó la sanción
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aplicado por: ${sancion.nombreAplicadoPor}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /** Construye el estado de carga */
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando historial...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /** Construye el estado de error */
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Por favor, intenta de nuevo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Forzar reconstrucción del widget
              });
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
