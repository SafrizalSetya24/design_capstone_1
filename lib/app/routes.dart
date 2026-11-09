import 'package:flutter/material.dart';
import 'package:sipintar/app/adaptive_shell.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/features/auth/account_type_page.dart';
import 'package:sipintar/features/auth/forgot_password_page.dart';
import 'package:sipintar/features/auth/onboarding_page.dart';
import 'package:sipintar/features/auth/register_page.dart';
import 'package:sipintar/features/auth/splash_page.dart';
import 'package:sipintar/features/face_verification/login_face_verification_page.dart';
import 'package:sipintar/pages/auth/login_page.dart';
import 'package:sipintar/pages/face/face_registration_page.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const accountType = '/akun';
  static const registerSiswa = '/daftar-siswa';
  static const registerGuru = '/daftar-guru';
  static const forgot = '/lupa-password';
  static const home = '/home';
  static const loginFaceVerification = '/verifikasi-wajah-masuk';
  static const faceRegistration = '/pendaftaran-wajah';

  static Route<dynamic> generate(RouteSettings s) {
    final Widget page = switch (s.name) {
      onboarding => const OnboardingPage(),
      login => const LoginPage(),
      accountType => const AccountTypePage(),
      registerSiswa => const RegisterPage(role: UserRole.siswa),
      registerGuru => const RegisterPage(role: UserRole.guru),
      forgot => const ForgotPasswordPage(),
      loginFaceVerification => const LoginFaceVerificationPage(),
      faceRegistration => const FaceRegistrationPage(),
      home => const AdaptiveShell(),
      _ => const SplashPage(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
