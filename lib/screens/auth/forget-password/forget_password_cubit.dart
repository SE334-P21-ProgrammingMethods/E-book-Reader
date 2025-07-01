import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enums/processing/process_state_enum.dart';
import 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  ForgetPasswordCubit() : super(const ForgetPasswordState());

  void toIdle() {
    emit(state.copyWith(processState: ProcessState.idle, message: ''));
  }

  void toLoading() {
    emit(state.copyWith(processState: ProcessState.loading, message: ''));
  }

  void toFailure(String error) {
    emit(state.copyWith(processState: ProcessState.failure, message: error));
  }

  void toSuccess(String message) {
    emit(state.copyWith(processState: ProcessState.success, message: message));
  }

  Future<void> sendResetEmail(String email) async {
    toLoading();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      toSuccess('Password reset email sent successfully.');
    } on FirebaseAuthException {
      toFailure('Failed to send reset email');
    } catch (e) {
      toFailure('An unexpected error occurred. Please try again.');
      if (kDebugMode) {
        print('Error sending reset email: $e');
      }
    }
  }
}
