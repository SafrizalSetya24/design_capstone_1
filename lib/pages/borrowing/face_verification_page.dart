import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/borrowing/borrowing_success_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class FaceVerificationPage extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final String purpose;

  const FaceVerificationPage({
    super.key,
    required this.start,
    required this.end,
    required this.purpose,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  bool _scanning = false;
  bool _success = false;
  String? _error;

  Future<void> _verifyFace() async {
    setState(() {
      _scanning = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final auth = context.read<AuthStore>();
    final cart = context.read<CartStore>();
    final loans = context.read<LoanStore>();
    final user = auth.currentUser;

    if (user == null) {
      setState(() {
        _scanning = false;
        _error = 'Pengguna tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    // Buat Borrower & LoanLine
    final borrower = Borrower.fromUser(user);
    final lines = cart.items.map((ci) {
      return LoanLine(
        itemId: ci.itemId,
        itemName: ci.itemName,
        kind: ci.kind,
        satuan: ci.satuan,
        iconKey: ci.iconKey,
        qty: ci.qty,
      );
    }).toList();

    // Buat draft pengajuan peminjaman
    final request = loans.createDraft(
      borrower: borrower,
      lines: lines,
      start: widget.start,
      end: widget.end,
      purpose: widget.purpose,
    );

    // Verifikasi wajah berhasil dicocokkan
    loans.submitFace(request, ok: true, score: 0.96);

    // Kosongkan keranjang belanja
    cart.clear();

    setState(() {
      _scanning = false;
      _success = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => BorrowingSuccessPage(request: request)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Wajah Peminjam'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Alur SOP Langkah 5
                  const BorrowingFlowStepper(
                    currentStep: 5,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tanda Tangan Biometrik Peminjaman',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sesuai ketentuan keamanan sekolah, silakan lakukan verifikasi wajah sebelum pengajuan peminjaman dikirim ke Sapras.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    const SizedBox(height: 16),

                    // Kotak Kamera Depan
                    Container(
                      height: 290,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _success
                              ? Colors.green
                              : _scanning
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const FakeCamera(isFront: true),
                            Center(
                              child: Container(
                                width: 170,
                                height: 210,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(90),
                                  border: Border.all(
                                    color: _success
                                        ? Colors.green
                                        : _scanning
                                            ? Colors.yellowAccent
                                            : Colors.white.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (_scanning)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 12),
                                      Text(
                                        'Mencocokkan dengan profil wajah Anda...',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_success)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 52),
                                      SizedBox(height: 10),
                                      Text(
                                        'Verifikasi Wajah Berhasil!',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Kecocokan: 96% • Request dibuat',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ringkasan Cepat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total: ${cart.itemCount} jenis barang (${cart.totalQty} item)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text('SLA Sapras: 2 Jam', style: TextStyle(fontSize: 11.5, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      const SizedBox(height: 12),
                    ],

                    PrimaryButton(
                      label: _scanning
                          ? 'Memverifikasi...'
                          : _success
                              ? 'Sukses!'
                              : 'Verifikasi & Kirim Pengajuan',
                      icon: Icons.camera_front_outlined,
                      loading: _scanning,
                      onPressed: (_scanning || _success) ? null : _verifyFace,
                    ),
                  ],
                ),
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
