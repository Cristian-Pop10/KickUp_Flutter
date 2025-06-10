import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';

/** Pantalla que muestra los términos y condiciones de uso de la aplicación KickUp.
 * Incluye todas las secciones legales necesarias para el uso de la plataforma
 * de gestión de equipos deportivos.
 */
class TerminosCondicionesView extends StatefulWidget {
  const TerminosCondicionesView({Key? key}) : super(key: key);

  @override
  State<TerminosCondicionesView> createState() =>
      _TerminosCondicionesViewState();
}

class _TerminosCondicionesViewState extends State<TerminosCondicionesView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // Listener para mostrar/ocultar botón de scroll to top
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /** Navega al inicio del documento */
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: _buildAppBar(),
      body: _buildContent(),
      floatingActionButton: _showScrollToTop ? _buildScrollToTopButton() : null,
    );
  }

  /** Construye el AppBar personalizado */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Términos y Condiciones',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        // Botón para compartir términos
        IconButton(
          icon: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            // Implementar funcionalidad de compartir
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad de compartir próximamente'),
              ),
            );
          },
        ),
      ],
    );
  }

  /** Construye el contenido principal con los términos */
  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildLastUpdated(),
            const SizedBox(height: 32),
            _buildSection(
              '1. Aceptación de los Términos',
              _getAceptacionContent(),
            ),
            _buildSection(
              '2. Descripción del Servicio',
              _getDescripcionContent(),
            ),
            _buildSection(
              '3. Registro y Cuenta de Usuario',
              _getRegistroContent(),
            ),
            _buildSection(
              '4. Uso Aceptable',
              _getUsoAceptableContent(),
            ),
            _buildSection(
              '5. Privacidad y Protección de Datos',
              _getPrivacidadContent(),
            ),
            _buildSection(
              '6. Contenido del Usuario',
              _getContenidoUsuarioContent(),
            ),
            _buildSection(
              '7. Propiedad Intelectual',
              _getPropiedadIntelectualContent(),
            ),
            _buildSection(
              '8. Limitación de Responsabilidad',
              _getLimitacionResponsabilidadContent(),
            ),
            _buildSection(
              '9. Modificaciones del Servicio',
              _getModificacionesContent(),
            ),
            _buildSection(
              '10. Terminación',
              _getTerminacionContent(),
            ),
            _buildSection(
              '11. Ley Aplicable',
              _getLeyAplicableContent(),
            ),
            _buildSection(
              '12. Contacto',
              _getContactoContent(),
            ),
            const SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /** Construye el header principal */
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KickUp',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    'Términos y Condiciones de Uso',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Por favor, lee cuidadosamente estos términos antes de usar KickUp.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /** Construye la fecha de última actualización */
  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.update, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Última actualización: 10 de Junio de 2025',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /** Construye una sección de contenido */
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  /** Construye el footer */
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, color: Colors.green[700], size: 32),
          const SizedBox(height: 12),
          Text(
            'Gracias por confiar en KickUp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estamos comprometidos con ofrecerte la mejor experiencia en la gestión de equipos deportivos.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /** Construye el botón de scroll to top */
  Widget _buildScrollToTopButton() {
    return FloatingActionButton(
      onPressed: _scrollToTop,
      backgroundColor: Colors.green,
      child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
    );
  }

  // Métodos que retornan el contenido de cada sección

  String _getAceptacionContent() {
    return '''Al acceder y utilizar la aplicación KickUp, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestro servicio.

Estos términos constituyen un acuerdo legal vinculante entre usted y KickUp. Al crear una cuenta o utilizar cualquier función de la aplicación, confirma que ha leído, entendido y acepta cumplir con estos términos.''';
  }

  String _getDescripcionContent() {
    return '''KickUp es una aplicación móvil diseñada para facilitar la gestión de equipos deportivos, organización de partidos y reserva de instalaciones deportivas. Nuestro servicio incluye:

• Creación y gestión de equipos deportivos
• Organización y seguimiento de partidos
• Sistema de reservas de pistas deportivas
• Gestión de jugadores y estadísticas
• Sistema de notificaciones y comunicación
• Herramientas administrativas para gestores

El servicio se proporciona "tal como está" y nos reservamos el derecho de modificar, suspender o discontinuar cualquier aspecto del servicio en cualquier momento.''';
  }

  String _getRegistroContent() {
    return '''Para utilizar KickUp, debe crear una cuenta proporcionando información precisa y completa. Usted es responsable de:

• Mantener la confidencialidad de sus credenciales de acceso
• Todas las actividades que ocurran bajo su cuenta
• Notificar inmediatamente cualquier uso no autorizado
• Proporcionar información veraz y actualizada

Nos reservamos el derecho de suspender o terminar cuentas que violen estos términos o proporcionen información falsa. Debe tener al menos 13 años para crear una cuenta.''';
  }

  String _getUsoAceptableContent() {
    return '''Al utilizar KickUp, se compromete a:

ESTÁ PERMITIDO:
• Usar la aplicación para fines deportivos legítimos
• Respetar a otros usuarios y mantener un comportamiento deportivo
• Proporcionar información precisa sobre partidos y equipos
• Cumplir con las normas de las instalaciones deportivas

ESTÁ PROHIBIDO:
• Usar la aplicación para actividades ilegales o fraudulentas
• Acosar, intimidar o discriminar a otros usuarios
• Publicar contenido ofensivo, violento o inapropiado
• Intentar acceder a cuentas de otros usuarios
• Usar la aplicación para spam o actividades comerciales no autorizadas
• Interferir con el funcionamiento normal del servicio''';
  }

  String _getPrivacidadContent() {
    return '''La protección de su privacidad es fundamental para nosotros. Recopilamos y procesamos sus datos personales de acuerdo con nuestra Política de Privacidad, que forma parte integral de estos términos.

Los datos que recopilamos incluyen:
• Información de perfil (nombre, email, foto)
• Datos de actividad deportiva
• Información de ubicación para reservas de pistas
• Estadísticas de juego y rendimiento

Sus datos se utilizan exclusivamente para proporcionar y mejorar nuestros servicios. No vendemos ni compartimos su información personal con terceros sin su consentimiento, excepto cuando sea requerido por ley.''';
  }

  String _getContenidoUsuarioContent() {
    return '''Usted retiene la propiedad del contenido que publique en KickUp (fotos, comentarios, información de equipos). Sin embargo, nos otorga una licencia no exclusiva para usar, mostrar y distribuir dicho contenido dentro de la aplicación.

Usted es responsable de asegurar que su contenido:
• No infrinja derechos de terceros
• Sea apropiado y respetuoso
• Cumpla con las leyes aplicables
• No contenga virus o código malicioso

Nos reservamos el derecho de eliminar contenido que viole estos términos o que consideremos inapropiado.''';
  }

  String _getPropiedadIntelectualContent() {
    return '''KickUp y todo su contenido (diseño, código, logotipos, textos) están protegidos por derechos de propiedad intelectual. Estos derechos pertenecen a KickUp o a sus licenciantes.

Se le otorga una licencia limitada, no exclusiva e intransferible para usar la aplicación únicamente para los fines previstos. No puede:
• Copiar, modificar o distribuir la aplicación
• Realizar ingeniería inversa del software
• Usar nuestras marcas comerciales sin autorización
• Crear trabajos derivados basados en nuestro servicio''';
  }

  String _getLimitacionResponsabilidadContent() {
    return '''KickUp se proporciona "tal como está" sin garantías de ningún tipo. En la máxima medida permitida por la ley, limitamos nuestra responsabilidad por:

• Interrupciones del servicio o errores técnicos
• Pérdida de datos o información
• Daños indirectos o consecuenciales
• Disputas entre usuarios
• Problemas con instalaciones deportivas de terceros

Su uso de la aplicación es bajo su propio riesgo. Recomendamos mantener copias de seguridad de información importante y verificar siempre los detalles de reservas y partidos.''';
  }

  String _getModificacionesContent() {
    return '''Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios importantes se notificarán a través de:

• Notificaciones dentro de la aplicación
• Email a la dirección registrada
• Aviso en nuestra página web

El uso continuado de KickUp después de la notificación de cambios constituye su aceptación de los nuevos términos. Si no está de acuerdo con las modificaciones, debe dejar de usar el servicio.

También podemos actualizar, modificar o discontinuar características de la aplicación para mejorar la experiencia del usuario o por razones técnicas.''';
  }

  String _getTerminacionContent() {
    return '''Puede terminar su cuenta en cualquier momento eliminándola desde la configuración de la aplicación. Nos reservamos el derecho de suspender o terminar cuentas que:

• Violen estos términos de uso
• Participen en actividades fraudulentas
• Abusen del servicio o de otros usuarios
• No hayan sido utilizadas por un período prolongado

Tras la terminación:
• Su acceso al servicio cesará inmediatamente
• Sus datos personales serán eliminados según nuestra política de retención
• Las obligaciones que por su naturaleza deban sobrevivir continuarán vigentes''';
  }

  String _getLeyAplicableContent() {
    return '''Estos términos se rigen por las leyes de España. Cualquier disputa relacionada con estos términos o el uso de KickUp será resuelta en los tribunales competentes de Madrid, España.

Si alguna disposición de estos términos se considera inválida o inaplicable, las disposiciones restantes permanecerán en pleno vigor y efecto.

Estos términos constituyen el acuerdo completo entre usted y KickUp con respecto al uso del servicio y reemplazan todos los acuerdos anteriores.''';
  }

  String _getContactoContent() {
    return '''Si tiene preguntas sobre estos Términos y Condiciones, puede contactarnos a través de:

📧 Email: legal@kickup.app
📱 Teléfono: +34 900 123 456
📍 Dirección: Calle del Deporte, 123, 28001 Madrid, España

🕒 Horario de atención:
Lunes a Viernes: 9:00 - 18:00
Sábados: 10:00 - 14:00

También puede utilizar el sistema de soporte dentro de la aplicación para consultas generales. Nos comprometemos a responder a todas las consultas legales en un plazo máximo de 48 horas laborables.''';
  }
}
