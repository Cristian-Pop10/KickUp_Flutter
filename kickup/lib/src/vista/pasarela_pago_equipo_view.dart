import 'package:flutter/material.dart';
import 'package:kickup/src/controlador/partido_controller.dart';
import 'package:kickup/src/modelo/equipo_model.dart';
import 'package:kickup/src/modelo/partido_model.dart';
import 'package:kickup/src/servicio/user_service.dart';
import 'package:kickup/src/vista/pasarela_pago_view.dart';

/** Vista de pasarela de pago especializada para equipos.
 * Extiende la funcionalidad de la pasarela de pago individual
 * para manejar la inscripción de múltiples jugadores de un equipo.
 */
class PasarelaPagoEquipoView extends StatefulWidget {
  final String partidoId;
  final String userId;
  final PartidoModel partido;
  final EquipoModel equipo;
  final int jugadoresAInscribir;

  const PasarelaPagoEquipoView({
    Key? key,
    required this.partidoId,
    required this.userId,
    required this.partido,
    required this.equipo,
    required this.jugadoresAInscribir,
  }) : super(key: key);

  @override
  State<PasarelaPagoEquipoView> createState() => _PasarelaPagoEquipoViewState();
}

class _PasarelaPagoEquipoViewState extends State<PasarelaPagoEquipoView> {
  final PartidoController _partidoController = PartidoController();
  final UserService _userService = UserService();
  bool _procesandoPago = false;

  /** Procesa el pago e inscribe a todos los jugadores del equipo */
  Future<void> _procesarPagoEquipo() async {
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
              Text('Procesando pago del equipo...'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Simular tiempo de procesamiento de pago
      await Future.delayed(const Duration(seconds: 3));

      // Inscribir a cada jugador del equipo
      int jugadoresInscritos = 0;
      int jugadoresYaInscritos = 0;
      int jugadoresFallidos = 0;

      for (int i = 0; i < widget.jugadoresAInscribir && i < widget.equipo.jugadoresIds.length; i++) {
        final jugadorId = widget.equipo.jugadoresIds[i];
        
        // Verificar si el jugador ya está inscrito
        final yaInscrito = await _partidoController.verificarInscripcion(
          widget.partidoId, jugadorId);
          
        if (yaInscrito) {
          jugadoresYaInscritos++;
          continue;
        }
        
        // Obtener datos del jugador
        final jugador = await _userService.getUser(jugadorId);
        if (jugador == null) {
          jugadoresFallidos++;
          continue;
        }
        
        // Inscribir al jugador
        final success = await _partidoController.inscribirsePartido(
          widget.partidoId, jugador);
          
        if (success) {
          jugadoresInscritos++;
        } else {
          jugadoresFallidos++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Mostrar resultado del pago y las inscripciones
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Pago realizado! $jugadoresInscritos jugadores inscritos'
              '${jugadoresYaInscritos > 0 ? ', $jugadoresYaInscritos ya estaban inscritos' : ''}'
              '${jugadoresFallidos > 0 ? ', $jugadoresFallidos fallidos' : ''}.'
            ),
            backgroundColor: jugadoresInscritos > 0 ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );

        // Volver con resultado exitoso
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return PasarelaPagoView(
      partidoId: widget.partidoId,
      userId: widget.userId,
      partido: widget.partido,
      // Sobrescribir el método de procesamiento para equipos
      customProcessPayment: _procesarPagoEquipo,
      // Información adicional para mostrar en la UI
      extraInfo: 'Inscribiendo ${widget.jugadoresAInscribir} jugadores del equipo ${widget.equipo.nombre}',
    );
  }
}