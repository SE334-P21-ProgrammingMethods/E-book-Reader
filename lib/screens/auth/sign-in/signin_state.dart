import 'package:equatable/equatable.dart';

abstract class SigninState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SigninInitial extends SigninState {}

class SigninLoading extends SigninState {}

class SigninSuccess extends SigninState {
  final String uid;
  final String email;
  SigninSuccess({required this.uid, required this.email});

  @override
  List<Object?> get props => [uid, email];
}

class SigninFailure extends SigninState {
  final String error;
  SigninFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class SigninNotVerified extends SigninState {}

class SigninPasswordPolicyWarning extends SigninState {
  final String uid;
  final String email;
  SigninPasswordPolicyWarning({required this.uid, required this.email});

  @override
  List<Object?> get props => [uid, email];
}
