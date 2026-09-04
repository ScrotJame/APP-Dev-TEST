import 'package:vimes_test/models/user_model.dart';
import 'package:vimes_test/repositories/auth_repository.dart';
import 'package:vimes_test/repositories/user_repository.dart';

abstract class UserSessionRepository {
  Future<UserModel?> getCurrentUser();

}

class FirestoreUserSessionRepository implements UserSessionRepository {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  FirestoreUserSessionRepository({
    required this.authRepository,
    required this.userRepository,
  });

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = authRepository.currentUid;
    if (uid == null) return null;
    return userRepository.getUser(uid);
  }

}
