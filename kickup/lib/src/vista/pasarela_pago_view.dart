import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/servicio/user_service.dart';

/** Vista de pasarela de pago para inscripción a partidos.
 * Simula un proceso de pago antes de confirmar la inscripción al partido.
 * Incluye métodos de pago guardados, opción de añadir nuevos métodos
 * y detalles del pago con el precio del partido.
 */
class PasarelaPagoView extends StatefulWidget {
  /** ID del partido al que se quiere inscribir */
  final String partidoId;
  
  /** ID del usuario que se va a inscribir */
  final String userId;
  
  /** Información del partido */
  final PartidoModel partido;

  const PasarelaPagoView({
    Key? key,
    required this.partidoId,
    required this.userId,
    required this.partido,
  }) : super(key: key);

  @override
  State<PasarelaPagoView> createState() => _PasarelaPagoViewState();
}

class _PasarelaPagoViewState extends State<PasarelaPagoView>
    with TickerProviderStateMixin {
  final PartidoController _partidoController = PartidoController();
  final UserService _userService = UserService();

  // Variables de estado
  bool _procesandoPago = false;
  String _metodoSeleccionado = 'mastercard';

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Lista de métodos de pago simulados
  final List<Map<String, dynamic>> _metodosPago = [
    {
      'id': 'mastercard',
      'tipo': 'Mastercard',
      'numero': '...1234',
      'expiracion': 'Expires 05/2025',
      'icono': Icons.credit_card,
      'color': Colors.orange,
    },
    {
      'id': 'visa',
      'tipo': 'Visa',
      'numero': '...5678',
      'expiracion': 'Expires 11/2024',
      'icono': Icons.credit_card,
      'color': Colors.blue,
    },
    {
      'id': 'applepay',
      'tipo': 'Apple Pay',
      'numero': '',
      'expiracion': 'Verified',
      'icono': Icons.apple,
      'color': Colors.black,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

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

  /** Procesa el pago e inscribe al usuario al partido.
   * Simula un proceso de pago y luego procede con la inscripción real.
   */
  Future<void> _procesarPago() async {
    if (_procesandoPago) return;

    setState(() {
      _procesandoPago = true;
    });

    try {
      // Mostrar progreso de pago
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Procesando pago...'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Simular tiempo de procesamiento de pago
      await Future.delayed(const Duration(seconds: 2));

      // Obtener datos del usuario
      final user = await _userService.getUser(widget.userId);
      if (user == null) {
        throw Exception('No se pudo obtener los datos del usuario');
      }

      // Proceder con la inscripción al partido
      final success = await _partidoController.inscribirsePartido(
        widget.partidoId,
        user,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Mostrar confirmación de pago exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Pago realizado e inscripción confirmada!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Volver a la pantalla anterior con resultado exitoso
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al procesar la inscripción');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesandoPago = false;
        });
      }
    }
  }

  /** Muestra el diálogo para añadir un nuevo método de pago */
  void _mostrarAnadirMetodoPago(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir $tipo'),
        content: Text('Esta funcionalidad estará disponible próximamente.\n\nPor ahora puedes usar los métodos de pago guardados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fieldBackground(context),
      appBar: _buildAppBar(),
      body: _procesandoPago ? _buildLoadingState() : _buildPaymentContent(),
    );
  }

  /** Construye el AppBar personalizado */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(0, 159, 51, 51),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Pagar',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
    );
  }

  /** Construye el estado de carga durante el procesamiento del pago */
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Procesando pago...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor espera',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /** Construye el contenido principal de la pantalla de pago */
  Widget _buildPaymentContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildMetodosPagoSection(),
                const SizedBox(height: 30),
                _buildAnadirMetodoSection(),
                const SizedBox(height: 30),
                _buildDetallesPagoSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /** Construye la sección de métodos de pago guardados */
  Widget _buildMetodosPagoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          ...(_metodosPago.map((metodo) => _buildMetodoPagoTile(metodo)).toList()),
        ],
      ),
    );
  }

  /** Construye un tile individual de método de pago */
  Widget _buildMetodoPagoTile(Map<String, dynamic> metodo) {
    final isSelected = _metodoSeleccionado == metodo['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _metodoSeleccionado = metodo['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Checkbox personalizado
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Icono del método de pago
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: metodo['color'].withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metodo['icono'],
                  color: metodo['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información del método
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metodo['tipo']}${metodo['numero']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      metodo['expiracion'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de selección
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /** Construye la sección para añadir nuevos métodos de pago */
  Widget _buildAnadirMetodoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Añadir nuevo método de pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _buildAnadirMetodoTile(
            'Credit/Debit Card',
            Icons.credit_card,
            () => _mostrarAnadirMetodoPago('tarjeta'),
          ),
          const SizedBox(height: 12),
          _buildAnadirMetodoTile(
            'PayPal',
            Icons.account_balance_wallet,
            () => _mostrarAnadirMetodoPago('PayPal'),
          ),
        ],
      ),
    );
  }

  /** Construye un tile para añadir método de pago */
  Widget _buildAnadirMetodoTile(String titulo, IconData icono, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /** Construye la sección de detalles del pago */
  Widget _buildDetallesPagoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles del Pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          
          // Detalle del precio
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.adaptiveBeige(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuota del Partido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '${widget.partido.precio.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón de pagar
              ElevatedButton(
                onPressed: _procesarPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Pagar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
