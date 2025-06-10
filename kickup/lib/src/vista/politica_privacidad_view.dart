import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';

/** Pantalla que muestra la política de privacidad de la aplicación KickUp.
 * Detalla cómo se recopilan, usan y protegen los datos personales de los usuarios
 * en cumplimiento con las regulaciones de protección de datos.
 */
class PoliticaPrivacidadView extends StatefulWidget {
  const PoliticaPrivacidadView({Key? key}) : super(key: key);

  @override
  State<PoliticaPrivacidadView> createState() => _PoliticaPrivacidadViewState();
}

class _PoliticaPrivacidadViewState extends State<PoliticaPrivacidadView> {
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
        'Política de Privacidad',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        // Botón para descargar política
        IconButton(
          icon: Icon(Icons.download, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            // Implementar funcionalidad de descarga
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad de descarga próximamente'),
              ),
            );
          },
        ),
      ],
    );
  }

  /** Construye el contenido principal con la política */
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
              '1. Información que Recopilamos',
              _getInformacionRecopiladaContent(),
            ),
            _buildSection(
              '2. Cómo Utilizamos su Información',
              _getComoUtilizamosContent(),
            ),
            _buildSection(
              '3. Compartir Información',
              _getCompartirInformacionContent(),
            ),
            _buildSection(
              '4. Seguridad de los Datos',
              _getSeguridadDatosContent(),
            ),
            _buildSection(
              '5. Retención de Datos',
              _getRetencionDatosContent(),
            ),
            _buildSection(
              '6. Sus Derechos',
              _getSusDerechosContent(),
            ),
            _buildSection(
              '7. Cookies y Tecnologías Similares',
              _getCookiesContent(),
            ),
            _buildSection(
              '8. Transferencias Internacionales',
              _getTransferenciasContent(),
            ),
            _buildSection(
              '9. Menores de Edad',
              _getMenoresEdadContent(),
            ),
            _buildSection(
              '10. Cambios en esta Política',
              _getCambiosPoliticaContent(),
            ),
            _buildSection(
              '11. Contacto',
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
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.privacy_tip,
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
                    'Política de Privacidad',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Su privacidad es nuestra prioridad',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Esta política explica cómo recopilamos, usamos y protegemos su información personal cuando utiliza KickUp.',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
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
          Expanded(
            child: Text(
              'Última actualización: 10 de Junio de 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'RGPD Compliant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /** Construye una sección de contenido */
  Widget _buildSection(String title, Widget content) {
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
        content,
      ],
    );
  }

  /** Construye el footer */
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, color: Colors.blue[700], size: 32),
          const SizedBox(height: 12),
          Text(
            'Comprometidos con su Privacidad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cumplimos con las más altas normas de protección de datos y transparencia.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
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
      backgroundColor: Colors.blue,
      child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
    );
  }

  // Métodos que retornan el contenido de cada sección

  Widget _getInformacionRecopiladaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recopilamos diferentes tipos de información para proporcionar y mejorar nuestros servicios:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildDataTypeCard(
          'Información Personal',
          Icons.person,
          Colors.green,
          [
            'Nombre y apellidos',
            'Dirección de correo electrónico',
            'Número de teléfono (opcional)',
            'Foto de perfil',
            'Fecha de nacimiento',
            'Posición de juego preferida',
          ],
        ),
        const SizedBox(height: 12),
        _buildDataTypeCard(
          'Información de Actividad',
          Icons.sports_soccer,
          Colors.orange,
          [
            'Partidos jugados y estadísticas',
            'Equipos a los que pertenece',
            'Reservas de pistas realizadas',
            'Interacciones dentro de la app',
            'Preferencias de notificaciones',
          ],
        ),
        const SizedBox(height: 12),
        _buildDataTypeCard(
          'Información Técnica',
          Icons.phone_android,
          Colors.blue,
          [
            'Dirección IP',
            'Tipo de dispositivo y sistema operativo',
            'Identificadores únicos del dispositivo',
            'Datos de ubicación (para reservas)',
            'Registros de uso de la aplicación',
          ],
        ),
      ],
    );
  }

  Widget _buildDataTypeCard(String title, IconData icon, Color color, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _getComoUtilizamosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilizamos su información personal para los siguientes propósitos legítimos:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildPurposeCard(
          'Prestación del Servicio',
          Icons.sports,
          [
            'Crear y gestionar su cuenta de usuario',
            'Facilitar la organización de equipos y partidos',
            'Procesar reservas de instalaciones deportivas',
            'Mostrar estadísticas y rendimiento',
            'Enviar notificaciones relevantes',
          ],
        ),
        const SizedBox(height: 12),
        _buildPurposeCard(
          'Mejora y Personalización',
          Icons.tune,
          [
            'Personalizar su experiencia en la aplicación',
            'Analizar patrones de uso para mejorar funcionalidades',
            'Desarrollar nuevas características',
            'Optimizar el rendimiento de la aplicación',
          ],
        ),
        const SizedBox(height: 12),
        _buildPurposeCard(
          'Comunicación y Soporte',
          Icons.support_agent,
          [
            'Responder a sus consultas y solicitudes',
            'Proporcionar soporte técnico',
            'Enviar actualizaciones importantes del servicio',
            'Informar sobre cambios en políticas',
          ],
        ),
      ],
    );
  }

  Widget _buildPurposeCard(String title, IconData icon, List<String> purposes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...purposes.map((purpose) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purpose,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _getCompartirInformacionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NO vendemos ni alquilamos su información personal a terceros.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Solo compartimos su información en las siguientes circunstancias limitadas:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildSharingScenario(
          'Con Otros Usuarios',
          Icons.group,
          'Información básica del perfil (nombre, foto) visible para otros miembros de sus equipos.',
        ),
        _buildSharingScenario(
          'Proveedores de Servicios',
          Icons.cloud,
          'Servicios de hosting, análisis y soporte técnico bajo estrictos acuerdos de confidencialidad.',
        ),
        _buildSharingScenario(
          'Cumplimiento Legal',
          Icons.gavel,
          'Cuando sea requerido por ley, orden judicial o para proteger nuestros derechos legales.',
        ),
        _buildSharingScenario(
          'Transferencias Comerciales',
          Icons.business,
          'En caso de fusión, adquisición o venta de activos, con las mismas protecciones de privacidad.',
        ),
      ],
    );
  }

  Widget _buildSharingScenario(String title, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSeguridadDatosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Implementamos múltiples capas de seguridad para proteger su información:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityMeasure(
          'Cifrado de Datos',
          Icons.lock,
          'Todos los datos se cifran en tránsito (TLS 1.3) y en reposo (AES-256).',
        ),
        _buildSecurityMeasure(
          'Autenticación Segura',
          Icons.fingerprint,
          'Autenticación multifactor y gestión segura de sesiones.',
        ),
        _buildSecurityMeasure(
          'Acceso Controlado',
          Icons.admin_panel_settings,
          'Acceso limitado a datos personales solo para personal autorizado.',
        ),
        _buildSecurityMeasure(
          'Monitoreo Continuo',
          Icons.monitor,
          'Supervisión 24/7 para detectar y prevenir accesos no autorizados.',
        ),
        _buildSecurityMeasure(
          'Auditorías Regulares',
          Icons.verified,
          'Evaluaciones periódicas de seguridad por terceros independientes.',
        ),
      ],
    );
  }

  Widget _buildSecurityMeasure(String title, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getRetencionDatosContent() {
    return Text(
      '''Conservamos su información personal solo durante el tiempo necesario para cumplir con los propósitos descritos en esta política:

• Datos de cuenta: Mientras su cuenta esté activa
• Datos de actividad: 3 años después de la última actividad
• Datos de soporte: 2 años después de resolver la consulta
• Datos de marketing: Hasta que retire su consentimiento
• Datos legales: Según requieran las leyes aplicables

Cuando elimine su cuenta, procederemos a eliminar o anonimizar sus datos personales dentro de 30 días, excepto cuando debamos conservar cierta información por obligaciones legales.

Puede solicitar la eliminación anticipada de sus datos contactándonos directamente.''',
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary(context),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _getSusDerechosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bajo el RGPD y otras leyes de protección de datos, usted tiene los siguientes derechos:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildRightCard('Acceso', Icons.visibility, 'Solicitar una copia de sus datos personales'),
        _buildRightCard('Rectificación', Icons.edit, 'Corregir datos inexactos o incompletos'),
        _buildRightCard('Eliminación', Icons.delete, 'Solicitar la eliminación de sus datos'),
        _buildRightCard('Portabilidad', Icons.import_export, 'Recibir sus datos en formato estructurado'),
        _buildRightCard('Oposición', Icons.block, 'Oponerse al procesamiento de sus datos'),
        _buildRightCard('Limitación', Icons.pause, 'Restringir el procesamiento en ciertas circunstancias'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Para ejercer estos derechos, contáctenos en privacy@kickup.app',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightCard(String title, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCookiesContent() {
    return Text(
      '''KickUp utiliza tecnologías similares a cookies para mejorar su experiencia:

COOKIES ESENCIALES (Siempre activas)
• Autenticación y seguridad de sesión
• Preferencias de idioma y configuración
• Funcionalidad básica de la aplicación

COOKIES ANALÍTICAS (Opcionales)
• Análisis de uso y rendimiento
• Identificación de errores y problemas
• Mejora de funcionalidades

COOKIES DE PERSONALIZACIÓN (Opcionales)
• Recordar sus preferencias
• Personalizar contenido y recomendaciones
• Optimizar la experiencia de usuario

Puede gestionar sus preferencias de cookies desde la configuración de la aplicación. Desactivar ciertas cookies puede afectar la funcionalidad del servicio.''',
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary(context),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _getTransferenciasContent() {
    return Text(
      '''Sus datos personales pueden ser transferidos y procesados en países fuera del Espacio Económico Europeo (EEE) donde operan nuestros proveedores de servicios.

GARANTÍAS DE PROTECCIÓN:
• Cláusulas contractuales estándar aprobadas por la UE
• Certificaciones de adecuación de protección de datos
• Medidas técnicas y organizativas apropiadas

UBICACIONES PRINCIPALES:
• Servidores en la Unión Europea (datos principales)
• Estados Unidos (servicios de análisis y soporte)
• Canadá (servicios de backup y recuperación)

Todas las transferencias cumplen con los requisitos del RGPD y garantizan un nivel de protección equivalente al proporcionado en la UE.''',
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary(context),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _getMenoresEdadContent() {
    return Text(
      '''KickUp está diseñado para usuarios de 13 años en adelante. No recopilamos intencionalmente información personal de menores de 13 años.

USUARIOS DE 13-17 AÑOS:
• Requieren consentimiento parental verificable
• Funcionalidades limitadas de privacidad adicionales
• Supervisión parental disponible

VERIFICACIÓN DE EDAD:
• Solicitamos fecha de nacimiento durante el registro
• Verificación adicional puede ser requerida
• Cuentas de menores pueden ser suspendidas hasta verificación

Si descubrimos que hemos recopilado información de un menor de 13 años sin consentimiento parental, eliminaremos inmediatamente dicha información.

Los padres pueden contactarnos para revisar, modificar o eliminar la información de sus hijos.''',
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary(context),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _getCambiosPoliticaContent() {
    return Text(
      '''Podemos actualizar esta Política de Privacidad ocasionalmente para reflejar cambios en nuestras prácticas o por otros motivos operativos, legales o regulatorios.

NOTIFICACIÓN DE CAMBIOS:
• Notificación dentro de la aplicación
• Email a su dirección registrada
• Aviso en nuestro sitio web
• 30 días de antelación para cambios significativos

CAMBIOS MENORES:
• Correcciones tipográficas
• Actualizaciones de información de contacto
• Clarificaciones que no afecten sus derechos

CAMBIOS SIGNIFICATIVOS:
• Nuevos usos de datos personales
• Cambios en bases legales de procesamiento
• Nuevas transferencias internacionales

Le recomendamos revisar esta política periódicamente. El uso continuado del servicio después de los cambios constituye su aceptación de la política actualizada.''',
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary(context),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _getContactoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Para cualquier consulta sobre esta Política de Privacidad o el tratamiento de sus datos personales:',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          'Delegado de Protección de Datos',
          Icons.person_pin,
          [
            '📧 privacy@kickup.app',
            '📱 +34 900 123 456',
            '📍 Calle del Deporte, 123, 28001 Madrid',
          ],
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          'Autoridad de Control',
          Icons.account_balance,
          [
            '🏛️ Agencia Española de Protección de Datos',
            '📧 consultas@aepd.es',
            '🌐 www.aepd.es',
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tiempo de respuesta: Máximo 30 días para consultas sobre privacidad',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(String title, IconData icon, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis, // Opcional
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}
