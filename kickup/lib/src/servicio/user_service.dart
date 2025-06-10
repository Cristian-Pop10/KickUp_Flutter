import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelo/user_model.dart';

/** Servicio especializado para operaciones de usuarios en Firestore.
   Proporciona métodos específicos para gestionar datos de usuarios,
   incluyendo operaciones de lectura y escritura en la colección 'usuarios'. */
class UserService {
  /** Instancia de Firestore para acceso a la base de datos */
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /** Guarda un usuario en la colección 'usuarios' de Firestore.
     
     [user] Modelo del usuario a guardar. Debe tener un ID válido.
     
     Sobrescribe completamente el documento del usuario si ya existe.
     Lanza una excepción en caso de error de conexión o permisos.*/
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('usuarios').doc(user.id).set(user.toJson());
  }

  /** Obtiene un usuario específico desde Firestore por su ID.
     
     [userId] ID único del usuario a obtener.
     
     Retorna un UserModel si el usuario existe en la base de datos,
     null si no se encuentra el documento.
     Lanza una excepción en caso de error de conexión.*/
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('usuarios').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }
}