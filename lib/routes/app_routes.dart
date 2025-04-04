import 'package:flutter/material.dart';
import '../presentation/screens/chat/chat_page.dart';
import '../presentation/screens/home/home_page.dart';
import '../presentation/screens/home/user_selection/user_selection_page.dart';
import '../presentation/screens/login/login_page.dart';
import '../presentation/screens/otp/otp_verification_page.dart';
import '../presentation/screens/phone_login/phone_login_page.dart';
import '../presentation/screens/profile/profile_page.dart';
import '../presentation/screens/register/register_page.dart';
import '../presentation/screens/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String phoneLogin = '/phone-login';
  static const String otpVerification = '/otp-verification';
  static const String userSelection = '/user-selection';
  static const String profile = '/profile';
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: args['chatId'],
            receiverId: args['receiverId'],
          ),
        );
      case phoneLogin:
        return MaterialPageRoute(builder: (_) => const PhoneLoginPage());
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OTPVerificationPage(
            verificationId: args['verificationId'],
            resendToken: args['resendToken'],
            phoneNumber: args['phoneNumber'],
          ),
        );
      case userSelection:
        return MaterialPageRoute(builder: (_) => const UserSelectionPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  static Widget getHomeScreen() {
    // Return the user selection page as the main screen after authentication
    return const UserSelectionPage();
  }
}