import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/cubits/auth_cubit/auth_cubit.dart';
import '../../../logic/cubits/auth_cubit/auth_state.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/auth/otp_verification_form.dart';

class OTPVerificationPage extends StatelessWidget {
  final String verificationId;
  final int? resendToken;
  final String phoneNumber;

  const OTPVerificationPage({
    super.key,
    required this.verificationId,
    this.resendToken,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Verify Phone',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Navigate to home page when authenticated
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PhoneVerificationSent) {
            // Show success message for resent code
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code resent successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PhoneAuthCredentialReceived) {
            // Show loading message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone verified automatically, signing in...'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Phone icon
                  const Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Verification Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone number
                  Text(
                    'Code sent to $phoneNumber',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // OTP verification form
                  OTPVerificationForm(
                    verificationId: verificationId,
                    phoneNumber: phoneNumber,
                    resendToken: resendToken,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}