import 'package:flutter/material.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';

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
      final equipo = await _equipoController.obtenerEquipoPorId(widget.equipoId);
      
      if (equipo != null) {
        // Verificar si el usuario actual es miembro del equipo
        final esMiembro = equipo.jugadoresIds.contains(widget.userId);
        
        setState(() {
          _equipo = equipo;
          _esMiembro = esMiembro;
          _isLoading = false;
        });
      } else {
        // Manejar el caso en que no se encuentra el equipo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró el equipo')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Manejar errores
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
      final resultado = await _equipoController.unirseEquipo(widget.equipoId, widget.userId);
      
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
      final resultado = await _equipoController.abandonarEquipo(widget.equipoId, widget.userId);
      
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

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5EFE6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con nombre del equipo y avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _equipo!.nombre,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Logo del equipo
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        _equipo!.logoUrl,
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
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Información del equipo
                _buildInfoRow('Jugadores', _equipo!.jugadoresIds.length.toString()),
                const SizedBox(height: 15),
                _buildInfoRow('Capitán', 'Luis Ruiz'),
                const SizedBox(height: 15),
                _buildInfoRow('Nivel', '4'),
                
                const SizedBox(height: 25),
                
                // Descripción
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
                
                const Spacer(),
                
                // Botón para unirse o abandonar el equipo
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
          ),
        ),
      ],
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
