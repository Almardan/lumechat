import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/auth_user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AuthUserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Phone authentication states
class PhoneVerificationSent extends AuthState {
  final String verificationId;
  final int? resendToken;
  final String phoneNumber;

  const PhoneVerificationSent(this.verificationId, this.resendToken, this.phoneNumber);

  @override
  List<Object?> get props => [verificationId, resendToken, phoneNumber];
}

// Renamed from PhoneVerificationCompleted to PhoneAuthCredentialReceived
class PhoneAuthCredentialReceived extends AuthState {
  final AuthCredential credential;

  const PhoneAuthCredentialReceived(this.credential);

  @override
  List<Object?> get props => [credential];
}

class PhoneAuthError extends AuthState {
  final String message;

  const PhoneAuthError(this.message);

  @override
  List<Object?> get props => [message];
}