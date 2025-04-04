import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/auth_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef OTPSentCallback = void Function(String verificationId, int? resendToken);
typedef VerificationCompletedCallback = void Function(AuthCredential credential);
typedef VerificationFailedCallback = void Function(FirebaseAuthException e);

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  User? get currentUser => _firebaseAuth.currentUser;

  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Phone authentication - send OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required OTPSentCallback codeSent,
    required VerificationCompletedCallback verificationCompleted,
    required VerificationFailedCallback verificationFailed,
    required Function(String) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
    );
  }

  // Phone authentication - verify OTP
  Future<UserCredential> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    // Sign in with the credential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Sign out
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
  }

  // Create or update user in Firestore
  Future<void> saveUserToFirestore({
    required String uid,
    required String name,
    String? phoneNumber,
    String? email,
    String? profileImage,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'userId': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImage': profileImage ?? '',
      'lastSeen': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Convert Firebase User to AuthUserModel
  AuthUserModel? userFromFirebaseUser(User? user) {
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }
}