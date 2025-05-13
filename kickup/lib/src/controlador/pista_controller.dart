import '../modelo/pista_model.dart';

class PistaController {
  // Método para obtener todas las pistas
  Future<List<PistaModel>> obtenerPistas() async {
    try {
      // En una aplicación real, aquí obtendrías los datos de las pistas desde Firebase o tu backend
      // Por ahora, simulamos datos de ejemplo
      await Future.delayed(const Duration(seconds: 1)); // Simular carga
      
      return _generarPistasEjemplo();
    } catch (e) {
      print('Error al obtener pistas: $e');
      return [];
    }
  }

  // Método para buscar pistas por texto
  Future<List<PistaModel>> buscarPistas(String query) async {
    try {
      // En una aplicación real, aquí buscarías las pistas en Firebase o tu backend
      // Por ahora, filtramos los datos de ejemplo
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      
      final pistas = _generarPistasEjemplo();
      
      if (query.isEmpty) {
        return pistas;
      }
      
      final queryLower = query.toLowerCase();
      return pistas.where((pista) {
        return pista.nombre.toLowerCase().contains(queryLower) ||
               pista.direccion.toLowerCase().contains(queryLower) ||
               (pista.tipo?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    } catch (e) {
      print('Error al buscar pistas: $e');
      return [];
    }
  }

  // Método para obtener una pista por su ID
  Future<PistaModel?> obtenerPistaPorId(String pistaId) async {
    try {
      // En una aplicación real, aquí obtendrías la pista desde Firebase o tu backend
      // Por ahora, buscamos en los datos de ejemplo
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      
      final pistas = _generarPistasEjemplo();
      return pistas.firstWhere(
        (pista) => pista.id == pistaId,
        orElse: () => throw Exception('Pista no encontrada'),
      );
    } catch (e) {
      print('Error al obtener pista: $e');
      return null;
    }
  }

  // Método para generar datos de ejemplo
  List<PistaModel> _generarPistasEjemplo() {
    return [
      PistaModel(
        id: 'pista_1',
        nombre: 'Campo de fútbol El Hornillo',
        direccion: 'Calle El Hornillo, s/n, Taberno',
        latitud: 37.4219,
        longitud: -2.2585,
        tipo: 'Fútbol 7',
        descripcion: 'Campo de fútbol municipal con césped artificial.',
        precio: 25.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo1.jpg',
      ),
      PistaModel(
        id: 'pista_2',
        nombre: 'Ciudad deportiva Pedro Pastor',
        direccion: 'Avda. del Deporte, s/n, Arboleas',
        latitud: 37.3500,
        longitud: -2.0750,
        tipo: 'Fútbol 11',
        descripcion: 'Complejo deportivo con campo de fútbol 11, pistas de tenis y piscina.',
        precio: 40.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo2.jpg',
      ),
      PistaModel(
        id: 'pista_3',
        nombre: 'Campo Municipal',
        direccion: 'Calle del Estadio, 10, Albox',
        latitud: 37.4000,
        longitud: -2.1500,
        tipo: 'Fútbol 11',
        descripcion: 'Campo municipal con gradas y vestuarios renovados.',
        precio: 35.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo3.jpg',
      ),
      PistaModel(
        id: 'pista_4',
        nombre: 'Pista Cubierta Oria',
        direccion: 'Plaza del Ayuntamiento, Oria',
        latitud: 37.4850,
        longitud: -2.3000,
        tipo: 'Fútbol Sala',
        descripcion: 'Pista cubierta para fútbol sala y otros deportes.',
        precio: 15.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo4.jpg',
      ),
      PistaModel(
        id: 'pista_5',
        nombre: 'Complejo Deportivo El Contador',
        direccion: 'Carretera A-334, El Contador',
        latitud: 37.5000,
        longitud: -2.1800,
        tipo: 'Fútbol 7',
        descripcion: 'Complejo con campo de fútbol 7 y pistas de pádel.',
        precio: 20.0,
        disponible: false,
        imagenUrl: 'assets/pistas/campo5.jpg',
      ),
      PistaModel(
        id: 'pista_6',
        nombre: 'Campo de Fútbol Chirivel',
        direccion: 'Calle Deportes, Chirivel',
        latitud: 37.5950,
        longitud: -2.2650,
        tipo: 'Fútbol 11',
        descripcion: 'Campo de fútbol con césped natural.',
        precio: 30.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo6.jpg',
      ),
      PistaModel(
        id: 'pista_7',
        nombre: 'Pista Municipal Albánchez',
        direccion: 'Calle Mayor, Albánchez',
        latitud: 37.2850,
        longitud: -2.1800,
        tipo: 'Fútbol Sala',
        descripcion: 'Pista municipal para fútbol sala y baloncesto.',
        precio: 12.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo7.jpg',
      ),
      PistaModel(
        id: 'pista_8',
        nombre: 'Campo de Fútbol Uleila',
        direccion: 'Avenida Andalucía, Uleila del Campo',
        latitud: 37.1950,
        longitud: -2.2100,
        tipo: 'Fútbol 7',
        descripcion: 'Campo de fútbol 7 con césped artificial de última generación.',
        precio: 22.0,
        disponible: true,
        imagenUrl: 'assets/pistas/campo8.jpg',
      ),
    ];
  }
}
