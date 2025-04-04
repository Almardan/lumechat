import '../../core/services/auth_service.dart';
import '../models/auth_user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  
  // Constructor to support singleton pattern
  static final AuthRepository _instance = AuthRepository._internal();
  
  factory AuthRepository() {
    return _instance;
  }
  
  AuthRepository._internal();

  // Get current authenticated user
  AuthUserModel? getCurrentUser() {
    final user = _authService.currentUser;
    return _authService.userFromFirebaseUser(user);
  }

  // Get authentication state stream
  Stream<AuthUserModel?> get authStateChanges {
    return _authService.authStateChanges.map((User? user) {
      return _authService.userFromFirebaseUser(user);
    });
  }

  // Sign in with email and password
  Future<AuthUserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _authService.userFromFirebaseUser(credential.user);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Register with email and password
  Future<AuthUserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(
          displayName: name,
        );
        
        // Save user to Firestore
        await _authService.saveUserToFirestore(
          uid: user.uid,
          name: name,
          email: email,
        );
        
        return _authService.userFromFirebaseUser(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Phone auth - Send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(AuthCredential) onVerificationCompleted,
    required Function(String) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: onCodeSent,
      verificationFailed: onVerificationFailed,
      verificationCompleted: onVerificationCompleted,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      resendToken: resendToken,
    );
  }

  // Phone auth - Verify OTP
  Future<AuthUserModel?> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _authService.verifyOTPAndSignIn(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final user = credential.user;
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(
          displayName: name,
        );
        
        // Save user to Firestore
        await _authService.saveUserToFirestore(
          uid: user.uid,
          name: name,
          phoneNumber: phoneNumber,
        );
        
        return _authService.userFromFirebaseUser(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Handle Firebase Auth exceptions
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The email address is already in use.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'invalid-verification-code':
        return Exception('The verification code is invalid.');
      case 'invalid-verification-id':
        return Exception('The verification ID is invalid.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'invalid-phone-number':
        return Exception('The phone number is invalid. Please use international format (e.g., +1234567890).');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}