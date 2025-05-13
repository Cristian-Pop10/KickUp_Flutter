import '../modelo/partido_model.dart';
import '../modelo/user_model.dart';
import 'dart:async';

class PartidoController {
  // Lista para almacenar los partidos (simulando una base de datos)
  static final List<PartidoModel> _partidos = [];
  
  // Stream controller para notificar cambios en la lista de partidos
  static final _partidosStreamController = StreamController<List<PartidoModel>>.broadcast();
  
  // Stream para escuchar cambios en la lista de partidos
  Stream<List<PartidoModel>> get partidosStream => _partidosStreamController.stream;

  // Constructor
  PartidoController() {
    // Si la lista está vacía, inicializarla con datos de ejemplo
    if (_partidos.isEmpty) {
      _partidos.addAll(_generarPartidosEjemplo());
      _partidosStreamController.add(_partidos);
    }
  }

  // Método para obtener todos los partidos
  Future<List<PartidoModel>> obtenerPartidos() async {
    // Aquí se conectaría con un servicio o API para obtener los partidos
    // Por ahora, devolvemos los partidos almacenados
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    return _partidos;
  }

  // Método para crear un nuevo partido
  Future<bool> crearPartido(PartidoModel partido) async {
    try {
      // Aquí se conectaría con un servicio o API para crear el partido
      // Por ahora, lo añadimos a la lista local
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      _partidos.add(partido);
      _partidosStreamController.add(_partidos); // Notificar cambios
      
      return true;
    } catch (e) {
      print('Error al crear partido: $e');
      return false;
    }
  }

  // Método para buscar partidos por texto
  Future<List<PartidoModel>> buscarPartidos(String query) async {
    // Aquí se conectaría con un servicio o API para buscar partidos
    // Por ahora, filtramos los datos almacenados
    await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
    
    if (query.isEmpty) {
      return _partidos;
    }
    
    final queryLower = query.toLowerCase();
    return _partidos.where((partido) {
      return partido.tipo.toLowerCase().contains(queryLower) ||
             partido.lugar.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Método para obtener un partido por su ID
  Future<PartidoModel?> obtenerPartidoPorId(String partidoId) async {
    // Aquí se conectaría con un servicio o API para obtener el partido
    // Por ahora, buscamos en los datos almacenados
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    try {
      return _partidos.firstWhere(
        (partido) => partido.id == partidoId,
      );
    } catch (e) {
      print('Error al obtener partido: $e');
      return null;
    }
  }

  // Método para verificar si un usuario está inscrito en un partido
  Future<bool> verificarInscripcion(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para verificar la inscripción
    // Por ahora, simulamos la verificación
    await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
    
    try {
      final partido = await obtenerPartidoPorId(partidoId);
      if (partido == null) return false;
      
      return partido.jugadores.any((jugador) => jugador.id == userId);
    } catch (e) {
      print('Error al verificar inscripción: $e');
      return false;
    }
  }

  // Método para inscribirse a un partido
  Future<bool> inscribirsePartido(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para inscribirse al partido
    // Por ahora, simulamos una inscripción exitosa
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    try {
      final partidoIndex = _partidos.indexWhere((p) => p.id == partidoId);
      if (partidoIndex == -1) return false;
      
      final partido = _partidos[partidoIndex];
      
      // Verificar si ya está inscrito
      if (partido.jugadores.any((j) => j.id == userId)) return true;
      
      // Crear un usuario simulado
      final nuevoJugador = UserModel(
        id: userId,
        email: 'usuario$userId@example.com',
        nombre: 'Usuario $userId',
      );
      
      // Crear una copia del partido con el nuevo jugador
      final nuevosJugadores = List<UserModel>.from(partido.jugadores)..add(nuevoJugador);
      final nuevoPartido = partido.copyWith(
        jugadores: nuevosJugadores,
        jugadoresFaltantes: partido.jugadoresFaltantes - 1,
        completo: partido.jugadoresFaltantes <= 1,
      );
      
      // Actualizar el partido en la lista
      _partidos[partidoIndex] = nuevoPartido;
      _partidosStreamController.add(_partidos); // Notificar cambios
      
      return true;
    } catch (e) {
      print('Error al inscribirse al partido: $e');
      return false;
    }
  }

  // Método para abandonar un partido
  Future<bool> abandonarPartido(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para abandonar el partido
    // Por ahora, simulamos un abandono exitoso
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    try {
      final partidoIndex = _partidos.indexWhere((p) => p.id == partidoId);
      if (partidoIndex == -1) return false;
      
      final partido = _partidos[partidoIndex];
      
      // Verificar si está inscrito
      if (!partido.jugadores.any((j) => j.id == userId)) return true;
      
      // Crear una copia del partido sin el jugador
      final nuevosJugadores = partido.jugadores.where((j) => j.id != userId).toList();
      final nuevoPartido = partido.copyWith(
        jugadores: nuevosJugadores,
        jugadoresFaltantes: partido.jugadoresFaltantes + 1,
        completo: false,
      );
      
      // Actualizar el partido en la lista
      _partidos[partidoIndex] = nuevoPartido;
      _partidosStreamController.add(_partidos); // Notificar cambios
      
      return true;
    } catch (e) {
      print('Error al abandonar el partido: $e');
      return false;
    }
  }

  // Método para generar datos de ejemplo
  List<PartidoModel> _generarPartidosEjemplo() {
    final ahora = DateTime.now();
    
    // Crear algunos usuarios de ejemplo
    final usuarios = [
      UserModel(
        id: 'user_1',
        email: 'usuario1@example.com',
        nombre: 'Juan',
        apellidos: 'Pérez',
        posicion: 'Delantero',
        profileImageUrl: 'assets/profile.jpg',
      ),
      UserModel(
        id: 'user_2',
        email: 'usuario2@example.com',
        nombre: 'María',
        apellidos: 'García',
        posicion: 'Defensa',
        profileImageUrl: 'assets/profile.jpg',
      ),
      UserModel(
        id: 'user_3',
        email: 'usuario3@example.com',
        nombre: 'Carlos',
        apellidos: 'López',
        posicion: 'Portero',
        profileImageUrl: 'assets/profile.jpg',
      ),
    ];
    
    // Crear partidos de ejemplo
    return [
      PartidoModel(
        id: 'partido_1',
        fecha: ahora.add(const Duration(days: 1, hours: 2)),
        tipo: 'Fútbol 7',
        lugar: 'Campo Municipal',
        completo: false,
        jugadoresFaltantes: 3,
        precio: 5.0,
        duracion: 90,
        descripcion: 'Partido amistoso de fútbol 7. Se necesitan 3 jugadores más para completar los equipos. El precio incluye el alquiler del campo y los petos.',
        jugadores: [usuarios[0], usuarios[1]],
      ),
      PartidoModel(
        id: 'partido_2',
        fecha: ahora.add(const Duration(days: 2, hours: 4)),
        tipo: 'Fútbol 5',
        lugar: 'Polideportivo Central',
        completo: true,
        jugadoresFaltantes: 0,
        precio: 7.5,
        duracion: 60,
        descripcion: 'Partido de fútbol 5 indoor. El equipo está completo. El precio incluye el alquiler de la pista y el balón.',
        jugadores: usuarios,
      ),
      PartidoModel(
        id: 'partido_3',
        fecha: ahora.add(const Duration(days: 3, hours: 1)),
        tipo: 'Fútbol 11',
        lugar: 'Estadio Norte',
        completo: false,
        jugadoresFaltantes: 5,
        precio: 10.0,
        duracion: 120,
        descripcion: 'Partido de fútbol 11 en campo completo. Necesitamos 5 jugadores más para completar los equipos. El precio incluye el alquiler del campo, árbitro y agua.',
        jugadores: [usuarios[2]],
      ),
    ];
  }
  
  // Método para cerrar el stream controller
  void dispose() {
    _partidosStreamController.close();
  }
}
