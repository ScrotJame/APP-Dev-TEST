import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/repositories/auth_repository.dart';

part 'login_state.dart';

// Cubit quản lý xử lý đăng nhập người dùng
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit({required this.authRepository}) : super(const LoginState());

  // Thực hiện xác thực đăng nhập tài khoản
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: LoadStatus.FAILURE,
        msg: 'Vui lòng nhập email và mật khẩu',
      ));
      return;
    }

    emit(state.copyWith(status: LoadStatus.LOADING));
    try {
      await authRepository.signIn(email: email, password: password);
      emit(state.copyWith(status: LoadStatus.SUCCESS));
    } catch (e) {
      emit(state.copyWith(
        status: LoadStatus.FAILURE,
        msg: _parseFirebaseError('$e'),
      ));
    }
  }

  // Backward compatibility alias
  Future<void> dangNhap({
    required String email,
    required String password,
  }) =>
      signIn(email: email, password: password);

  // Chuyển đổi thông báo lỗi Firebase thành tiếng Việt
  String _parseFirebaseError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (raw.contains('too-many-requests')) {
      return 'Đăng nhập thất bại quá nhiều lần. Vui lòng thử lại sau';
    }
    if (raw.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng';
    }
    return 'Đăng nhập thất bại. Vui lòng thử lại';
  }
}
