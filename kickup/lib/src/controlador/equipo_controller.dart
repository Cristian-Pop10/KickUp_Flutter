import 'package:flutter_application/src/modelo/equipo_model.dart';

class EquipoController {
  // Método para obtener todos los equipos
  Future<List<EquipoModel>> obtenerEquipos() async {
    try {
      // En una aplicación real, aquí obtendrías los datos de los equipos desde Firebase o tu backend
      // Por ahora, simulamos datos de ejemplo
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      return _generarEquiposEjemplo();
    } catch (e) {
      print('Error al obtener equipos: $e');
      return [];
    }
  }

  // Método para buscar equipos por texto
  Future<List<EquipoModel>> buscarEquipos(String query) async {
    try {
      // En una aplicación real, aquí buscarías los equipos en Firebase o tu backend
      // Por ahora, filtramos los datos de ejemplo
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      
      final equipos = _generarEquiposEjemplo();
      
      if (query.isEmpty) {
        return equipos;
      }
      
      final queryLower = query.toLowerCase();
      return equipos.where((equipo) {
        return equipo.nombre.toLowerCase().contains(queryLower) ||
               equipo.tipo.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      print('Error al buscar equipos: $e');
      return [];
    }
  }

  // Método para obtener un equipo por su ID
  Future<EquipoModel?> obtenerEquipoPorId(String equipoId) async {
    try {
      // En una aplicación real, aquí obtendrías el equipo desde Firebase o tu backend
      // Por ahora, buscamos en los datos de ejemplo
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      
      final equipos = _generarEquiposEjemplo();
      return equipos.firstWhere(
        (equipo) => equipo.id == equipoId,
        orElse: () => throw Exception('Equipo no encontrado'),
      );
    } catch (e) {
      print('Error al obtener equipo: $e');
      return null;
    }
  }

  // Método para crear un nuevo equipo
  Future<bool> crearEquipo(EquipoModel equipo) async {
    try {
      // En una aplicación real, aquí crearías el equipo en Firebase o tu backend
      // Por ahora, simulamos una creación exitosa
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      print('Equipo creado: ${equipo.nombre}');
      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  // Método para unirse a un equipo
  Future<bool> unirseEquipo(String equipoId, String userId) async {
    try {
      // En una aplicación real, aquí actualizarías el equipo en Firebase o tu backend
      // Por ahora, simulamos una unión exitosa
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      print('Usuario $userId se unió al equipo $equipoId');
      return true;
    } catch (e) {
      print('Error al unirse al equipo: $e');
      return false;
    }
  }

  // Método para abandonar un equipo
  Future<bool> abandonarEquipo(String equipoId, String userId) async {
    try {
      // En una aplicación real, aquí actualizarías el equipo en Firebase o tu backend
      // Por ahora, simulamos un abandono exitoso
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      print('Usuario $userId abandonó el equipo $equipoId');
      return true;
    } catch (e) {
      print('Error al abandonar el equipo: $e');
      return false;
    }
  }

  // Método para generar datos de ejemplo
  List<EquipoModel> _generarEquiposEjemplo() {
    return [
      EquipoModel(
        id: 'equipo_1',
        nombre: 'Esmayaos FC',
        tipo: 'Fútbol Sala',
        logoUrl: 'assets/logos/esmayaos.png',
        descripcion: 'Equipo de fútbol sala amateur',
        jugadoresIds: ['user_1', 'user_2', 'user_3'],
        creadorId: 'user_1',
      ),
      EquipoModel(
        id: 'equipo_2',
        nombre: 'Laquetecuento FC',
        tipo: 'Fútbol Sala',
        logoUrl: 'assets/logos/laquetecuento.png',
        descripcion: 'Equipo de fútbol sala recreativo',
        jugadoresIds: ['user_2', 'user_4'],
        creadorId: 'user_2',
      ),
      EquipoModel(
        id: 'equipo_3',
        nombre: 'Mondongo FC',
        tipo: 'Fútbol 7',
        logoUrl: 'assets/logos/mondongo.png',
        descripcion: 'Equipo de fútbol 7 competitivo',
        jugadoresIds: ['user_1', 'user_5', 'user_6'],
        creadorId: 'user_5',
      ),
      EquipoModel(
        id: 'equipo_4',
        nombre: 'Aliados FC',
        tipo: 'Fútbol Sala',
        logoUrl: 'assets/logos/aliados.png',
        descripcion: 'Equipo de fútbol sala universitario',
        jugadoresIds: ['user_3', 'user_7'],
        creadorId: 'user_3',
      ),
      EquipoModel(
        id: 'equipo_5',
        nombre: 'Deryaba FC',
        tipo: 'Fútbol Sala',
        logoUrl: 'assets/logos/deryaba.png',
        descripcion: 'Equipo de fútbol sala de empresa',
        jugadoresIds: ['user_8', 'user_9'],
        creadorId: 'user_8',
      ),
      EquipoModel(
        id: 'equipo_6',
        nombre: 'Albiol FC',
        tipo: 'Fútbol 11',
        logoUrl: 'assets/logos/albiol.png',
        descripcion: 'Equipo de fútbol 11 de barrio',
        jugadoresIds: ['user_10', 'user_11', 'user_12'],
        creadorId: 'user_10',
      ),
    ];
  }
}