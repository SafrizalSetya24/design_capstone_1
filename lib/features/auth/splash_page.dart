import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/stores/auth_store.dart';
import '../../shared/widgets/sipintar_logo.dart';
import 'package:sipintar/app/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      if (auth.currentUser != null) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      } else {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(AppRoutes.onboarding, (_) => false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SipintarLogo(size: 104, inverted: true),
                SizedBox(height: AppSpacing.lg),
                Text('SIPINTAR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                SizedBox(height: AppSpacing.sm),
                Text('Kelola Inventaris Sekolah dengan Mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFBFD3F5), fontSize: 15)),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.6, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
