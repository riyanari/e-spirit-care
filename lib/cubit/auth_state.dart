part of 'auth_cubit.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {

  final UserModel user;

  const AuthSuccess(this.user);

  @override
  // TODO: implement props
  List<Object> get props => [user];

}

class ChildAuthSuccess extends AuthState {
  final ChildModel child;

  const ChildAuthSuccess({required this.child});

  @override
  List<Object> get props => [child];
}

class AuthFailed extends AuthState {

  final String error;

  const AuthFailed(this.error);

  @override
  // TODO: implement props
  List<Object> get props => [error];

}

class AuthPasswordResetSent extends AuthState {}