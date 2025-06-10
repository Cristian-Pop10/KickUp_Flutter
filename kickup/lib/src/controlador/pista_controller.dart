import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/pista_model.dart';

/** Controlador que gestiona todas las operaciones relacionadas con pistas deportivas.
   Maneja la creación, búsqueda, modificación y eliminación de pistas,
   así como la verificación de permisos administrativos y generación de datos de ejemplo. */
class PistaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Obtiene todas las pistas deportivas de la base de datos.
     Si no existen pistas en Firestore, genera y guarda datos de ejemplo automáticamente. */
  Future<List<PistaModel>> obtenerPistas() async {
    try {
      final querySnapshot = await _firestore.collection('pistas').get();

      if (querySnapshot.docs.isNotEmpty) {
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

      final pistasEjemplo = _generarPistasEjemplo();

      for (final pista in pistasEjemplo) {
        try {
          await _firestore
              .collection('pistas')
              .doc(pista.id)
              .set(pista.toJson());
        } catch (e) {
          print('Error al guardar pista de ejemplo ${pista.id}: $e');
        }
      }

      return pistasEjemplo;
    } catch (e, stackTrace) {
      print('Error al obtener pistas: $e');
      print('StackTrace: $stackTrace');

      return _generarPistasEjemplo();
    }
  }

  /** Crea una nueva pista deportiva en la base de datos.
     Genera automáticamente un ID único si no se proporciona. */
  Future<bool> crearPista(PistaModel pista) async {
    try {
      final id = pista.id.isEmpty
          ? 'pista_${DateTime.now().millisecondsSinceEpoch}'
          : pista.id;
      final pistaConId = pista.copyWith(id: id);

      await _firestore.collection('pistas').doc(id).set(pistaConId.toJson());

      return true;
    } catch (e, stackTrace) {
      print('Error al crear pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  /** Actualiza los datos de una pista existente en la base de datos. */
  Future<bool> actualizarPista(PistaModel pista) async {
    try {
      if (pista.id.isEmpty) {
        print('Error: La pista no tiene ID');
        return false;
      }

      await _firestore
          .collection('pistas')
          .doc(pista.id)
          .update(pista.toJson());

      return true;
    } catch (e, stackTrace) {
      print('Error al actualizar pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  /** Elimina una pista específica de la base de datos. */
  Future<bool> eliminarPista(String pistaId) async {
    try {
      await _firestore.collection('pistas').doc(pistaId).delete();

      return true;
    } catch (e, stackTrace) {
      print('Error al eliminar pista: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  /** Elimina múltiples pistas en una sola operación.
     Solo disponible para administradores. Retorna el número de pistas eliminadas exitosamente. */
  Future<int> eliminarPistasMultiples(
      List<String> pistaIds, String userId) async {
    int eliminadas = 0;

    try {
      if (!await esUsuarioAdmin(userId)) {
        print('Usuario $userId no es administrador');
        return 0;
      }

      for (final pistaId in pistaIds) {
        try {
          await _firestore.collection('pistas').doc(pistaId).delete();
          eliminadas++;
        } catch (e) {
          print('Error al eliminar pista $pistaId: $e');
        }
      }

      return eliminadas;
    } catch (e, stackTrace) {
      print('Error al eliminar pistas: $e');
      print('StackTrace: $stackTrace');
      return eliminadas;
    }
  }

  /** Verifica si un usuario tiene permisos de administrador. */
  Future<bool> esUsuarioAdmin(String userId) async {
    try {
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

  /** Obtiene una pista específica por su ID. */
  Future<PistaModel?> obtenerPistaPorId(String pistaId) async {
    try {
      final doc = await _firestore.collection('pistas').doc(pistaId).get();

      if (doc.exists) {
        return PistaModel.fromJson(doc.data()!);
      } else {
        print('Pista no encontrada');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error al obtener pista por ID: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  /** Genera una lista de pistas de ejemplo para inicializar la base de datos.
     Incluye diferentes tipos de instalaciones deportivas con datos realistas. */
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
        descripcion:
            'Complejo deportivo con campo de fútbol 11, pistas de tenis y piscina.',
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
