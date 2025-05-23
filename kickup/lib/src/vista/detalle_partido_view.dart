import 'package:flutter/material.dart';
import 'package:kickup/src/controlador/auth_controller.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/servicio/user_service.dart';

class DetallePartidoView extends StatefulWidget {
  final String partidoId;
  final String userId;

  final AuthController authController = AuthController();

  DetallePartidoView({
    Key? key,
    required this.partidoId,
    required this.userId,
  }) : super(key: key);

  @override
  State<DetallePartidoView> createState() => _DetallePartidoViewState();
}

class _DetallePartidoViewState extends State<DetallePartidoView> {
  final PartidoController _partidoController = PartidoController();
  final UserService _userService = UserService();
  PartidoModel? _partido;
  bool _isLoading = true;
  bool _usuarioInscrito = false;

  @override
  void initState() {
    super.initState();
    _cargarPartido();
  }

  Future<void> _cargarPartido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final partido =
          await _partidoController.obtenerPartidoPorId(widget.partidoId);
      final inscrito = await _partidoController.verificarInscripcion(
          widget.partidoId, widget.userId);

      setState(() {
        _partido = partido;
        _usuarioInscrito = inscrito;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar el partido: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _inscribirsePartido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtén el usuario completo desde Firestore
      final user = await _userService.getUser(widget.userId);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener el usuario')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success =
          await _partidoController.inscribirsePartido(widget.partidoId, user);

      if (success) {
        setState(() {
          _usuarioInscrito = true;
          if (_partido != null) {
            _partido = _partido!.copyWith(
              jugadoresFaltantes: _partido!.jugadoresFaltantes - 1,
              completo: _partido!.jugadoresFaltantes <= 1,
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Te has inscrito al partido correctamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al inscribirse al partido')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _abandonarPartido() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
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
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _partidoController.abandonarPartido(
          widget.partidoId, widget.userId);

      if (success) {
        setState(() {
          _usuarioInscrito = false;
          if (_partido != null) {
            _partido = _partido!.copyWith(
              jugadoresFaltantes: _partido!.jugadoresFaltantes + 1,
              completo: false,
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Has abandonado el partido correctamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al abandonar el partido')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day;
    final mes = _obtenerNombreMes(fecha.month);
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia de $mes, $anio - $hora:$minuto';
  }

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
      backgroundColor: const Color(0xFFD7EAD9), // Fondo verde claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalle del partido',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partido == null
              ? const Center(child: Text('Partido no encontrado'))
              : SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFE5EFE6), // Fondo más claro para el contenido
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado con fecha y tipo de partido
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(
                                0xFFD2C9A0), // Color beige para el encabezado
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatearFecha(_partido!.fecha),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                        ),

                        // Información del partido
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estado del partido
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _partido!.completo
                                      ? Colors.red.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _partido!.completo
                                      ? 'Partido completo'
                                      : 'Faltan ${_partido!.jugadoresFaltantes} jugadores',
                                  style: TextStyle(
                                    color: _partido!.completo
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Detalles del partido
                              _buildInfoSection(
                                'Ubicación',
                                _partido!.lugar,
                                Icons.location_on,
                              ),

                              const SizedBox(height: 16),

                              _buildInfoSection(
                                'Precio',
                                '${_partido!.precio}€ por persona',
                                Icons.euro,
                              ),

                              const SizedBox(height: 16),

                              _buildInfoSection(
                                'Duración',
                                '${_partido!.duracion} minutos',
                                Icons.timer,
                              ),

                              const SizedBox(height: 24),

                              // Lista de jugadores
                              const Text(
                                'Jugadores inscritos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Lista de jugadores (simulada)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _partido!.jugadores.length,
                                itemBuilder: (context, index) {
                                  final jugador = _partido!.jugadores[index];
                                  return ListTile(
                                    leading: FutureBuilder<String?>(
                                      future: widget.authController
                                          .getProfileImageUrl(widget.userId),
                                      builder: (context, snapshot) {
                                        final imageUrl = snapshot.data;
                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundImage: (imageUrl != null &&
                                                  imageUrl.isNotEmpty)
                                              ? NetworkImage(imageUrl)
                                              : const AssetImage(
                                                  'assets/profile.jpg')
                                                  as ImageProvider,
                                        );
                                      },
                                    ),
                                    title: Text(
                                      '${jugador.nombre} ${jugador.apellidos}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      jugador.posicion ?? 'Sin posición',
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Botón para inscribirse o abandonar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _partido!.completo &&
                                          !_usuarioInscrito
                                      ? null // Desactivar si está completo y el usuario no está inscrito
                                      : _usuarioInscrito
                                          ? _abandonarPartido
                                          : _inscribirsePartido,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _usuarioInscrito
                                        ? Colors.red
                                        : const Color(0xFF5A9A7A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    disabledBackgroundColor: Colors.grey,
                                  ),
                                  child: Text(
                                    _usuarioInscrito
                                        ? 'Abandonar partido'
                                        : 'Inscribirse al partido',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF5A9A7A),
          size: 24,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
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
      ],
    );
  }
}
