import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/face/face_registration_page.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class _IdentityDetection {
  final UserRole? role;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _IdentityDetection({
    this.role,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _identifierCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  _IdentityDetection? _detectRole(String input, AuthStore auth) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // 1. Cek kecocokan langsung ke akun terdaftar (NIS, NIK, ID, Email)
    final matched = auth.findAccount(text);
    if (matched != null) {
      final u = matched.user;
      switch (u.role) {
        case UserRole.siswa:
          return _IdentityDetection(
            role: UserRole.siswa,
            title: 'Siswa: ${u.name}',
            subtitle: 'NIS: ${u.identityValue} • Kelas: ${u.extraValue ?? "-"}',
            color: AppColors.primary,
            icon: Icons.school_rounded,
          );
        case UserRole.guru:
          return _IdentityDetection(
            role: UserRole.guru,
            title: 'Guru: ${u.name}',
            subtitle: 'NIK: ${u.identityValue} • ${u.extraValue ?? "Tenaga Pendidik"}',
            color: Colors.teal,
            icon: Icons.person_pin_rounded,
          );
        case UserRole.sapras:
          return _IdentityDetection(
            role: UserRole.sapras,
            title: 'Petugas Sapras: ${u.name}',
            subtitle: 'ID: ${u.identityValue}',
            color: Colors.orange.shade800,
            icon: Icons.build_rounded,
          );
        case UserRole.admin:
          return _IdentityDetection(
            role: UserRole.admin,
            title: 'Admin: ${u.name}',
            subtitle: 'ID: ${u.identityValue}',
            color: Colors.purple,
            icon: Icons.admin_panel_settings_rounded,
          );
      }
    }

    // 2. Jika belum cocok persis, deteksi format angka
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(text);
    if (isDigitsOnly) {
      if (text.length >= 15) {
        return _IdentityDetection(
          role: UserRole.guru,
          title: 'Format NIK (Guru / Tenaga Pendidik)',
          subtitle: 'Terdeteksi ${text.length} digit (Standar NIK: 16 digit)',
          color: Colors.teal,
          icon: Icons.person_pin_rounded,
        );
      } else {
        return _IdentityDetection(
          role: UserRole.siswa,
          title: 'Format NIS (Siswa)',
          subtitle: 'Terdeteksi ${text.length} digit nomor induk siswa',
          color: AppColors.primary,
          icon: Icons.school_rounded,
        );
      }
    }

    if (text.contains('@')) {
      return const _IdentityDetection(
        role: null,
        title: 'Format Email Pengguna',
        subtitle: 'Mendeteksi login menggunakan email',
        color: Colors.indigo,
        icon: Icons.mail_outline_rounded,
      );
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final auth = context.read<AuthStore>();
    final err = auth.login(_identifierCtrl.text.trim(), _passwordCtrl.text);

    if (err != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = err;
      });
      return;
    }

    setState(() => _isLoading = false);

    // Cek Face Profile sesuai Dokumen Spesifikasi Alur 3 & 4
    if (!auth.isFaceRegistered()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FaceRegistrationPage()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  void _fillDemo(String id) {
    final auth = context.read<AuthStore>();
    auth.demoLogin(id);
    if (!auth.isFaceRegistered()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FaceRegistrationPage()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  void _fillInput(String identifier, String password) {
    setState(() {
      _identifierCtrl.text = identifier;
      _passwordCtrl.text = password;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthStore>();
    final detection = _detectRole(_identifierCtrl.text, auth);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final formWidget = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormHeader(isDesktop: isDesktop, theme: theme),

                      // Input NIS / NIK
                      const Text(
                        'Nomor Identitas (NIS / NIK / Email)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _identifierCtrl,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Contoh: 2024001234 atau 337401...',
                          prefixIcon: Icon(
                            detection?.icon ?? Icons.badge_outlined,
                            color: detection?.color ?? theme.hintColor,
                          ),
                          suffixIcon: _identifierCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _identifierCtrl.clear(),
                                )
                              : null,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nomor identitas (NIS / NIK) wajib diisi'
                            : null,
                      ),

                      // Badge Deteksi Otomatis
                      if (detection != null) ...[
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: detection.color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: detection.color.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(detection.icon,
                                  size: 18, color: detection.color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detection.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: detection.color,
                                      ),
                                    ),
                                    Text(
                                      detection.subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Input Password
                      const Text(
                        'Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password Anda',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tombol Masuk
                      PrimaryButton(
                        label: 'Masuk Aplikasi',
                        icon: Icons.login,
                        loading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),

                      // Info akun
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun Siswa dan Guru dibuat oleh Admin Sekolah. Jika belum memiliki akun, silakan hubungi petugas Admin / Sarpras.',
                                style: TextStyle(fontSize: 11.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Demo Quick Access Chips
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Akses Cepat Pengujian (Mode Demo):',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFF93C5FD), width: 1.2),
                            avatar: const Icon(Icons.school, size: 15, color: Color(0xFF1D4ED8)),
                            label: const Text('Siswa (NIS: 2024001234)',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF))),
                            onPressed: () => _fillInput('2024001234', 'sipintar123'),
                          ),
                          ActionChip(
                            backgroundColor: const Color(0xFFF0FDFA),
                            side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.2),
                            avatar: const Icon(Icons.person, size: 15, color: Color(0xFF0F766E)),
                            label: const Text('Guru (NIK: 337401...)',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF115E59))),
                            onPressed: () => _fillInput('3374012345670001', 'sipintar123'),
                          ),
                          ActionChip(
                            backgroundColor: const Color(0xFFEEF2FF),
                            side: const BorderSide(color: Color(0xFFA5B4FC), width: 1.2),
                            avatar: const Icon(Icons.face_retouching_natural,
                                size: 15, color: Color(0xFF4338CA)),
                            label: const Text('Siswa Baru (Face Reg)',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3730A3))),
                            onPressed: () => _fillDemo('sw4'),
                          ),
                          ActionChip(
                            backgroundColor: const Color(0xFFFFFBEB),
                            side: const BorderSide(color: Color(0xFFFCD34D), width: 1.2),
                            avatar: const Icon(Icons.build, size: 15, color: Color(0xFFB45309)),
                            label: const Text('Sapras',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E))),
                            onPressed: () => _fillDemo('sp1'),
                          ),
                          ActionChip(
                            backgroundColor: const Color(0xFFFAF5FF),
                            side: const BorderSide(color: Color(0xFFD8B4FE), width: 1.2),
                            avatar: const Icon(Icons.admin_panel_settings,
                                size: 15, color: Color(0xFF7E22CE)),
                            label: const Text('Admin',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B21A8))),
                            onPressed: () => _fillDemo('ad1'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Panel Kiri: Hero Showcase
            Expanded(
              flex: 5,
              child: _buildHeroPanel(context, theme),
            ),

            // Panel Kanan: Form Login
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AppCard(
                        padding: const EdgeInsets.all(32),
                        child: formWidget,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tampilan Mobile / Layar Kecil
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: formWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader({required bool isDesktop, required ThemeData theme}) {
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masuk Aplikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'Silakan login menggunakan akun sekolah Anda',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      );
    }

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'InventarisMuhamka',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistem Inventaris & Peminjaman Sarpras\nSMK Muhammadiyah 1 Sukoharjo',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildHeroPanel(BuildContext context, ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A35),
            Color(0xFF0B2A5B),
            Color(0xFF143E78),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Decorative Accents
          Positioned(
            top: -70,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 42),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 84,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // School Brand Header
                  Row(
                    children: [
                      const SipintarLogo(size: 46, inverted: true),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMK MUHAMMADIYAH 1 SUKOHARJO',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Text(
                            'inventarisMuhamka',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Headline Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: Color(0xFFFBBF24)),
                        SizedBox(width: 8),
                        Text(
                          'Sistem Inventaris Sekolah Terintegrasi',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Peminjaman Sarana & Prasarana Sekolah Lebih Cepat, Tertib, dan Terdata.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Platform digital sarpras sekolah berbasis biometrik wajah siswa & guru, anti-tabrakan jadwal, serta approval terstandarisasi SLA 2 jam.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3 Feature Cards
                  _buildFeatureCard(
                    icon: Icons.face_retouching_natural_rounded,
                    title: 'Biometrik Face Recognition',
                    desc: 'Verifikasi wajah siswa/guru sebelum pengajuan untuk menjamin akuntabilitas tanpa joki.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.category_rounded,
                    title: 'Dual-Katalog & Mixed Cart',
                    desc: 'Peminjaman multi-item: barang per unit wajib kembali dan barang habis pakai (ATK) dalam 1 alur.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.timer_outlined,
                    title: 'Approval SLA 2 Jam Sarpras',
                    desc: 'Persetujuan reservasi dengan hitung mundur otomatis dan penentuan unit fisik oleh petugas.',
                  ),
                  const SizedBox(height: 36),

                  // Footer Security Notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 16, color: Colors.white.withValues(alpha: 0.75)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Single-School Security • Login NIS (Siswa) & NIK (Guru)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
