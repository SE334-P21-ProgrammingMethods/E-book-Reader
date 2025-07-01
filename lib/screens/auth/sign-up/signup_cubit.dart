import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../models/user.dart';
import 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit() : super(const SignupState());

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
  
  Future<void> signUp({
    required String name,
    required String email,
    required String password
  }) async {
    toLoading();    
    try {
      if (kDebugMode) {
        print('Starting signup process...');
      }
      // Create user with Firebase Auth
      if (kDebugMode) {
        print('Creating user with Firebase Auth...');
      }      
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) {
        print('Firebase Auth user created successfully');
      }

      final uid = credential.user?.uid;
      if (kDebugMode) {
        print('User ID: $uid');
      }
      if (uid == null) {
        if (kDebugMode) {
          print('Error: User ID is null');
        }
        throw Exception('User ID not found');
      }

      // Create user object
      if (kDebugMode) {
        print('Creating AppUser object...');
      }
      final user = AppUser(uid: uid, name: name, email: email);
      if (kDebugMode) {
        print('AppUser object created: ${user.toMap()}');
      }

      // Save user to Firestore
      if (kDebugMode) {
        print('Saving user to Firestore...');
      }
      final usersCollection = FirebaseFirestore.instance.collection('users');
      await usersCollection.doc(uid).set(user.toMap());
      if (kDebugMode) {
        print('User saved to Firestore successfully');
      }

      // Send email verification
      if (kDebugMode) {
        print('Sending email verification...');
      }
      await credential.user?.sendEmailVerification();
      if (kDebugMode) {
        print('Email verification sent');
      }

      // Sign out the user to prevent automatic login before email verification
      if (kDebugMode) {
        print('Signing out user to prevent automatic login...');
      }
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) {
        print('User signed out successfully');
      }

      if (kDebugMode) {
        print('Signup process completed successfully');
      }
      toSuccess('A verification email has been sent to your registered email address. Please verify your email before signing in.');
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException occurred: ${e.message}');
      }
      // Only show FirebaseAuth errors
      toFailure('Authentication error');
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error occurred: $e');
      }
      toFailure('An unexpected error occurred. Please try again.');
    }
  }
}
