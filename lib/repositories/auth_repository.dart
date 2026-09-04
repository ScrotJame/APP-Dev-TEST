import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {

  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<String?> get authStateChanges;
  String? get currentUid;
  
}

// Triển khai AuthRepository với Firebase Authentication
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }


  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;
}
