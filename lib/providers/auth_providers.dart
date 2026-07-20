import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

/// Whether Firebase initialised at startup. Overridden in `main()`.
///
/// When false (no Firebase config present) the whole auth layer disables
/// itself and the app runs exactly as before — so cloning the repo without a
/// Firebase project still gives a fully working app.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  assert(ref.watch(firebaseReadyProvider),
      'AuthRepository requested but Firebase is not initialised.');
  return AuthRepository();
});

/// The signed-in user (null while signed out). Only meaningful when
/// [firebaseReadyProvider] is true.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return Stream.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// True once the visitor chose "Continue as guest" on the login screen.
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Handles submit-in-flight / error state for the login & register forms.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncValue.data(null));
  final AuthRepository _repo;

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> register(String name, String email, String password) => _run(
      () => _repo.registerWithEmail(name: name, email: email, password: password));

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> _run(Future<Result<AppUser>> Function() action) async {
    state = const AsyncValue.loading();
    final result = await action();
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<String?> sendPasswordReset(String email) async {
    final result = await _repo.sendPasswordReset(email);
    return result.when(
      success: (_) => null,
      failure: (Failure f) => f.message,
    );
  }

  void clearError() => state = const AsyncValue.data(null);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
