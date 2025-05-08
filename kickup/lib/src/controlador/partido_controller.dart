import 'package:flutter_application/src/modelo/partido_model.dart';
import 'package:flutter_application/src/modelo/user_model.dart';


class PartidoController {
  // Método para obtener todos los partidos
  Future<List<PartidoModel>> obtenerPartidos() async {
    // Aquí se conectaría con un servicio o API para obtener los partidos
    // Por ahora, devolvemos datos de ejemplo
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    return _generarPartidosEjemplo();
  }

  // Método para buscar partidos por texto
  Future<List<PartidoModel>> buscarPartidos(String query) async {
    // Aquí se conectaría con un servicio o API para buscar partidos
    // Por ahora, filtramos los datos de ejemplo
    await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
    
    final partidos = _generarPartidosEjemplo();
    
    if (query.isEmpty) {
      return partidos;
    }
    
    final queryLower = query.toLowerCase();
    return partidos.where((partido) {
      return partido.tipo.toLowerCase().contains(queryLower) ||
             partido.lugar.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Método para obtener un partido por su ID
  Future<PartidoModel?> obtenerPartidoPorId(String partidoId) async {
    // Aquí se conectaría con un servicio o API para obtener el partido
    // Por ahora, buscamos en los datos de ejemplo
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    final partidos = _generarPartidosEjemplo();
    return partidos.firstWhere(
      (partido) => partido.id == partidoId,
      orElse: () => throw Exception('Partido no encontrado'),
    );
  }

  // Método para verificar si un usuario está inscrito en un partido
  Future<bool> verificarInscripcion(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para verificar la inscripción
    // Por ahora, simulamos la verificación
    await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
    
    // Simulamos que el usuario está inscrito si su ID termina en "1"
    return userId.endsWith('1');
  }

  // Método para inscribirse a un partido
  Future<bool> inscribirsePartido(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para inscribirse al partido
    // Por ahora, simulamos una inscripción exitosa
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    return true; // Simulamos éxito
  }

  // Método para abandonar un partido
  Future<bool> abandonarPartido(String partidoId, String userId) async {
    // Aquí se conectaría con un servicio o API para abandonar el partido
    // Por ahora, simulamos un abandono exitoso
    await Future.delayed(const Duration(seconds: 1)); // Simular carga
    
    return true; // Simulamos éxito
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
}