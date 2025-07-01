import 'package:ebook_reader/enums/processing/process_state_enum.dart';
import 'package:equatable/equatable.dart';

class ForgetPasswordState extends Equatable {
  final ProcessState processState;
  final String message;

  const ForgetPasswordState({
    this.processState = ProcessState.idle,
    this.message = '',
  });

  @override
  List<Object?> get props => [processState, message];

  ForgetPasswordState copyWith({
    ProcessState? processState,
    String? message,
  }) {
    return ForgetPasswordState(
      processState: processState ?? this.processState,
      message: message ?? this.message,
    );
  }
}