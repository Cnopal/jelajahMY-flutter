import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());

    await credential.user?.reload();

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}

String getAuthErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'An unexpected error occurred. Please try again.';
  }

  switch (error.code) {
    case 'invalid-email':
      return 'The email address is invalid.';

    case 'email-already-in-use':
      return 'An account already exists for this email.';

    case 'weak-password':
      return 'The password is too weak.';

    case 'user-disabled':
      return 'This user account has been disabled.';

    case 'user-not-found':
      return 'No account was found for this email.';

    case 'wrong-password':
      return 'The password entered is incorrect.';

    case 'invalid-credential':
      return 'The email or password is incorrect.';

    case 'operation-not-allowed':
      return 'Email and password authentication is not enabled.';

    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';

    case 'network-request-failed':
      return 'Network error. Check your internet connection.';

    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
