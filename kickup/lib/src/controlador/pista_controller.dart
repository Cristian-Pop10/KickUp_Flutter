import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/pista_model.dart';

class PistaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para obtener todas las pistas
  Future<List<PistaModel>> obtenerPistas() async {
    try {
      print('PistaController: Obteniendo pistas...');
      
      // Intentar obtener pistas desde Firestore
      final querySnapshot = await _firestore.collection('pistas').get();
      
      // Si hay pistas en Firestore, devolverlas
      if (querySnapshot.docs.isNotEmpty) {
        print('PistaController: ${querySnapshot.docs.length} pistas encontradas en Firestore');
        return querySnapshot.docs
            .map((doc) {
              try {
                return PistaModel.fromJson(doc.data());
              } catch (e) {
                print('Error al parsear pista ${doc.id}: $e');
                return null;
              }
            })
            .where((pista) => pista != null)
            .cast<PistaModel>()
            .toList();
      }
      
      // Si no hay pistas en Firestore, crear algunas de ejemplo y guardarlas
      print('PistaController: No hay pistas en Firestore, creando ejemplos...');
      final pistasEjemplo = _generarPistasEjemplo();
      
      // Guardar las pistas de ejemplo en Firestore
      for (final pista in pistasEjemplo) {
        try {
          await _firestore.collection('pistas').doc(pista.id).set(pista.toJson());
        } catch (e) {
          print('Error al guardar pista de ejemplo ${pista.id}: $e');
        }
      }
      
      return pistasEjemplo;
    } catch (e, stackTrace) {
      print('Error al obtener pistas: $e');
      print('StackTrace: $stackTrace');
      
      // En caso de error, devolver pistas de ejemplo sin guardarlas
      return _generarPistasEjemplo();
    }
  }

  // Método para crear una nueva pista
  Future<bool> crearPista(PistaModel pista) async {
    try {
      print('PistaController: Creando pista ${pista.id}...');
      
      // Si no tiene ID, generar uno
      final id = pista.id.isEmpty ? 'pista_${DateTime.now().millisecondsSinceEpoch}' : pista.id;
      final pistaConId = pista.copyWith(id: id);
      
      print('PistaController: Guardando en Firestore con ID: $id');
      
      // Guardar la pista en Firestore
      await _firestore.collection('pistas').doc(id).set(pistaConId.toJson());
      
      print('PistaController: Pista creada exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('Error al crear pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  // Método para actualizar una pista
  Future<bool> actualizarPista(PistaModel pista) async {
    try {
      print('PistaController: Actualizando pista ${pista.id}...');
      
      // Verificar que la pista tenga ID
      if (pista.id.isEmpty) {
        print('Error: La pista no tiene ID');
        return false;
      }
      
      // Actualizar la pista en Firestore
      await _firestore.collection('pistas').doc(pista.id).update(pista.toJson());
      
      print('PistaController: Pista actualizada exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('Error al actualizar pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  // Método para eliminar una pista
  Future<bool> eliminarPista(String pistaId) async {
    try {
      print('PistaController: Eliminando pista $pistaId...');
      
      // Eliminar la pista de Firestore
      await _firestore.collection('pistas').doc(pistaId).delete();
      
      print('PistaController: Pista eliminada exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('Error al eliminar pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  // Método para eliminar múltiples pistas
  Future<int> eliminarPistasMultiples(List<String> pistaIds, String userId) async {
    int eliminadas = 0;
    
    try {
      print('PistaController: Eliminando ${pistaIds.length} pistas...');
      
      // Verificar que el usuario sea administrador
      if (!await esUsuarioAdmin(userId)) {
        print('Usuario $userId no es administrador');
        return 0;
      }
      
      // Eliminar cada pista
      for (final pistaId in pistaIds) {
        try {
          await _firestore.collection('pistas').doc(pistaId).delete();
          eliminadas++;
          print('Pista $pistaId eliminada');
        } catch (e) {
          print('Error al eliminar pista $pistaId: $e');
        }
      }
      
      print('PistaController: $eliminadas pistas eliminadas');
      return eliminadas;
    } catch (e, stackTrace) {
      print('Error al eliminar pistas: $e');
      print('StackTrace: $stackTrace');
      return eliminadas;
    }
  }

  // Método para verificar si un usuario es administrador
  Future<bool> esUsuarioAdmin(String userId) async {
    try {
      print('PistaController: Verificando si usuario $userId es admin...');
      
      final doc = await _firestore.collection('usuarios').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final esAdmin = data?['esAdmin'] == true;
        print('Usuario $userId es admin: $esAdmin');
        return esAdmin;
      }
      
      print('Usuario $userId no encontrado');
      return false;
    } catch (e, stackTrace) {
      print('Error al verificar permisos de administrador: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  // Método para obtener una pista por ID
  Future<PistaModel?> obtenerPistaPorId(String pistaId) async {
    try {
      print('PistaController: Obteniendo pista por ID: $pistaId...');
      
      final doc = await _firestore.collection('pistas').doc(pistaId).get();
      
      if (doc.exists) {
        print('PistaController: Pista encontrada: ${doc.id}');
        return PistaModel.fromJson(doc.data()!);
      } else {
        print('PistaController: Pista no encontrada');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error al obtener pista por ID: $e');
      print('StackTrace: $stackTrace');
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
    ];
  }
}