import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/face/face_registration_page.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Model pembantu untuk menampilkan hasil deteksi instan saat pengguna mengetik
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

  /// Logika cerdas pendeteksi identitas pengguna berdasarkan NIS, NUPTK, ID, atau Email
  _IdentityDetection? _detectRole(String input, AuthStore auth) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // Cek akun terdaftar berdasarkan NIS, NIK, ID, atau email
    final matched = auth.findAccount(text);
    if (matched != null) {
      final u = matched.user;
      switch (u.role) {
        case UserRole.siswa:
          return _IdentityDetection(
            role: UserRole.siswa,
            title: 'Siswa: ${u.name}',
            subtitle: 'NIS: ${u.identityValue} • Kelas: ${u.extraValue ?? "-"}',
            color: const Color(0xFF2563EB), // Blue
            icon: Icons.school_rounded,
          );
        case UserRole.guru:
          return _IdentityDetection(
            role: UserRole.guru,
            title: 'Guru: ${u.name}',
            subtitle: 'NUPTK / NIK: ${u.identityValue} • ${u.extraValue ?? "Tenaga Pendidik"}',
            color: const Color(0xFF0D9488), // Teal
            icon: Icons.person_pin_rounded,
          );
        case UserRole.sapras:
          return _IdentityDetection(
            role: UserRole.sapras,
            title: 'Petugas Sapras: ${u.name}',
            subtitle: 'ID: ${u.identityValue} • Petugas Inventaris',
            color: const Color(0xFFD97706), // Amber
            icon: Icons.build_circle_rounded,
          );
        case UserRole.admin:
          return _IdentityDetection(
            role: UserRole.admin,
            title: 'Admin: ${u.name}',
            subtitle: 'ID: ${u.identityValue} • Administrator Sistem',
            color: const Color(0xFF9333EA), // Purple
            icon: Icons.admin_panel_settings_rounded,
          );
      }
    }

    // Deteksi berdasarkan pola digit angka jika belum cocok persis dengan data akun
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(text);
    if (isDigitsOnly) {
      if (text.length >= 15) {
        return _IdentityDetection(
          role: UserRole.guru,
          title: 'Format NIK (Guru / Tenaga Pendidik)',
          subtitle: 'Terdeteksi ${text.length} digit (Standar NIK: 16 digit)',
          color: const Color(0xFF0D9488),
          icon: Icons.person_pin_rounded,
        );
      } else {
        return const _IdentityDetection(
          role: UserRole.siswa,
          title: 'Format NIS (Siswa)',
          subtitle: 'Mendeteksi nomor induk siswa sekolah',
          color: Color(0xFF2563EB),
          icon: Icons.school_rounded,
        );
      }
    }

    if (text.contains('@')) {
      return const _IdentityDetection(
        role: null,
        title: 'Format Email Pengguna',
        subtitle: 'Mendeteksi kredensial via alamat surel resmi',
        color: Color(0xFF4F46E5),
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

    await Future.delayed(const Duration(milliseconds: 500));
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

    // Jika biometrik wajah siswa/guru belum didaftarkan, arahkan ke registrasi wajah
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
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    final formWidget = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFormHeader(isDesktop: isDesktop, theme: theme),

          // Label Input Nomor Identitas
          const Text(
            'Nomor Identitas (NIS / NIK / Email)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _identifierCtrl,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Contoh: 22090044 atau 24090106...',
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

          // Smart Badge Deteksi Otomatis Real-Time
          if (detection != null) ...[
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: detection.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: detection.color.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: detection.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(detection.icon, size: 16, color: detection.color),
                  ),
                  const SizedBox(width: 10),
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

          const SizedBox(height: 14),

          // Label Input Kata Sandi
          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Masukkan kata sandi Anda',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
          ),
          const SizedBox(height: 14),

          // Pesan Error Jika Login Gagal
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Tombol Masuk Utama
          PrimaryButton(
            label: 'Masuk Aplikasi',
            icon: Icons.login_rounded,
            loading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 14),

          // Kotak Informasi Akun Resmi Sekolah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Akun Siswa dan Guru dibuat oleh Admin Sekolah. Jika belum memiliki akun, silakan hubungi petugas Admin / Sarpras.',
                    style: TextStyle(fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Akses Cepat Pengujian Mode Demo (Layout 2x2 Grid Rapi & Informatif)
          _buildDemoSection(),
        ],
      ),
    );

    // ==========================================
    // Tampilan Desktop (Split-Screen Modern)
    // ==========================================
    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // Sisi Kiri: Hero Banner Informasi & Branding Sekolah
            Expanded(
              flex: 6,
              child: _buildHeroPanel(context, theme),
            ),

            // Sisi Kanan: Form Autentikasi Pengguna
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: formWidget,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================
    // Tampilan Mobile / Layar Kecil
    // ==========================================
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: formWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Header Form Login
  // ==========================================
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 24,
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
                      'Gunakan akun sekolah Anda untuk mengakses sistem',
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
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'InventarisMuhamka',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistem Inventaris & Peminjaman Sarpras\nSMK Muhammadiyah 1 Sukoharjo',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // ==========================================
  // Akses Cepat Demo (2x2 Grid Rapi)
  // ==========================================
  Widget _buildDemoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Akses Cepat Pengujian (Mode Demo):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Baris 1: Siswa & Guru
          Row(
            children: [
              Expanded(
                child: _buildDemoCard(
                  roleLabel: 'Siswa',
                  nameLabel: 'Safrizal',
                  idLabel: 'NIS 22090044',
                  icon: Icons.school_rounded,
                  accentColor: const Color(0xFF1D4ED8),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () => _fillInput('22090044', 'sipintar123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDemoCard(
                  roleLabel: 'Guru',
                  nameLabel: 'Ade Anang',
                  idLabel: 'NUPTK 24090106',
                  icon: Icons.person_rounded,
                  accentColor: const Color(0xFF0F766E),
                  bgColor: const Color(0xFFF0FDFA),
                  onTap: () => _fillInput('24090106', 'sipintar123'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Baris 2: Sarpras & Admin
          Row(
            children: [
              Expanded(
                child: _buildDemoCard(
                  roleLabel: 'Sapras',
                  nameLabel: 'M. Fajar',
                  idLabel: 'ID 24090133',
                  icon: Icons.build_rounded,
                  accentColor: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFFFBEB),
                  onTap: () => _fillInput('24090133', 'sipintar123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDemoCard(
                  roleLabel: 'Admin',
                  nameLabel: 'Irfan',
                  idLabel: 'ID 24090107',
                  icon: Icons.admin_panel_settings_rounded,
                  accentColor: const Color(0xFF7E22CE),
                  bgColor: const Color(0xFFFAF5FF),
                  onTap: () => _fillInput('24090107', 'sipintar123'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Link Simulasi Pendaftaran Wajah Siswa Baru
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _fillInput('2024001455', 'sipintar123'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Simulasi Siswa Baru (Wajah Belum Terdaftar) →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Komponen kartu individual demo peran
  Widget _buildDemoCard({
    required String roleLabel,
    required String nameLabel,
    required String idLabel,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      nameLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      idLabel,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Panel Hero Showcase Sisi Kiri (Desktop) - Modern Bento Showcase
  // ==========================================
  Widget _buildHeroPanel(BuildContext context, ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF070E1A), // Midnight Obsidian
            Color(0xFF0D1B2E), // Modern Deep Slate Navy
            Color(0xFF13253E), // Soft Ambient Indigo
          ],
        ),
      ),
      child: Stack(
        children: [
          // Aksen Cahaya Ambient Halus di Latar Belakang
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
          ),

          // Konten Utama Hero yang Terpusat & Terproporsi Rapi
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand & Identitas Sekolah
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const SipintarLogo(size: 34, inverted: true),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMK MUHAMMADIYAH 1 SUKOHARJO',
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'inventarisMuhamka',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, size: 12, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text(
                                'Portal Resmi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Headline Utama & Deskripsi
                    const Text(
                      'Peminjaman Sarana & Prasarana Sekolah Lebih Cepat, Tertib, dan Terdata.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform digital sarpras sekolah berbasis biometrik wajah siswa & guru, anti-tabrakan jadwal, serta approval terstandarisasi SLA 2 jam.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // Modern Bento Showcase Layout
                    // ==========================================
                    // Bento Card 1: Biometrik Face Recognition (Featured Wide Card)
                    _buildBentoFaceCard(),
                    const SizedBox(height: 12),

                    // Bento Card 2 & 3: Side-by-Side Dual-Katalog & SLA 2 Jam
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildBentoDualCatalogCard(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBentoSlaCard(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Catatan Keamanan Tunggal & Versi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 15, color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Single-School Security • Login NIS (Siswa) & NIK (Guru)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            'T.A. 2026/2027',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bento Card 1: Biometrik Face Recognition (Hero Card)
  // ==========================================
  Widget _buildBentoFaceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0284C7).withValues(alpha: 0.18),
            const Color(0xFF0F172A).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Viewfinder Kamera Face Scan
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0369A1).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: Color(0xFF38BDF8),
                  size: 26,
                ),
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Biometrik Face Recognition',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI VERIFIED',
                        style: TextStyle(
                          color: Color(0xFF7DD3FC),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Verifikasi biometrik wajah otomatis sebelum pengajuan untuk menjamin validitas peminjam tanpa joki.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF34D399)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Simulasi: Safrizal S. (Siswa) • Terverifikasi',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bento Card 2: Dual-Katalog & Mixed Cart
  // ==========================================
  Widget _buildBentoDualCatalogCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD97706).withValues(alpha: 0.14),
            const Color(0xFF0F172A).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: Color(0xFFFBBF24),
                  size: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MIXED',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Dual-Katalog & Mixed Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            'Peminjaman unit inventaris wajib kembali & barang habis pakai (ATK) dalam satu alur terpadu.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildBentoMiniPill('💻 Laptop', const Color(0xFF38BDF8)),
              _buildBentoMiniPill('🖊️ ATK', const Color(0xFFFBBF24)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bento Card 3: Approval SLA 2 Jam Sarpras
  // ==========================================
  Widget _buildBentoSlaCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.14),
            const Color(0xFF0F172A).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF34D399),
                  size: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SLA 2H',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Approval SLA 2 Jam Sarpras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            'Persetujuan terpantau dengan standar waktu respons maksimal 2 jam oleh petugas sarpras.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF34D399)),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'SLA Respons < 2 Jam',
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMiniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
