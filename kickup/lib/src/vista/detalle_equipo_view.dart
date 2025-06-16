import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/pista_view.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/** Vista detallada de un equipo deportivo con funcionalidades completas.
 * Proporciona información en tiempo real del equipo, gestión de miembros,
 * cambio de logo, tutorial interactivo y controles administrativos.
 * Utiliza StreamBuilder para actualizaciones automáticas y manejo
 * robusto de permisos para operaciones críticas como eliminación.
 */
class DetalleEquipoView extends StatefulWidget {
  /** ID del equipo a mostrar */
  final String equipoId;
  
  /** ID del usuario actual */
  final String userId;
  
  /** Indica si se debe mostrar el tutorial interactivo */
  final bool showTutorial;

  const DetalleEquipoView({
    Key? key,
    required this.equipoId,
    required this.userId,
    this.showTutorial = false, 
  }) : super(key: key);

  @override
  State<DetalleEquipoView> createState() => _DetalleEquipoViewState();
}

class _DetalleEquipoViewState extends State<DetalleEquipoView> {
  // Controlador para manejar la lógica de equipos
  final EquipoController _equipoController = EquipoController();
  
  // Variables de estado principales
  bool _procesandoSolicitud = false;
  bool _isAdmin = false;

  // Referencias para el sistema de tutorial
  final GlobalKey _unirseKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _inicializarVista();
  }

  /** Inicializa la vista verificando permisos y configurando tutorial */
  void _inicializarVista() {
    _verificarAdmin();

    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  /** Verifica si el usuario actual tiene permisos de administrador.
   * Los administradores pueden eliminar cualquier equipo y tienen
   * acceso a funcionalidades adicionales de gestión.
   */
  Future<void> _verificarAdmin() async {
    try {
      final isAdmin = await _equipoController.esUsuarioAdmin(widget.userId);
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      print('Error al verificar permisos de admin: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  /** Muestra el tutorial interactivo para guiar a nuevos usuarios.
   * Utiliza TutorialCoachMark para resaltar elementos importantes
   * y guiar al usuario a través de las funcionalidades principales.
   */
  void _showTutorial() {
    targets = [
      TargetFocus(
        identify: "unirse",
        keyTarget: _unirseKey,
        contents: [
          TargetContent(
            child: const Text(
              "¡Únete al equipo aquí!",
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
      onFinish: () => _navegarAPistasConTutorial(),
      onSkip: () => _navegarAPistasConTutorial(),
    ).show(context: context);
  }

  /** Navega a la vista de pistas con tutorial activado */
  bool _navegarAPistasConTutorial() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PistasView(showTutorial: true),
      ),
    );
    return false;
  }

  /** Elimina el equipo con verificación exhaustiva de permisos.
   * Verifica si el usuario es administrador, creador del equipo,
   * o el primer jugador (para equipos antiguos sin creadorId).
   * Incluye manejo robusto de errores y feedback al usuario.
   */
  Future<void> _eliminarEquipo() async {
    if (_procesandoSolicitud) return;

    final bool? confirmar = await _mostrarDialogoConfirmacionEliminar();
    if (confirmar != true) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      await _verificarPermisosEliminacion();
      final resultado = await _ejecutarEliminacionEquipo();
      
      if (resultado && mounted) {
        _mostrarExitoEliminacion();
        Navigator.pop(context, true);
      } else if (mounted) {
        throw Exception('No se pudo eliminar el equipo');
      }
    } catch (e) {
      _manejarErrorEliminacion(e);
    } finally {
      _finalizarProcesoEliminacion();
    }
  }

  /** Verifica los permisos necesarios para eliminar el equipo */
  Future<void> _verificarPermisosEliminacion() async {
    final esAdmin = await _equipoController.esUsuarioAdmin(widget.userId);
    final esCreador = await _equipoController.esCreadorDelEquipo(widget.equipoId, widget.userId);
    
    print('Debug - Es admin: $esAdmin, Es creador: $esCreador');

    if (!esAdmin && !esCreador) {
      await _manejarEquipoSinCreador();
    }
  }

  /** Maneja equipos antiguos que no tienen creadorId definido */
  Future<void> _manejarEquipoSinCreador() async {
    final equipoDoc = await FirebaseFirestore.instance
        .collection('equipos')
        .doc(widget.equipoId)
        .get();
        
    if (equipoDoc.exists) {
      final data = equipoDoc.data() as Map<String, dynamic>;
      final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
      
      // Si es el primer jugador y no hay creadorId, asumimos que es el creador
      if (jugadoresIds.isNotEmpty && jugadoresIds.first == widget.userId) {
        await _asignarCreadorId();
      } else {
        throw Exception('No tienes permisos para eliminar este equipo');
      }
    }
  }

  /** Asigna el creadorId al usuario actual para equipos antiguos */
  Future<void> _asignarCreadorId() async {
    await FirebaseFirestore.instance
        .collection('equipos')
        .doc(widget.equipoId)
        .update({'creadorId': widget.userId});
  }

  /** Ejecuta la eliminación del equipo */
  Future<bool> _ejecutarEliminacionEquipo() async {
    return await _equipoController.eliminarEquipo(widget.equipoId, widget.userId);
  }

  /** Muestra mensaje de éxito tras eliminar el equipo */
  void _mostrarExitoEliminacion() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Equipo eliminado correctamente'),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /** Maneja errores durante la eliminación del equipo */
  void _manejarErrorEliminacion(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /** Finaliza el proceso de eliminación restaurando el estado */
  void _finalizarProcesoEliminacion() {
    if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
    }
  }

  /** Muestra diálogo de confirmación para eliminar el equipo */
  Future<bool?> _mostrarDialogoConfirmacionEliminar() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar equipo'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar este equipo?\n\n'
            'Esta acción no se puede deshacer y todos los jugadores serán removidos del equipo.'
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
        );
      },
    );
  }

  /** Procesa la solicitud para abandonar el equipo.
   * Incluye confirmación del usuario, manejo de errores
   * y feedback visual durante el proceso.
   */
  Future<void> _abandonarEquipo() async {
    if (_procesandoSolicitud) return;

    final bool? confirmar = await _mostrarDialogoConfirmacion();
    if (confirmar != true) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final resultado = await _equipoController.abandonarEquipo(
          widget.equipoId, widget.userId);

      if (resultado && mounted) {
        _mostrarExitoAbandonar();
      } else if (mounted) {
        _mostrarErrorGenerico();
      }
    } catch (e) {
      _mostrarErrorEspecifico(e);
    } finally {
      _finalizarProceso();
    }
  }

  /** Procesa la solicitud para unirse al equipo.
   * Maneja la lógica de inscripción con validaciones
   * y feedback apropiado al usuario.
   */
  Future<void> _unirseAlEquipo() async {
    if (_procesandoSolicitud) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final resultado = await _equipoController.unirseEquipo(widget.equipoId, widget.userId);

      if (resultado && mounted) {
        _mostrarExitoUnirse();
      } else if (mounted) {
        _mostrarErrorGenerico();
      }
    } catch (e) {
      _mostrarErrorEspecifico(e);
    } finally {
      _finalizarProceso();
    }
  }

  /** Muestra mensaje de éxito al abandonar el equipo */
  void _mostrarExitoAbandonar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Has abandonado el equipo correctamente'),
        backgroundColor: const Color.fromARGB(255, 224, 45, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /** Muestra mensaje de éxito al unirse al equipo */
  void _mostrarExitoUnirse() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Te has unido al equipo correctamente'),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /** Muestra mensaje de error genérico */
  void _mostrarErrorGenerico() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo procesar la solicitud'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /** Muestra mensaje de error específico */
  void _mostrarErrorEspecifico(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /** Finaliza cualquier proceso restaurando el estado de carga */
  void _finalizarProceso() {
    if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
    }
  }

  /** Muestra diálogo de confirmación para abandonar el equipo */
  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Estás seguro de que quieres abandonar este equipo?'),
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
        );
      },
    );
  }

  /** Muestra las opciones disponibles para cambiar el logo del equipo.
   * Presenta un bottom sheet con opciones de galería y cámara
   * para seleccionar una nueva imagen de logo.
   */
  Future<void> _mostrarOpcionesCambiarLogo() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => _construirBottomSheetLogo(),
    );

    if (source != null) {
      await _cambiarLogo(source);
    }
  }

  /** Construye el bottom sheet para seleccionar fuente de imagen */
  Widget _construirBottomSheetLogo() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _construirIndicadorBottomSheet(),
            const SizedBox(height: 20),
            const Text(
              'Cambiar logo del equipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _construirOpcionGaleria(),
            _construirOpcionCamara(),
          ],
        ),
      ),
    );
  }

  /** Construye el indicador visual del bottom sheet */
  Widget _construirIndicadorBottomSheet() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /** Construye la opción de galería */
  Widget _construirOpcionGaleria() {
    return ListTile(
      leading: const Icon(Icons.photo_library, color: Colors.blue),
      title: const Text('Galería'),
      onTap: () => Navigator.of(context).pop(ImageSource.gallery),
    );
  }

  /** Construye la opción de cámara */
  Widget _construirOpcionCamara() {
    return ListTile(
      leading: const Icon(Icons.photo_camera, color: Colors.green),
      title: const Text('Cámara'),
      onTap: () => Navigator.of(context).pop(ImageSource.camera),
    );
  }

  /** Cambia el logo del equipo utilizando la fuente especificada.
   * Maneja todo el proceso: selección de imagen, compresión,
   * subida a Firebase Storage y actualización en Firestore.
   * @param source Fuente de la imagen (galería o cámara)
   */
  Future<void> _cambiarLogo(ImageSource source) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await _seleccionarImagen(picker, source);
      if (pickedFile == null) return;

      setState(() {
        _procesandoSolicitud = true;
      });

      _mostrarIndicadorSubida();
      
      final downloadUrl = await _subirImagenAStorage(pickedFile);
      await _actualizarLogoEnFirestore(downloadUrl);
      
      _mostrarExitoActualizacionLogo();
    } catch (e) {
      _manejarErrorActualizacionLogo(e);
    } finally {
      _finalizarActualizacionLogo();
    }
  }

  /** Selecciona una imagen con configuraciones optimizadas */
  Future<XFile?> _seleccionarImagen(ImagePicker picker, ImageSource source) async {
    return await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  /** Muestra indicador de progreso durante la subida */
  void _mostrarIndicadorSubida() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Subiendo logo...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }
  }

  /** Sube la imagen a Firebase Storage y retorna la URL de descarga */
  Future<String> _subirImagenAStorage(XFile pickedFile) async {
    final fileBytes = await pickedFile.readAsBytes();
    final fileName = '${widget.equipoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('logos_equipos')
        .child(fileName);
    
    await storageRef.putData(fileBytes);
    return await storageRef.getDownloadURL();
  }

  /** Actualiza la información del logo en Firestore */
  Future<void> _actualizarLogoEnFirestore(String downloadUrl) async {
    await FirebaseFirestore.instance
        .collection('equipos')
        .doc(widget.equipoId)
        .update({
      'logoUrl': downloadUrl,
      'logoUpdatedAt': FieldValue.serverTimestamp(),
      'logoUpdatedBy': widget.userId,
    });
  }

  /** Muestra mensaje de éxito tras actualizar el logo */
  void _mostrarExitoActualizacionLogo() {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /** Maneja errores durante la actualización del logo */
  void _manejarErrorActualizacionLogo(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar logo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /** Finaliza el proceso de actualización del logo */
  void _finalizarActualizacionLogo() {
    if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: _construirStreamBuilder(),
    );
  }

  /** Construye el StreamBuilder para actualizaciones en tiempo real.
   * Escucha cambios en el documento del equipo y actualiza
   * automáticamente la interfaz cuando hay modificaciones.
   */
  Widget _construirStreamBuilder() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _construirPantallaCarga();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _construirPantallaError();
        }

        return _construirContenidoPrincipal(snapshot);
      },
    );
  }

  /** Construye la pantalla de carga */
  Widget _construirPantallaCarga() {
    return Scaffold(
      appBar: _buildAppBar(false, false),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  /** Construye la pantalla de error cuando no se encuentra el equipo */
  Widget _construirPantallaError() {
    return Scaffold(
      appBar: _buildAppBar(false, false),
      body: const Center(
        child: Text('No se encontró información del equipo'),
      ),
    );
  }

  /** Construye el contenido principal con los datos del equipo */
  Widget _construirContenidoPrincipal(AsyncSnapshot<DocumentSnapshot> snapshot) {
    final data = snapshot.data!.data() as Map<String, dynamic>;
    final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
    final esMiembro = jugadoresIds.contains(widget.userId);
    
    // Verificar si es creador del equipo
    final creadorId = data['creadorId'] as String?;
    final esCreador = _determinarSiEsCreador(creadorId, jugadoresIds);

    final equipo = EquipoModel.fromJson({
      'id': snapshot.data!.id,
      ...data,
    });

    return Scaffold(
      appBar: _buildAppBar(esCreador, _isAdmin),
      body: _buildDetalleEquipo(equipo, esMiembro, data),
    );
  }

  /** Determina si el usuario actual es el creador del equipo */
  bool _determinarSiEsCreador(String? creadorId, List<String> jugadoresIds) {
    return creadorId == widget.userId || 
           (creadorId == null && jugadoresIds.isNotEmpty && jugadoresIds.first == widget.userId);
  }

  /** Construye el AppBar con opciones dinámicas según permisos.
   * Muestra opciones de eliminación solo para creadores y administradores.
   * @param esCreador Si el usuario es creador del equipo
   * @param isAdmin Si el usuario es administrador
   */
  PreferredSizeWidget _buildAppBar(bool esCreador, bool isAdmin) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Detalle del Equipo',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: (esCreador || isAdmin) ? [_construirMenuOpciones()] : null,
    );
  }

  /** Construye el menú de opciones para creadores y administradores */
  Widget _construirMenuOpciones() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).iconTheme.color,
      ),
      onSelected: (value) {
        if (value == 'eliminar') {
          _eliminarEquipo();
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
                'Eliminar equipo',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /** Construye el contenido detallado del equipo.
   * Organiza toda la información del equipo en secciones
   * claramente definidas con datos actualizados en tiempo real.
   * @param equipo Modelo del equipo con toda la información
   * @param esMiembro Si el usuario actual es miembro del equipo
   * @param data Datos raw del equipo desde Firestore
   */
  Widget _buildDetalleEquipo(EquipoModel equipo, bool esMiembro, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(equipo),
          const SizedBox(height: 20),
          _buildLogoSection(esMiembro, data),
          const SizedBox(height: 30),
          _buildPlayersSection(data),
          const SizedBox(height: 15),
          _buildInfoSection(equipo),
          const SizedBox(height: 30),
          _buildActionButton(esMiembro),
        ],
      ),
    );
  }

  /** Construye el encabezado con el nombre del equipo */
  Widget _buildHeader(EquipoModel equipo) {
    return Center(
      child: Text(
        equipo.nombre,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /** Construye la sección del logo con funcionalidad de cambio.
   * Permite a los miembros del equipo cambiar el logo tocando la imagen.
   * Incluye indicador visual para mostrar que es interactivo.
   * @param esMiembro Si el usuario puede cambiar el logo
   * @param data Datos del equipo incluyendo URL del logo
   */
  Widget _buildLogoSection(bool esMiembro, Map<String, dynamic> data) {
    final logoUrl = data['logoUrl'] as String?;

    return Center(
      child: GestureDetector(
        onTap: esMiembro ? _mostrarOpcionesCambiarLogo : null,
        child: Container(
          width: 150,
          height: 150,
          decoration: _construirDecoracionLogo(esMiembro),
          child: Stack(
            children: [
              _construirImagenLogo(logoUrl),
              if (esMiembro) _construirIconoCamara(),
            ],
          ),
        ),
      ),
    );
  }

  /** Construye la decoración del contenedor del logo */
  BoxDecoration _construirDecoracionLogo(bool esMiembro) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: esMiembro
          ? Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            )
          : Border.all(color: Colors.grey[300]!, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(25), 
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /** Construye la imagen del logo con manejo de errores */
  Widget _construirImagenLogo(String? logoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 150,
        height: 150,
        child: (logoUrl != null && logoUrl.isNotEmpty)
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
              )
            : _buildDefaultLogo(),
      ),
    );
  }

  /** Construye el icono de cámara para miembros del equipo */
  Widget _construirIconoCamara() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(76), 
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  /** Construye el logo por defecto cuando no hay imagen */
  Widget _buildDefaultLogo() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.sports_soccer,
        size: 70,
        color: Colors.grey,
      ),
    );
  }

  /** Construye la sección de jugadores con eliminación de duplicados.
   * Muestra la lista de jugadores del equipo con información actualizada
   * en tiempo real y manejo de duplicados por ID.
   * @param data Datos del equipo incluyendo lista de jugadores
   */
  Widget _buildPlayersSection(Map<String, dynamic> data) {
    final jugadoresRaw = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

    // Eliminar duplicados por ID para evitar inconsistencias
    final jugadores = _eliminarJugadoresDuplicados(jugadoresRaw);

    if (jugadores.isEmpty) {
      return const Text('No hay jugadores inscritos.');
    }

    final jugadoresList = jugadores.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirTituloJugadores(jugadoresList.length),
        const SizedBox(height: 10),
        _construirListaJugadores(jugadoresList),
      ],
    );
  }

  /** Elimina jugadores duplicados basándose en su ID */
  Map<String, Map<String, dynamic>> _eliminarJugadoresDuplicados(
      List<Map<String, dynamic>> jugadoresRaw) {
    final jugadores = <String, Map<String, dynamic>>{};
    for (var jugador in jugadoresRaw) {
      final id = jugador['id'];
      if (id != null && !jugadores.containsKey(id)) {
        jugadores[id] = jugador;
      }
    }
    return jugadores;
  }

  /** Construye el título de la sección de jugadores */
  Widget _construirTituloJugadores(int cantidad) {
    return Text(
      'Jugadores ($cantidad)',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /** Construye la lista de jugadores */
  Widget _construirListaJugadores(List<Map<String, dynamic>> jugadoresList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jugadoresList.length,
      itemBuilder: (context, index) {
        final jugador = jugadoresList[index];
        return _buildPlayerTile(jugador);
      },
    );
  }

  /** Construye un tile individual de jugador con información actualizada.
   * Utiliza StreamBuilder para obtener datos actualizados del usuario
   * incluyendo imagen de perfil y puntuación actual.
   * @param jugador Datos básicos del jugador desde el equipo
   */
  Widget _buildPlayerTile(Map<String, dynamic> jugador) {
    final jugadorId = jugador['id'] as String?;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(jugadorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final datosActualizados = _obtenerDatosActualizadosJugador(jugador, userSnapshot);
        
        return ListTile(
          leading: _construirAvatarJugador(datosActualizados['imageUrl']),
          title: _construirNombreJugador(jugador),
          subtitle: _construirPosicionJugador(jugador),
          trailing: _construirPuntosJugador(datosActualizados['puntos']),
        );
      },
    );
  }

  /** Obtiene los datos actualizados del jugador combinando información local y remota */
  Map<String, dynamic> _obtenerDatosActualizadosJugador(
      Map<String, dynamic> jugador, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
    String? imageUrl;
    int puntos = jugador['puntos'] ?? 15;
    
    if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
      imageUrl = userData['profileImageUrl'] as String?;
      puntos = userData['puntos'] ?? 15;
    }

    return {
      'imageUrl': imageUrl,
      'puntos': puntos,
    };
  }

  /** Construye el avatar del jugador con imagen de perfil */
  Widget _construirAvatarJugador(String? imageUrl) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  /** Construye el nombre completo del jugador */
  Widget _construirNombreJugador(Map<String, dynamic> jugador) {
    return Text(
      '${jugador['nombre'] ?? ''} ${jugador['apellidos'] ?? ''}',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /** Construye la posición del jugador */
  Widget _construirPosicionJugador(Map<String, dynamic> jugador) {
    return Text(
      jugador['posicion'] ?? 'Sin posición',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  /** Construye la puntuación del jugador */
  Widget _construirPuntosJugador(int puntos) {
    return Text(
      '$puntos pts',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /** Construye la sección de información adicional del equipo */
  Widget _buildInfoSection(EquipoModel equipo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Nivel', equipo.nivel.toString()),
        const SizedBox(height: 25),
        _construirSeccionDescripcion(equipo),
      ],
    );
  }

  /** Construye la sección de descripción del equipo */
  Widget _construirSeccionDescripcion(EquipoModel equipo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          equipo.descripcion ?? 'Sin descripción',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /** Construye una fila de información con etiqueta y valor */
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /** Construye el botón de acción que se actualiza automáticamente.
   * Cambia dinámicamente entre "Unirse" y "Abandonar" según
   * el estado de membresía del usuario. Los administradores
   * no ven este botón ya que tienen controles separados.
   * @param esMiembro Si el usuario actual es miembro del equipo
   */
  Widget _buildActionButton(bool esMiembro) {
    if (_isAdmin) return const SizedBox.shrink();

    if (esMiembro) {
      return _construirBotonAbandonar();
    } else {
      return _construirBotonUnirse();
    }
  }

  /** Construye el botón para abandonar el equipo */
  Widget _construirBotonAbandonar() {
    return Center(
      child: ElevatedButton.icon(
        key: _unirseKey,
        icon: _construirIconoBoton(),
        label: Text(_procesandoSolicitud ? 'Procesando...' : 'Abandonar equipo'),
        onPressed: _procesandoSolicitud ? null : _abandonarEquipo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /** Construye el botón para unirse al equipo */
  Widget _construirBotonUnirse() {
    return Center(
      child: ElevatedButton.icon(
        key: _unirseKey,
        icon: _construirIconoBoton(),
        label: Text(_procesandoSolicitud ? 'Procesando...' : 'Unirse al equipo'),
        onPressed: _procesandoSolicitud ? null : _unirseAlEquipo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /** Construye el icono apropiado para el botón según el estado */
  Widget _construirIconoBoton() {
    if (_procesandoSolicitud) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    // Determinar si es miembro basándose en el contexto del botón
    return const Icon(Icons.group_add); // Por defecto, icono de unirse
  }
}