import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/app_user.dart';

/// E-mail + Google authentication on top of Firebase Auth.
///
/// Every method returns a [Result] with an [AuthFailure] carrying a message
/// that is safe to show directly in the UI. Only construct this when Firebase
/// initialised successfully (see `firebaseReadyProvider`).
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// Emits the current user (or null) and every subsequent sign-in/out.
  Stream<AppUser?> authStateChanges() => _auth
      .authStateChanges()
      .map((u) => u == null ? null : AppUser.fromFirebase(u));

  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser.fromFirebase(u);
  }

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return AppUser.fromFirebase(cred.user!);
      });

  Future<Result<AppUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = cred.user!;
        final trimmed = name.trim();
        if (trimmed.isNotEmpty) {
          await user.updateDisplayName(trimmed);
          await user.reload();
        }
        return AppUser.fromFirebase(_auth.currentUser ?? user);
      });

  /// Google sign-in: popup on web, native account picker on mobile.
  Future<Result<AppUser>> signInWithGoogle() => _guard(() async {
        final UserCredential cred;
        if (kIsWeb) {
          cred = await _auth.signInWithPopup(GoogleAuthProvider());
        } else {
          final account = await _google.signIn();
          if (account == null) {
            throw const _CancelledException();
          }
          final tokens = await account.authentication;
          cred = await _auth.signInWithCredential(
            GoogleAuthProvider.credential(
              idToken: tokens.idToken,
              accessToken: tokens.accessToken,
            ),
          );
        }
        return AppUser.fromFirebase(cred.user!);
      });

  Future<Result<bool>> sendPasswordReset(String email) => _guard(() async {
        await _auth.sendPasswordResetEmail(email: email.trim());
        return true;
      });

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await _google.signOut();
    } catch (_) {
      // Google session teardown is best-effort; Firebase sign-out is what
      // actually ends the app session.
    }
    await _auth.signOut();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(_message(e)));
    } on _CancelledException {
      return const Err(AuthFailure('Sign-in was cancelled.'));
    } catch (e) {
      return Err(AuthFailure('Sign-in failed. Please try again. ($e)'));
    }
  }

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That e-mail address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'E-mail or password is incorrect.',
        'email-already-in-use' =>
          'An account already exists for that e-mail — try signing in.',
        'weak-password' => 'Please choose a stronger password (6+ characters).',
        'operation-not-allowed' =>
          'This sign-in method is not enabled in Firebase.',
        'too-many-requests' =>
          'Too many attempts — please wait a moment and try again.',
        'network-request-failed' => 'Check your connection and try again.',
        'popup-closed-by-user' => 'Sign-in was cancelled.',
        _ => e.message ?? 'Authentication failed. Please try again.',
      };
}

class _CancelledException implements Exception {
  const _CancelledException();
}
