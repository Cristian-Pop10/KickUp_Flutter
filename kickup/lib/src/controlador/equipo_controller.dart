import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelo/equipo_model.dart';

class EquipoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream controller para notificar cambios en la lista de equipos
  static final _equiposStreamController =
      StreamController<List<EquipoModel>>.broadcast();

  // Stream para escuchar cambios en la lista de equipos
  Stream<List<EquipoModel>> get equiposStream =>
      _equiposStreamController.stream;

  // Constructor que inicia la escucha de cambios en Firebase
  EquipoController() {
    // Suscribirse al stream de Firebase
    _firestore.collection('equipos').snapshots().listen((snapshot) {
      final equipos =
          snapshot.docs.map((doc) => EquipoModel.fromJson(doc.data())).toList();
      _equiposStreamController.add(equipos);
    });
  }

  

  // Método para obtener todos los equipos
  Future<List<EquipoModel>> obtenerEquipos() async {
    try {
      final querySnapshot = await _firestore.collection('equipos').get();
      final equipos = querySnapshot.docs
          .map((doc) => EquipoModel.fromJson(doc.data()))
          .toList();

      return equipos;
    } catch (e) {
      print('Error al obtener equipos: $e');
      return [];
    }
  }

  // Método para crear un nuevo equipo con imagen
  Future<bool> crearEquipoConImagen(EquipoModel equipo, File? logoImage) async {
    try {
      String logoUrl = equipo.logoUrl; // Usar la URL por defecto

      // Si hay una imagen, subirla a Firebase Storage
      if (logoImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'equipos/${equipo.nombre}_$timestamp.jpg';

        // Subir la imagen a Firebase Storage
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(logoImage);
        final snapshot = await uploadTask.whenComplete(() => null);
        logoUrl = await snapshot.ref.getDownloadURL();
      }

      // Crear una copia del equipo con la URL de la imagen
      final equipoConLogo = equipo.copyWith(logoUrl: logoUrl);

      // Si no tiene ID, generar uno
      final id = equipo.id.isEmpty
          ? 'equipo_${DateTime.now().millisecondsSinceEpoch}'
          : equipo.id;
      final equipoConId = equipoConLogo.copyWith(id: id);

      // Guardar el equipo en Firestore
      await _firestore.collection('equipos').doc(id).set(equipoConId.toJson());

      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  // Método para crear un nuevo equipo
  Future<bool> crearEquipo(EquipoModel equipo, String userIdCreador) async {
    try {
      final equipoConCapitan = equipo.copyWith(
        jugadoresIds: [userIdCreador],
      );
      await _firestore
          .collection('equipos')
          .doc(equipoConCapitan.id)
          .set(equipoConCapitan.toJson());
      return true;
    } catch (e) {
      print('Error al crear equipo: $e');
      return false;
    }
  }

  // Método para buscar equipos por texto
  Future<List<EquipoModel>> buscarEquipos(String query) async {
    try {
      if (query.isEmpty) {
        return await obtenerEquipos();
      }

      // Convertir la consulta a minúsculas para búsqueda insensible a mayúsculas
      final queryLower = query.toLowerCase();

      // Obtener todos los equipos y filtrar en memoria
      final equipos = await obtenerEquipos();

      return equipos.where((equipo) {
        return equipo.nombre.toLowerCase().contains(queryLower) ||
            equipo.tipo.toLowerCase().contains(queryLower) ||
            (equipo.descripcion?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    } catch (e) {
      print('Error al buscar equipos: $e');
      return [];
    }
  }

  // Método para obtener un equipo por su ID
  Future<EquipoModel?> obtenerEquipoPorId(String equipoId) async {
    try {
      final doc = await _firestore.collection('equipos').doc(equipoId).get();
      if (doc.exists) {
        return EquipoModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener equipo: $e');
      return null;
    }
  }

  // Método para unirse a un equipo
  Future<bool> unirseEquipo(String equipoId, String userId) async {
    try {
      final equipoRef = _firestore.collection('equipos').doc(equipoId);
      final usuarioDoc =
          await _firestore.collection('usuarios').doc(userId).get();
      final userData = usuarioDoc.data();

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(equipoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        // Verificar si ya es miembro
        if (jugadoresIds.contains(userId)) return true;

        // Agregar el jugador
        jugadoresIds.add(userId);
        jugadores.add({
          'id': userId,
          'nombre': userData?['nombre'] ?? '',
          'apellidos': userData?['apellidos'] ?? '',
          'posicion': userData?['posicion'] ?? '',
          'profileImageUrl': userData?['profileImageUrl'] ?? '',
        });

        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadores,
        });

        return true;
      });
    } catch (e) {
      print('Error al unirse al equipo: $e');
      return false;
    }
  }

  // Método para abandonar un equipo
  Future<bool> abandonarEquipo(String equipoId, String userId) async {
    try {
      final equipoRef = _firestore.collection('equipos').doc(equipoId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(equipoRef);
        if (!doc.exists) return false;

        final data = doc.data()!;
        final jugadoresIds = List<String>.from(data['jugadoresIds'] ?? []);
        final jugadores =
            List<Map<String, dynamic>>.from(data['jugadores'] ?? []);

        if (!jugadoresIds.contains(userId)) return true;

        jugadoresIds.remove(userId);
        jugadores.removeWhere((jugador) => jugador['id'] == userId);

        transaction.update(equipoRef, {
          'jugadoresIds': jugadoresIds,
          'jugadores': jugadores,
        });

        return true;
      });
    } catch (e) {
      print('Error al abandonar el equipo: $e');
      return false;
    }
  }

  // Método para cerrar el stream controller
  void dispose() {
    _equiposStreamController.close();
  }

  // Método para actualizar el logo de un equipo
  Future<void> actualizarLogoEquipo(String equipoId, String logoUrl) async {
    await FirebaseFirestore.instance
        .collection('equipos')
        .doc(equipoId)
        .update({
      'logoUrl': logoUrl,
    });
  }
}
