import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SipintarLogo(size: 104, inverted: true),
                SizedBox(height: AppSpacing.lg),
                Text('SIPINTAR',
                    style: TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                SizedBox(height: AppSpacing.sm),
                Text('Kelola Inventaris Sekolah dengan Mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFBFD3F5), fontSize: 15)),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
