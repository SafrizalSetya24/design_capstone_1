import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Halaman formulir kritik dan saran layanan sarpras untuk siswa dan guru.
// Menggunakan layout responsif (2 kolom pada desktop/tablet, 1 kolom pada mobile).
class UserFeedbackPage extends StatefulWidget {
  final bool isSubPage;
  const UserFeedbackPage({super.key, this.isSubPage = false});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _selectedRating = 5;
  String _selectedCategory = 'Kemudahan Peminjaman';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Kemudahan Peminjaman',
    'Pelayanan Sarpras',
    'Kondisi Barang & Alat',
    'Fitur Verifikasi Wajah',
    'Umum & Saran',
  ];

  final Map<int, String> _ratingLabels = const {
    1: 'Sangat Kurang',
    2: 'Kurang Puas',
    3: 'Cukup Baik',
    4: 'Puas & Membantu',
    5: 'Sangat Memuaskan!',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Mengirim masukan pengguna ke ReviewStore
  void _submitFeedback() {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = context.read<AuthStore>().currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    final reviewStore = context.read<ReviewStore>();
    reviewStore.addReview(
      userId: currentUser.id,
      userName: currentUser.name,
      userRoleLabel: '${currentUser.role.label} - ${currentUser.identityLabel}: ${currentUser.identityValue}',
      rating: _selectedRating,
      category: _selectedCategory,
      comment: _commentController.text.trim(),
      isAnonymous: _isAnonymous,
    );

    setState(() {
      _isSubmitting = false;
      _commentController.clear();
      _selectedRating = 5;
      _selectedCategory = _categories.first;
      _isAnonymous = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text('Terima kasih! Saran & masukan Anda berhasil dikirim ke pihak Sarpras.'),
            ),
          ],
        ),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthStore>().currentUser;
    final reviewStore = context.watch<ReviewStore>();

    final myFeedbacks = currentUser == null
        ? <AppReview>[]
        : reviewStore.reviewsForUser(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kritik & Saran Layanan Sarpras'),
        leading: widget.isSubPage && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 860;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 24 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kolom Kiri: Formulir Input Masukan
                            Expanded(
                              flex: 6,
                              child: _buildFormCard(context),
                            ),
                            const SizedBox(width: 24),
                            // Kolom Kanan: Riwayat Saran Saya & Informasi Layanan
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHistorySection(context, myFeedbacks, theme),
                                  const SizedBox(height: 20),
                                  _buildInfoCard(context),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFormCard(context),
                            const SizedBox(height: 24),
                            _buildHistorySection(context, myFeedbacks, theme),
                            const SizedBox(height: 20),
                            _buildInfoCard(context),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Card Formulir Pengiriman Masukan & Saran
  Widget _buildFormCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Formulir
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulir Ulasan & Saran Pengguna',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Beri masukan atau laporkan kendala sarana prasarana sekolah',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),

            // Rating kepuasan bintang
            const Text(
              'Bagaimana Kepuasan Anda Terhadap Layanan Sarpras?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          starValue <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: starValue <= _selectedRating
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => _selectedRating = starValue),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ratingLabels[_selectedRating] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pilihan kategori masukan
            const Text(
              'Kategori Masukan',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.navy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.navy,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Kolom pesan dan saran
            const Text(
              'Kritik, Saran, atau Kendala yang Dialami',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tuliskan saran perbaikan fasilitas, kendala barang, atau masukan Anda di sini...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 5) {
                  return 'Mohon tuliskan saran atau masukan Anda (minimal 5 karakter).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Opsi kirim anonim
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: AppColors.navy),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim sebagai anonim',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                        Text(
                          'Nama dan NIS/NIK Anda tidak akan ditampilkan di ulasan publik',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Tombol kirim masukan
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting ? 'Mengirim...' : 'Kirim Saran & Masukan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Riwayat Masukan yang Pernah Dikirim Pengguna
  Widget _buildHistorySection(BuildContext context, List<AppReview> myFeedbacks, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.navy, size: 20),
            const SizedBox(width: 8),
            Text(
              'Saran & Masukan yang Pernah Anda Kirim (${myFeedbacks.length})',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (myFeedbacks.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum Ada Saran yang Dikirim',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukan Anda akan dicatat di sini beserta tanggapan resmi dari pihak sarpras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: myFeedbacks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = myFeedbacks[index];
              return _buildHistoryItemCard(context, item, theme);
            },
          ),
      ],
    );
  }

  // Card Satuan Item Riwayat
  Widget _buildHistoryItemCard(BuildContext context, AppReview item, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: Kategori & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.adminReply != null ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.adminReply != null ? const Color(0xFF86EFAC) : const Color(0xFFFED7AA),
                  ),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: item.adminReply != null ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating Bintang & Tanggal
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                Format.ago(item.createdAt),
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
              if (item.isAnonymous) ...[
                const SizedBox(width: 8),
                Text('(Anonim)', style: TextStyle(fontSize: 11, color: theme.hintColor, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Teks Masukan
          Text(
            item.comment,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),

          // Kotak Balasan Petugas Sarpras
          if (item.adminReply != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, color: Color(0xFF047857), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tanggapan Petugas (${item.adminReplyBy ?? "Sarpras"}):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF047857)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.adminReplyAt != null)
                        Text(
                          Format.ago(item.adminReplyAt!),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.adminReply!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF064E3B), height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Card Informasi Layanan Sarpras Sekolah
  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.navy),
              SizedBox(width: 8),
              Text(
                'Informasi Layanan Sarpras',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Ruang Sarana & Prasarana: Gedung Utama Lt. 1\n'
            '• Jam Pelayanan: Senin - Jumat (07.30 - 15.30 WIB)\n'
            '• Seluruh masukan dan laporan kendala ditinjau langsung oleh petugas sarpras untuk kenyamanan KBM.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.45),
          ),
        ],
      ),
    );
  }
}
