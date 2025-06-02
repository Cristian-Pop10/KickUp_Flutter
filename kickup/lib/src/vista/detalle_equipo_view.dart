import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DetalleEquipoView extends StatefulWidget {
  final String equipoId;
  final String userId;

  const DetalleEquipoView({
    Key? key,
    required this.equipoId,
    required this.userId,
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
  bool _esCreador = false;
  bool _procesandoSolicitud = false;

  @override
  void initState() {
    super.initState();
    _cargarEquipo();
  }

  /// Carga la información del equipo y determina el rol del usuario
  Future<void> _cargarEquipo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final equipo =
          await _equipoController.obtenerEquipoPorId(widget.equipoId);

      if (equipo != null) {
        // Determinar el rol del usuario en el equipo
        final esMiembro = equipo.jugadoresIds.contains(widget.userId);
        final esCreador = equipo.creadorId == widget.userId;

        if (mounted) {
          setState(() {
            _equipo = equipo;
            _esMiembro = esMiembro;
            _esCreador = esCreador;
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

  // Corregir el método _abandonarEquipo() para actualizar el estado inmediatamente
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
        // Actualizar el estado inmediatamente sin esperar a recargar
        setState(() {
          _esMiembro = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Has abandonado el equipo correctamente'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        // Recargar datos en segundo plano para actualizar el resto de la información
        _cargarEquipo();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo procesar la solicitud')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

// También corregir el método _unirseAlEquipo() de manera similar
  Future<void> _unirseAlEquipo() async {
    if (_procesandoSolicitud) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final resultado =
          await _equipoController.unirseEquipo(widget.equipoId, widget.userId);

      if (resultado && mounted) {
        // Actualizar el estado inmediatamente
        setState(() {
          _esMiembro = true;
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

        // Recargar datos en segundo plano
        _cargarEquipo();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo procesar la solicitud')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  /// Muestra diálogo de confirmación para abandonar equipo
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

  /// Muestra opciones para cambiar el logo del equipo
  Future<void> _mostrarOpcionesCambiarLogo() async {
    if (!_esCreador) return;

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

  /// Cambia el logo del equipo usando la fuente especificada
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

  /// Construye el AppBar personalizado
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

  /// Construye el contenido principal de la pantalla
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

  /// Construye el header con el nombre del equipo
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

  /// Construye la sección del logo con funcionalidad de cambio
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
            onTap: _esCreador ? _mostrarOpcionesCambiarLogo : null,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: _esCreador
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      )
                    : Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25), // Sombra sutil
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
                  // Indicador de edición para creadores
                  if (_esCreador)
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
                                  .withAlpha(76), // Sombra más visible
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

  /// Construye el logo por defecto
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

  /// Construye la sección de jugadores
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

  /// Construye un tile individual de jugador
  Widget _buildPlayerTile(Map<String, dynamic> jugador) {
    final jugadorId = jugador['id'] as String?;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(jugadorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String? imageUrl;
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          imageUrl = userData['profileImageUrl'] as String?;
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
            '${jugador['puntos'] ?? '15'} pts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  /// Construye la sección de información del equipo
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

  /// Construye una fila de información
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

  /// Construye el botón de acción principal
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _procesandoSolicitud
            ? null
            : (_esMiembro ? _abandonarEquipo : _unirseAlEquipo),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _esMiembro ? Colors.red : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: _esMiembro ? 2 : 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_esMiembro) ...[
              const Icon(Icons.exit_to_app, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              _procesandoSolicitud
                  ? 'Procesando...'
                  : (_esMiembro ? 'Abandonar equipo' : 'Unirse al equipo'),
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
