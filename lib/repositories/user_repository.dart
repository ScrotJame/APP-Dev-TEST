import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vimes_test/models/user_model.dart';

abstract class UserRepository { 

  Future<UserModel?> getUser(String uid);

  Future<void> saveUser(UserModel user);

  Future<void> updateUser(String uid, Map<String, dynamic> fields);

  Future<List<UserModel>> getAllUsers();

  Future<List<UserModel>> getUsersByRole(String role);

}

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      firestore.collection('users');

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _usersCol.doc(user.uid).set(user.toMap());
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _usersCol.doc(uid).update(fields);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersCol.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<UserModel>> getUsersByRole(String role) async {
    final snapshot = await _usersCol
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

}
