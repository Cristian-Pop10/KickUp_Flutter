import 'package:flutter/material.dart';
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
  final EquipoController _equipoController = EquipoController();
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

  Future<void> _cargarEquipo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final equipo =
          await _equipoController.obtenerEquipoPorId(widget.equipoId);

      if (equipo != null) {
        final esMiembro = equipo.jugadoresIds.contains(widget.userId);
        final esCreador = equipo.creadorId == widget.userId;

        setState(() {
          _equipo = equipo;
          _esMiembro = esMiembro;
          _esCreador = esCreador;
          _isLoading = false;
        });
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

  Future<void> _unirseAlEquipo() async {
    if (_procesandoSolicitud) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final resultado =
          await _equipoController.unirseEquipo(widget.equipoId, widget.userId);

      if (resultado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada correctamente')),
        );
        setState(() {
          _esMiembro = true;
        });
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

  Future<void> _abandonarEquipo() async {
    if (_procesandoSolicitud) return;

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final resultado = await _equipoController.abandonarEquipo(
          widget.equipoId, widget.userId);

      if (resultado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has abandonado el equipo')),
        );
        setState(() {
          _esMiembro = false;
        });
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

  Future<void> _cambiarLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // Usuario canceló

    setState(() {
      _procesandoSolicitud = true;
    });

    try {
      final fileBytes = await pickedFile.readAsBytes();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('logos_equipos')
          .child('${widget.equipoId}.jpg');

      await storageRef.putData(fileBytes);

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId)
          .update({'logoUrl': downloadUrl});

      await _cargarEquipo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar logo: $e')),
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
      backgroundColor: const Color(0xFFE5EFE6), // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Equipos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetalleEquipo(),
    );
  }

  Widget _buildDetalleEquipo() {
    if (_equipo == null) {
      return const Center(child: Text('No se encontró información del equipo'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _equipo!.nombre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
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

                return Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: (logoUrl != null && logoUrl.isNotEmpty)
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.sports_soccer,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.sports_soccer,
                                  size: 70,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    if (_esCreador)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: InkWell(
                          onTap: _cambiarLogo,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          StreamBuilder<DocumentSnapshot>(
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
                  const Text(
                    'Jugadores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jugadoresList.length,
                    itemBuilder: (context, index) {
                      final jugador = jugadoresList[index];
                      final jugadorId = jugador['id'] as String?;

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(jugadorId)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          String? imageUrl;
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.data() != null) {
                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            imageUrl = userData['profileImageUrl'] as String?;
                          }
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage(imageUrl)
                                      : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              '${jugador['nombre'] ?? ''} ${jugador['apellidos'] ?? ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text(jugador['posicion'] ?? 'Sin posición'),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          _buildInfoRow('Nivel', _equipo!.nivel.toString()),
          const SizedBox(height: 25),
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _equipo!.descripcion ?? 'Sin descripción',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _procesandoSolicitud
                  ? null
                  : (_esMiembro ? _abandonarEquipo : _unirseAlEquipo),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A9A7A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _procesandoSolicitud
                    ? 'Procesando...'
                    : (_esMiembro
                        ? 'Abandonar equipo'
                        : 'Petición para unirse al equipo'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
