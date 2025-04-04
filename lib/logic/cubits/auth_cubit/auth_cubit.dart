import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository = AuthRepository();
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;
  
  // Store temporary data for phone verification
  String _tempName = '';
  String _tempPhoneNumber = '';

  AuthCubit() : super(AuthInitial()) {
    // Check if user is already authenticated
    final currentUser = _authRepository.getCurrentUser();
    if (currentUser != null) {
      emit(Authenticated(currentUser));
    } else {
      emit(Unauthenticated());
    }

    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Authentication failed.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Register with email and password
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      emit(AuthLoading());
      final user = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Registration failed.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Phone Authentication - Step 1: Send OTP
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required String name,
  }) async {
    try {
      emit(AuthLoading());
      
      // Store temp data for later use
      _tempName = name;
      _tempPhoneNumber = phoneNumber;
      
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId, int? resendToken) {
          emit(PhoneVerificationSent(verificationId, resendToken, phoneNumber));
        },
        onVerificationFailed: (FirebaseAuthException e) {
          emit(PhoneAuthError(e.message ?? 'Verification failed'));
        },
        onVerificationCompleted: (AuthCredential credential) {
          emit(PhoneAuthCredentialReceived(credential));
          _signInWithCredential(credential);
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {
          // If current state is still waiting for verification, update the state
          if (state is PhoneVerificationSent) {
            emit(PhoneVerificationSent(verificationId, null, phoneNumber));
          }
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // Phone Authentication - Step 2: Verify OTP
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      emit(AuthLoading());
      
      final user = await _authRepository.verifyOTPAndSignIn(
        verificationId: verificationId,
        smsCode: smsCode,
        name: _tempName,
        phoneNumber: _tempPhoneNumber,
      );
      
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Verification failed.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // Sign in with credential (for auto-verification)
  Future<void> _signInWithCredential(AuthCredential credential) async {
    try {
      emit(AuthLoading());
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Save user data to Firestore
        await _authService.saveUserToFirestore(
          uid: user.uid,
          name: _tempName.isEmpty ? user.displayName ?? 'User' : _tempName,
          phoneNumber: _tempPhoneNumber,
        );
        
        final authUser = _authService.userFromFirebaseUser(user);
        if (authUser != null) {
          emit(Authenticated(authUser));
        } else {
          emit(const AuthError('Authentication failed.'));
        }
      } else {
        emit(const AuthError('Authentication failed.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // Resend OTP code
  Future<void> resendOTP({
    required String phoneNumber,
    int? resendToken,
  }) async {
    try {
      emit(AuthLoading());
      
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId, int? newResendToken) {
          emit(PhoneVerificationSent(verificationId, newResendToken, phoneNumber));
        },
        onVerificationFailed: (FirebaseAuthException e) {
          emit(PhoneAuthError(e.message ?? 'Verification failed'));
        },
        onVerificationCompleted: (AuthCredential credential) {
          emit(PhoneAuthCredentialReceived(credential));
          _signInWithCredential(credential);
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {
          // Update verification ID if still waiting
          if (state is PhoneVerificationSent) {
            emit(PhoneVerificationSent(verificationId, null, phoneNumber));
          }
        },
        resendToken: resendToken,
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}