import 'package:equatable/equatable.dart';

import '../../enums/processing/process_state_enum.dart';

class SettingState extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;
  final bool isLoggedOut;
  final ProcessState processState;

  const SettingState({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.avatarUrl,
    this.isLoading = false,
    this.error,
    this.isLoggedOut = false,
    this.processState = ProcessState.idle,
  });

  SettingState copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    String? error,
    bool? isLoggedOut,
    ProcessState? processState,
  }) {
    return SettingState(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedOut: isLoggedOut ?? false,
      processState: processState ?? this.processState,
    );
  }

  @override
  List<Object?> get props =>
      [uid, name, email, avatarUrl, isLoading, error, isLoggedOut, processState];
}

class UserLoggedOut extends SettingState {
  const UserLoggedOut() : super(isLoggedOut: true);
}
