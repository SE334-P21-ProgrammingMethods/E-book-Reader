import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signin_state.dart';

class SigninCubit extends Cubit<SigninState> {
  SigninCubit() : super(SigninInitial());

  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    emit(SigninLoading());
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        emit(SigninFailure('User not found'));
        return;
      }
      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        emit(SigninNotVerified());
        return;
      }
      // Firebase password policy: at least 6 chars, but may be stricter in future
      // Here, we warn if <8 chars or no number or no uppercase or no lowercase
      final passwordPolicyRegExp = RegExp(
          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{6,}');
      if (!passwordPolicyRegExp.hasMatch(password)) {
        emit(SigninPasswordPolicyWarning(
            uid: user.uid, email: user.email ?? ''));
        return;
      }
      emit(SigninSuccess(uid: user.uid, email: user.email ?? ''));
    } on FirebaseAuthException catch (e) {
      emit(SigninFailure(e.message ?? 'Authentication error'));
    } catch (e) {
      emit(SigninFailure('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(SigninLoading());
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(SigninFailure('Google sign in aborted'));
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        emit(SigninFailure('User not found'));
        return;
      }
      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        emit(SigninNotVerified());
        return;
      }
      // Check if user exists in Firestore, if not, create
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final doc = await usersCollection.doc(user.uid).get();
      if (!doc.exists) {
        await usersCollection.doc(user.uid).set({
          'uid': user.uid,
          'name': googleUser.displayName ?? '',
          'email': user.email ?? '',
        });
      }
      // Google passwords are managed by Google, so skip password policy check
      emit(SigninSuccess(uid: user.uid, email: user.email ?? ''));
    } on FirebaseAuthException catch (e) {
      emit(SigninFailure(e.message ?? 'Authentication error'));
    } catch (e) {
      emit(SigninFailure('An unexpected error occurred. Please try again.'));
    }
  }
}
