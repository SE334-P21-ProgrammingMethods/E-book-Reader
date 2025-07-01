import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../enums/processing/process_state_enum.dart';

class SignupState extends Equatable {
  final ProcessState processState;
  final String message;

  const SignupState({
    this.processState = ProcessState.idle,
    this.message = '',
  });

  @override
  List<Object?> get props => [message, processState];

  SignupState copyWith({
    ProcessState? processState,
    String? message,
  }) {
    return SignupState(
      processState: processState ?? this.processState,
      message: message ?? this.message,
    );
  }
}
