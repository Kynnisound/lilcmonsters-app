/// Utilisateur minimal. Pas de donnees personnelles d'enfant : compte
/// anonyme rattache a l'appareil, eventuellement lie plus tard au parent.
class AppUser {
  const AppUser({required this.id, this.isAnonymous = true});
  final String id;
  final bool isAnonymous;
}

/// Future implementation : FirebaseAuthService (firebase_auth).
abstract interface class AuthService {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signInAnonymously();
  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<AppUser> signInAnonymously() async =>
      _user ??= const AppUser(id: 'local-device');

  @override
  Future<void> signOut() async => _user = null;
}
