import 'package:flutter_application/src/modelo/partido_model.dart';


class PartidoController {
  // Simulación de una base de datos de partidos
  List<PartidoModel> _partidos = [];

  PartidoController() {
    // Inicializar con datos de ejemplo
    _inicializarPartidosEjemplo();
  }

  // Método para obtener todos los partidos
  Future<List<PartidoModel>> obtenerPartidos() async {
    // Simulamos un retraso para imitar una llamada a la red
    await Future.delayed(const Duration(milliseconds: 800));
    return _partidos;
  }

  // Método para buscar partidos por texto
  Future<List<PartidoModel>> buscarPartidos(String query) async {
    // Simulamos un retraso para imitar una llamada a la red
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (query.isEmpty) {
      return _partidos;
    }
    
    final queryLower = query.toLowerCase();
    return _partidos.where((partido) {
      return partido.tipo.toLowerCase().contains(queryLower) ||
             partido.lugar.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Método para crear un nuevo partido
  Future<bool> crearPartido(PartidoModel partido) async {
    // Simulamos un retraso para imitar una llamada a la red
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      _partidos.add(partido);
      return true;
    } catch (e) {
      print('Error al crear partido: $e');
      return false;
    }
  }

  // Método para unirse a un partido
  Future<bool> unirseAPartido(String partidoId, String userId) async {
    // Simulamos un retraso para imitar una llamada a la red
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      final index = _partidos.indexWhere((p) => p.id == partidoId);
      if (index < 0) return false;
      
      final partido = _partidos[index];
      if (partido.estaCompleto) return false;
      
      _partidos[index] = partido.copyWith(
        jugadoresActuales: partido.jugadoresActuales + 1,
        completo: partido.jugadoresActuales + 1 >= partido.capacidadTotal,
      );
      
      return true;
    } catch (e) {
      print('Error al unirse al partido: $e');
      return false;
    }
  }

  // Método para inicializar partidos de ejemplo
  void _inicializarPartidosEjemplo() {
    _partidos = [
      PartidoModel(
        id: '1',
        tipo: 'Fútbol Sala',
        lugar: 'Olula',
        fecha: DateTime(2025, 4, 10, 20, 0),
        capacidadTotal: 10,
        jugadoresActuales: 10,
        completo: true,
        creadorId: 'user_1',
      ),
      PartidoModel(
        id: '2',
        tipo: 'Fútbol Sala',
        lugar: 'Macael',
        fecha: DateTime(2025, 4, 5, 12, 0),
        capacidadTotal: 10,
        jugadoresActuales: 5,
        completo: false,
        creadorId: 'user_2',
      ),
      PartidoModel(
        id: '3',
        tipo: 'Fútbol 8',
        lugar: 'Fines',
        fecha: DateTime(2025, 3, 15, 22, 0),
        capacidadTotal: 16,
        jugadoresActuales: 13,
        completo: false,
        creadorId: 'user_3',
      ),
      PartidoModel(
        id: '4',
        tipo: 'Fútbol 11',
        lugar: 'Albox',
        fecha: DateTime(2025, 3, 25, 18, 0),
        capacidadTotal: 22,
        jugadoresActuales: 13,
        completo: false,
        creadorId: 'user_1',
      ),
    ];
  }
}