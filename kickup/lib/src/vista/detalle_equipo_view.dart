import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/pista_view.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/** Vista detallada de un equipo deportivo.
 * Muestra información completa del equipo, lista de jugadores,
 * y permite unirse/abandonar el equipo. Incluye funcionalidad
 * para cambiar el logo del equipo y un tutorial interactivo.
 */
class DetalleEquipoView extends StatefulWidget {
  /** ID del equipo a mostrar */
  final String equipoId;
  
  /** ID del usuario actual */
  final String userId;
  
  /** Indica si se debe mostrar el tutorial */
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
  EquipoModel? _equipo;
  bool _isLoading = true;
  bool _esMiembro = false;
  bool _procesandoSolicitud = false;
  bool _isAdmin = false; 

  // Referencias para el tutorial
  final GlobalKey _unirseKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _cargarEquipo();

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
      onFinish: () {
        // Al terminar, navega a PistasView con tutorial
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PistasView(showTutorial: true),
          ),
        );
        return false;
      },
      onSkip: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PistasView(showTutorial: true),
          ),
        );
        return false;
      },
    ).show(context: context);
  }

  /** Carga la información del equipo y determina el rol del usuario.
   * Obtiene datos del equipo desde Firestore y verifica si el usuario
   * actual es miembro del equipo o administrador.
   */
  Future<void> _cargarEquipo() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Obtener datos frescos directamente de Firestore
    final equipoDoc = await FirebaseFirestore.instance
        .collection('equipos')
        .doc(widget.equipoId)
        .get();

    if (equipoDoc.exists) {
      final data = equipoDoc.data() as Map<String, dynamic>;
      
      // Crear el modelo del equipo
      final equipo = EquipoModel.fromJson({
        'id': equipoDoc.id,
        ...data,
      });

      // Determinar el rol del usuario en el equipo
      final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
      final esMiembro = jugadoresIds.contains(widget.userId);
      final isAdmin = await _equipoController.esUsuarioAdmin(widget.userId);

      if (mounted) {
        setState(() {
          _equipo = equipo;
          _esMiembro = esMiembro;
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el equipo')),
        );
        Navigator.pop(context);
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  /** Permite al usuario abandonar el equipo.
   * Muestra un diálogo de confirmación y actualiza Firestore
   * para eliminar al usuario de la lista de jugadores.
   */
Future<void> _abandonarEquipo() async {
  if (_procesandoSolicitud) return;

  // Mostrar diálogo de confirmación
  final bool? confirmar = await _mostrarDialogoConfirmacion();
  if (confirmar != true) return;

  setState(() {
    _procesandoSolicitud = true;
  });

  try {
    final resultado = await _equipoController.abandonarEquipo(
        widget.equipoId, widget.userId);

    if (resultado && mounted) {
      // Actualizar Firestore inmediatamente para forzar la actualización de los StreamBuilders
      await FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId)
          .update({
        'jugadoresIds': FieldValue.arrayRemove([widget.userId]),
        'jugadores': FieldValue.arrayRemove([
          // Esto se manejará en el controlador, pero forzamos la actualización aquí
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Actualizar el estado local inmediatamente
      setState(() {
        _esMiembro = false;
        _procesandoSolicitud = false;
      });

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

      // Recargar datos para asegurar consistencia
      await _cargarEquipo();
    } else if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo procesar la solicitud')),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

/** Permite al usuario unirse al equipo.
 * Actualiza Firestore para añadir al usuario a la lista de jugadores
 * y muestra una notificación de éxito.
 */
Future<void> _unirseAlEquipo() async {
  if (_procesandoSolicitud) return;

  setState(() {
    _procesandoSolicitud = true;
  });

  try {
    final resultado =
        await _equipoController.unirseEquipo(widget.equipoId, widget.userId);

    if (resultado && mounted) {
      // Obtener datos del usuario para la actualización
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Actualizar Firestore inmediatamente
        await FirebaseFirestore.instance
            .collection('equipos')
            .doc(widget.equipoId)
            .update({
          'jugadoresIds': FieldValue.arrayUnion([widget.userId]),
          'jugadores': FieldValue.arrayUnion([{
            'id': widget.userId,
            'nombre': userData['nombre'] ?? '',
            'apellidos': userData['apellidos'] ?? '',
            'posicion': userData['posicion'] ?? 'Sin posición',
            'puntos': userData['puntos'] ?? 15,
          }]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Actualizar el estado local inmediatamente
      setState(() {
        _esMiembro = true;
        _procesandoSolicitud = false;
      });

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

      // Recargar datos para asegurar consistencia
      await _cargarEquipo();
    } else if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo procesar la solicitud')),
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _procesandoSolicitud = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  /** Muestra un diálogo de confirmación para abandonar el equipo.
   * @return true si el usuario confirma, false en caso contrario
   */
  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content:
              const Text('¿Estás seguro de que quieres abandonar este equipo?'),
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

  /** Muestra opciones para cambiar el logo del equipo.
   * Presenta un modal con opciones para seleccionar imagen
   * desde la galería o tomar una foto con la cámara.
   */
  Future<void> _mostrarOpcionesCambiarLogo() async {
    // Permitir a cualquier miembro del equipo cambiar el logo
    if (!_esMiembro) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar para el modal
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cambiar logo del equipo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Galería'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.green),
                  title: const Text('Cámara'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _cambiarLogo(source);
    }
  }

  /** Cambia el logo del equipo usando la fuente especificada.
   * Procesa la imagen seleccionada, la sube a Firebase Storage
   * y actualiza la referencia en Firestore.
   * @param source Fuente de la imagen (galería o cámara)
   */
  Future<void> _cambiarLogo(ImageSource source) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _procesandoSolicitud = true;
      });

      // Mostrar progreso de subida
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

      final fileBytes = await pickedFile.readAsBytes();
      final fileName =
          '${widget.equipoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Subir archivo a Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('logos_equipos').child(fileName);

      await storageRef.putData(fileBytes);
      final downloadUrl = await storageRef.getDownloadURL();

      // Actualizar URL en Firestore
      await FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId)
          .update({
        'logoUrl': downloadUrl,
        'logoUpdatedAt': FieldValue.serverTimestamp(),
        'logoUpdatedBy': widget.userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar logo: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetalleEquipo(),
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
        'Detalle del Equipo',
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineMedium?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /** Construye el contenido principal de la pantalla */
  Widget _buildDetalleEquipo() {
    if (_equipo == null) {
      return const Center(child: Text('No se encontró información del equipo'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(), // Nombre del equipo
          const SizedBox(height: 20),
          _buildLogoSection(), // Logo del equipo
          const SizedBox(height: 30),
          _buildPlayersSection(), // Lista de jugadores
          const SizedBox(height: 15),
          _buildInfoSection(), // Información del equipo
          const SizedBox(height: 30),
          _buildActionButton(), // Botón de acción
        ],
      ),
    );
  }

  /** Construye el header con el nombre del equipo */
  Widget _buildHeader() {
    return Center(
      child: Text(
        _equipo!.nombre,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /** Construye la sección del logo con funcionalidad de cambio.
   * Muestra el logo del equipo y permite a los miembros cambiarlo.
   */
  Widget _buildLogoSection() {
    return Center(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .doc(widget.equipoId)
            .snapshots(),
        builder: (context, snapshot) {
          String? logoUrl;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            logoUrl = data['logoUrl'] as String?;
          }

          return GestureDetector(
            // Permitir a cualquier miembro del equipo cambiar el logo
            onTap: _esMiembro ? _mostrarOpcionesCambiarLogo : null,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                // Mostrar borde especial para cualquier miembro
                border: _esMiembro
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
              ),
              child: Stack(
                children: [
                  // Imagen del logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 150,
                      height: 150,
                      child: (logoUrl != null && logoUrl.isNotEmpty)
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultLogo();
                              },
                            )
                          : _buildDefaultLogo(),
                    ),
                  ),
                  // Mostrar indicador de edición para cualquier miembro
                  if (_esMiembro)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withAlpha(76), 
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
                    ),
                ],
              ),
            ),
          );
        },
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

  /** Construye la sección de jugadores con lista actualizada en tiempo real */
  Widget _buildPlayersSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final jugadoresRaw =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        // Eliminar duplicados por ID
        final jugadores = <String, Map<String, dynamic>>{};
        for (var jugador in jugadoresRaw) {
          final id = jugador['id'];
          if (id != null && !jugadores.containsKey(id)) {
            jugadores[id] = jugador;
          }
        }

        if (jugadores.isEmpty) {
          return const Text('No hay jugadores inscritos.');
        }

        final jugadoresList = jugadores.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jugadores (${jugadoresList.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jugadoresList.length,
              itemBuilder: (context, index) {
                final jugador = jugadoresList[index];
                return _buildPlayerTile(jugador);
              },
            ),
          ],
        );
      },
    );
  }

  /** Construye un tile individual de jugador con avatar y datos */
  Widget _buildPlayerTile(Map<String, dynamic> jugador) {
    final jugadorId = jugador['id'] as String?;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(jugadorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String? imageUrl;
        int puntos = jugador['puntos'] ?? 15; // Valor por defecto del array
        
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          imageUrl = userData['profileImageUrl'] as String?;
          // Usar los puntos actualizados de la colección usuarios
          puntos = userData['puntos'] ?? 15;
        }

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
            '${jugador['nombre'] ?? ''} ${jugador['apellidos'] ?? ''}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            jugador['posicion'] ?? 'Sin posición',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            '$puntos pts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  /** Construye la sección de información del equipo */
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Nivel', _equipo!.nivel.toString()),
        const SizedBox(height: 25),
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _equipo!.descripcion ?? 'Sin descripción',
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

  /** Construye el botón de acción (Unirse o Abandonar).
   * Muestra un botón diferente según si el usuario es miembro o no.
   */
  Widget _buildActionButton() {
    if (_isAdmin) return const SizedBox.shrink(); // No mostrar botón para admins

    if (_esMiembro) {
      return Center(
        child: ElevatedButton.icon(
          key: _unirseKey, // Key para el tutorial
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Abandonar equipo'),
          onPressed: _abandonarEquipo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else {
      return Center(
        child: ElevatedButton.icon(
          key: _unirseKey, // Key para el tutorial
          icon: const Icon(Icons.group_add),
          label: const Text('Unirse al equipo'),
          onPressed: _unirseAlEquipo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
  }
}
