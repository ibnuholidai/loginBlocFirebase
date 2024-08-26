import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthCubit() : super(AuthInitial());

  // Fungsi untuk mendaftarkan akun dengan Google
  Future<void> createAccountAndLinkItWithGoogleAccount(
      String email,
      String password,
      GoogleSignInAccount googleUser,
      OAuthCredential credential) async {
    emit(AuthLoading());

    try {
      await _auth.createUserWithEmailAndPassword(
        email: googleUser.email,
        password: password,
      );
      await _auth.currentUser!.linkWithCredential(credential);
      await _auth.currentUser!.updateDisplayName(googleUser.displayName);
      await _auth.currentUser!.updatePhotoURL(googleUser.photoUrl);
      emit(UserSingupAndLinkedWithGoogle());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(AuthError('Alamat email sudah digunakan oleh akun lain.'));
      } else if (e.code == 'weak-password') {
        emit(AuthError('Kata sandi yang diberikan terlalu lemah.'));
      } else {
        emit(AuthError('Gagal membuat akun dan menghubungkan dengan Google: ${e.message}'));
      }
    } catch (e) {
      emit(AuthError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(ResetPasswordSent());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emit(AuthError('No user found with this email address.'));
      } else {
        emit(AuthError('Failed to send password reset email: ${e.message}'));
      }
    } catch (e) {
      emit(AuthError('An unexpected error occurred while resetting password: $e'));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user!.emailVerified) {
        emit(UserSignIn());
      } else {
        await _auth.signOut();
        emit(AuthError('Email not verified. Please check your email.'));
        emit(UserNotVerified());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emit(AuthError('No user found with this email address.'));
      } else if (e.code == 'wrong-password') {
        emit(AuthError('Wrong password provided for this user.'));
      } else {
        emit(AuthError('Failed to sign in: ${e.message}'));
      }
    } catch (e) {
      emit(AuthError('An unexpected error occurred during sign in: $e'));
    }
  }

  // Fungsi untuk masuk menggunakan akun Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(AuthError('Proses Sign In Google dibatalkan oleh pengguna.'));
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential authResult = await _auth.signInWithCredential(credential);
      if (authResult.additionalUserInfo!.isNewUser) {
        await _auth.currentUser!.delete();
        emit(IsNewUser(googleUser: googleUser, credential: credential));
      } else {
        emit(UserSignIn());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError('Gagal masuk dengan Google: ${e.message}'));
    } catch (e) {
      emit(AuthError('Terjadi kesalahan saat masuk dengan Google: $e'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _auth.signOut();
      emit(UserSignedOut());
    } catch (e) {
      emit(AuthError('Failed to sign out: $e'));
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    emit(AuthLoading());
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _auth.currentUser!.updateDisplayName(name);
      await _auth.currentUser!.sendEmailVerification();
      await _auth.signOut();
      emit(UserSingupButNotVerified());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        emit(AuthError('The password provided is too weak.'));
      } else if (e.code == 'email-already-in-use') {
        emit(AuthError('The email address is already in use by another account.'));
      } else {
        emit(AuthError('Failed to sign up: ${e.message}'));
      }
    } catch (e) {
      emit(AuthError('An unexpected error occurred during sign up: $e'));
    }
  }
}