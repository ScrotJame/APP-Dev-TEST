part of 'login_cubit.dart';

// State quản lý trạng thái màn hình đăng nhập
class LoginState extends Equatable {
  final LoadStatus status;
  final String msg;

  const LoginState({
    this.status = LoadStatus.INITIAL,
    this.msg = '',
  });

  LoginState copyWith({LoadStatus? status, String? msg}) {
    return LoginState(
      status: status ?? this.status,
      msg: msg ?? this.msg,
    );
  }

  @override
  List<Object?> get props => [status, msg];
}
