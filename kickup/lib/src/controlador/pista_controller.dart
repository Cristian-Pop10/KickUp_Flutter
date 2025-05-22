import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/pista_model.dart';

class PistaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para obtener todas las pistas
  Future<List<PistaModel>> obtenerPistas() async {
    try {
      // Intentar obtener pistas desde Firestore
      final querySnapshot = await _firestore.collection('pistas').get();
      
      // Si hay pistas en Firestore, devolverlas
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => PistaModel.fromJson(doc.data()))
            .toList();
      }
      
      // Si no hay pistas en Firestore, crear algunas de ejemplo y guardarlas
      final pistasEjemplo = _generarPistasEjemplo();
      
      // Guardar las pistas de ejemplo en Firestore
      for (final pista in pistasEjemplo) {
        await _firestore.collection('pistas').doc(pista.id).set(pista.toJson());
      }
      
      return pistasEjemplo;
    } catch (e) {
      print('Error al obtener pistas: $e');
      
      // En caso de error, devolver pistas de ejemplo sin guardarlas
      return _generarPistasEjemplo();
    }
  }

  // Método para buscar pistas por texto
  Future<List<PistaModel>> buscarPistas(String query) async {
    try {
      // Obtener todas las pistas
      List<PistaModel> pistas;
      
      try {
        // Intentar obtener pistas desde Firestore
        final querySnapshot = await _firestore.collection('pistas').get();
        
        if (querySnapshot.docs.isNotEmpty) {
          pistas = querySnapshot.docs
              .map((doc) => PistaModel.fromJson(doc.data()))
              .toList();
        } else {
          pistas = _generarPistasEjemplo();
        }
      } catch (e) {
        // En caso de error, usar pistas de ejemplo
        pistas = _generarPistasEjemplo();
      }
      
      // Si la consulta está vacía, devolver todas las pistas
      if (query.isEmpty) {
        return pistas;
      }
      
      // Filtrar las pistas según la consulta
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
      // Intentar obtener la pista desde Firestore
      final doc = await _firestore.collection('pistas').doc(pistaId).get();
      
      if (doc.exists) {
        return PistaModel.fromJson(doc.data()!);
      }
      
      // Si no existe en Firestore, buscar en las pistas de ejemplo
      final pistasEjemplo = _generarPistasEjemplo();
      return pistasEjemplo.firstWhere(
        (pista) => pista.id == pistaId,
        orElse: () => throw Exception('Pista no encontrada'),
      );
    } catch (e) {
      print('Error al obtener pista: $e');
      return null;
    }
  }

  // Método para crear una nueva pista
  Future<bool> crearPista(PistaModel pista) async {
    try {
      // Si no tiene ID, generar uno
      final id = pista.id.isEmpty ? 'pista_${DateTime.now().millisecondsSinceEpoch}' : pista.id;
      final pistaConId = pista.copyWith(id: id);
      
      // Guardar la pista en Firestore
      await _firestore.collection('pistas').doc(id).set(pistaConId.toJson());
      
      return true;
    } catch (e) {
      print('Error al crear pista: $e');
      return false;
    }
  }

  // Método para actualizar una pista
  Future<bool> actualizarPista(PistaModel pista) async {
    try {
      // Verificar que la pista tenga ID
      if (pista.id.isEmpty) {
        return false;
      }
      
      // Actualizar la pista en Firestore
      await _firestore.collection('pistas').doc(pista.id).update(pista.toJson());
      
      return true;
    } catch (e) {
      print('Error al actualizar pista: $e');
      return false;
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