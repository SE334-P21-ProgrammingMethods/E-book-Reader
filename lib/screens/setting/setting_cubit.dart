import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'setting_state.dart';

class SettingCubit extends Cubit<SettingState> {
  SettingCubit() : super(const SettingState());

  Future<void> fetchUser() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(state.copyWith(isLoading: false, isLoggedOut: true));
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      emit(state.copyWith(
        uid: user.uid,
        name: data?['name'] ?? '',
        email: user.email ?? '',
        avatarUrl: data?['avatarUrl'],
        isLoading: false,
        isLoggedOut: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> updateName(String newName) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': newName});
      emit(state.copyWith(name: newName, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> uploadAvatar(File file) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars/${user.uid}/${user.uid}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'avatarUrl': url});
      emit(state.copyWith(avatarUrl: url, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> sendPasswordReset() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final email = user.email;
      if (email == null) throw Exception('No email found');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      emit(const UserLoggedOut());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
