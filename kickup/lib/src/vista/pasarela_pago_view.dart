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
  
  /** Función personalizada para procesar el pago (opcional) */
  final Future<void> Function()? customProcessPayment;
  
  /** Información extra para mostrar en la UI (opcional) */
  final String? extraInfo;

  const PasarelaPagoView({
    Key? key,
    required this.partidoId,
    required this.userId,
    required this.partido,
    this.customProcessPayment,
    this.extraInfo,
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
      'expiracion': 'Expires 05/2028',
      'icono': Icons.credit_card,
      'color': Colors.orange,
    },
    {
      'id': 'visa',
      'tipo': 'Visa',
      'numero': '...5678',
      'expiracion': 'Expires 11/2028',
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
    {
      'id': 'googlepay',
      'tipo': 'Google Pay',
      'numero': '',
      'expiracion': 'Verified',
      'icono': Icons.account_balance_wallet,
      'color': Colors.green,
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
   * Puede usar una función personalizada si se proporciona.
   */
  Future<void> _procesarPago() async {
    if (_procesandoPago) return;

    setState(() {
      _procesandoPago = true;
    });

    try {
      // Si hay una función personalizada, usarla en lugar del proceso estándar
      if (widget.customProcessPayment != null) {
        await widget.customProcessPayment!();
        return;
      }

      // Proceso estándar para un solo usuario
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
        content: const Text('Esta funcionalidad estará disponible próximamente.\n\nPor ahora puedes usar los métodos de pago guardados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /** Obtiene el método de pago seleccionado */
  Map<String, dynamic> get _metodoSeleccionadoData {
    return _metodosPago.firstWhere(
      (metodo) => metodo['id'] == _metodoSeleccionado,
      orElse: () => _metodosPago.first,
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
              color: Theme.of(context).cardColor,
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
                  widget.extraInfo ?? 'Procesando pago...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
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
                // Mostrar información extra si está disponible
                if (widget.extraInfo != null) ...[
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                ],
                _buildResumenPartido(),
                const SizedBox(height: 30),
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

  /** Construye la tarjeta de información extra */
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.extraInfo!,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /** Construye el resumen del partido */
  Widget _buildResumenPartido() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Resumen del Partido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResumenItem('Tipo', widget.partido.tipo, Icons.sports_soccer),
          const SizedBox(height: 12),
          _buildResumenItem('Lugar', widget.partido.lugar, Icons.location_on),
          const SizedBox(height: 12),
          _buildResumenItem(
            'Fecha', 
            _formatearFechaPartido(widget.partido.fecha), 
            Icons.calendar_today
          ),
          const SizedBox(height: 12),
          _buildResumenItem(
            'Duración', 
            '${widget.partido.duracion} minutos', 
            Icons.timer
          ),
        ],
      ),
    );
  }

  /** Construye un item del resumen */
  Widget _buildResumenItem(String titulo, String valor, IconData icono) {
    return Row(
      children: [
        Icon(
          icono,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          '$titulo: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  /** Formatea la fecha del partido */
  String _formatearFechaPartido(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    
    return '$dia/$mes/$anio - $hora:$minuto';
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Método de pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Radio button personalizado
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: metodo['color'].withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metodo['icono'],
                  color: metodo['color'],
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información del método
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metodo['tipo']} ${metodo['numero']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metodo['expiracion'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de selección
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Seleccionado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_card,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Añadir nuevo método',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnadirMetodoTile(
            'Tarjeta de Crédito/Débito',
            Icons.credit_card,
            Colors.blue,
            () => _mostrarAnadirMetodoPago('tarjeta'),
          ),
          const SizedBox(height: 12),
          _buildAnadirMetodoTile(
            'PayPal',
            Icons.account_balance_wallet,
            Colors.indigo,
            () => _mostrarAnadirMetodoPago('PayPal'),
          ),
          const SizedBox(height: 12),
          _buildAnadirMetodoTile(
            'Transferencia Bancaria',
            Icons.account_balance,
            Colors.teal,
            () => _mostrarAnadirMetodoPago('transferencia'),
          ),
        ],
      ),
    );
  }

  /** Construye un tile para añadir método de pago */
  Widget _buildAnadirMetodoTile(String titulo, IconData icono, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detalles del Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Desglose del precio
          _buildPriceBreakdown(),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // Botón de pagar
          _buildPayButton(),
        ],
      ),
    );
  }

  /** Construye el desglose de precios */
  Widget _buildPriceBreakdown() {
    final precio = widget.partido.precio;
    final iva = precio * 0.21; // 21% IVA
    final total = precio + iva;

    return Column(
      children: [
        _buildPriceRow('Cuota del partido', '${precio.toStringAsFixed(2)}€'),
        const SizedBox(height: 8),
        _buildPriceRow('IVA (21%)', '${iva.toStringAsFixed(2)}€'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total a pagar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)}€',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /** Construye una fila de precio */
  Widget _buildPriceRow(String concepto, String precio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          concepto,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          precio,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  /** Construye el botón de pagar */
  Widget _buildPayButton() {
    final metodoSeleccionado = _metodoSeleccionadoData;
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _procesarPago,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              metodoSeleccionado['icono'],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Pagar con ${metodoSeleccionado['tipo']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}