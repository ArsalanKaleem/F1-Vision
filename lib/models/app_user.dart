import 'package:firebase_auth/firebase_auth.dart' as fb;

/// The signed-in user as the app sees it — a thin, immutable projection of the
/// Firebase user so no feature code depends on the Firebase SDK directly.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// Initials for the avatar fallback ("Lewis Hamilton" → "LH").
  String get initials {
    final source = displayName.isNotEmpty ? displayName : email;
    final parts =
        source.split(RegExp(r'[\s@._]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory AppUser.fromFirebase(fb.User user) => AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );
}
