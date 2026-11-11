import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/admin/reviews/admin_review_management_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Halaman rekapitulasi penilaian dan ulasan layanan sarpras untuk Admin dan Petugas Sarpras.
class AdminReviewSummaryPage extends StatefulWidget {
  final bool isSubPage;
  const AdminReviewSummaryPage({super.key, this.isSubPage = false});

  @override
  State<AdminReviewSummaryPage> createState() => _AdminReviewSummaryPageState();
}

class _AdminReviewSummaryPageState extends State<AdminReviewSummaryPage> {
  String _selectedFilter = 'Semua';

  final List<String> _categories = const [
    'Kemudahan Peminjaman',
    'Pelayanan Sarpras',
    'Kondisi Barang & Alat',
    'Fitur Verifikasi Wajah',
    'Umum & Saran',
  ];

  void _showWriteReviewModal(BuildContext context) {
    final user = context.read<AuthStore>().currentUser;
    if (user == null) return;

    int currentRating = 5;
    String selectedCat = _categories.first;
    bool isAnonymous = false;
    final commentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ratingLabels = {
      1: 'Sangat Kurang 😞',
      2: 'Kurang Puas 😐',
      3: 'Cukup Baik 🙂',
      4: 'Puas & Membantu 😊',
      5: 'Sangat Memuaskan! 🌟',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Tulis Ulasan / Catatan Evaluasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tambahkan catatan evaluasi atau ulasan layanan inventarisMuhamka.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Beri Penilaian Bintang',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              iconSize: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              icon: Icon(
                                star <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: star <= currentRating ? const Color(0xFFF59E0B) : Colors.grey.shade400,
                              ),
                              onPressed: () => setSheetState(() => currentRating = star),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            ratingLabels[currentRating] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.navy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Kategori Masukan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((cat) {
                          final isSel = selectedCat == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.navy,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppColors.navy,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11.5,
                            ),
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedCat = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Catatan / Saran Evaluasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: commentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan catatan evaluasi atau tanggapan layanan di sini...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 5) {
                            return 'Catatan minimal 5 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kirim sebagai Anonim', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('Nama pengirim akan disamarkan', style: TextStyle(fontSize: 11.5)),
                        value: isAnonymous,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setSheetState(() => isAnonymous = val ?? false),
                      ),
                      const SizedBox(height: 18),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final store = sheetCtx.read<ReviewStore>();
                            store.addReview(
                              userId: user.id,
                              userName: user.name,
                              userRoleLabel: user.role.label,
                              rating: currentRating,
                              category: selectedCat,
                              comment: commentCtrl.text.trim(),
                              isAnonymous: isAnonymous,
                            );

                            Navigator.of(sheetCtx).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ulasan / catatan berhasil ditambahkan.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<ReviewStore>();

    final avg = store.averageRating;
    final total = store.totalReviews;

    // Filter ulasan berdasarkan bintang
    final allReviews = store.reviews;
    final filteredReviews = allReviews.where((r) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Bintang 5') return r.rating == 5;
      if (_selectedFilter == 'Bintang 4') return r.rating == 4;
      if (_selectedFilter == 'Bintang 3') return r.rating == 3;
      if (_selectedFilter == 'Bintang 1-2') return r.rating <= 2;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.isSubPage && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Ulasan & Penilaian Aplikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Pengelolaan Ulasan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminReviewManagementPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ringkasan rating dan skor
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 580;
                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildScoreSummary(avg, total),
                              ),
                              Container(
                                height: 130,
                                width: 1,
                                color: AppColors.border,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              Expanded(
                                flex: 6,
                                child: _buildRatingBars(store),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildScoreSummary(avg, total),
                              const Divider(height: 32),
                              _buildRatingBars(store),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Banner ajakan ulasan
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFD97706),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bagaimana pengalaman Anda?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: AppColors.navy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ulasan Anda sangat berharga bagi evaluasi pelayanan sarana & prasarana sekolah.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.rate_review,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'Beri Ulasan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          onPressed: () => _showWriteReviewModal(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter ulasan
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Ulasan (${filteredReviews.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Semua',
                            'Bintang 5',
                            'Bintang 4',
                            'Bintang 3',
                            'Bintang 1-2',
                          ].map((f) {
                            final isSel = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: isSel,
                                selectedColor: AppColors.navy,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppColors.navy,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 11.5,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedFilter = f);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Daftar ulasan pengguna
                  if (filteredReviews.isEmpty)
                    const AppCard(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada ulasan untuk kategori filter ini.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredReviews.map((review) => _buildReviewCard(context, review)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSummary(double avg, int total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          avg.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            return Icon(
              star <= avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFF59E0B),
              size: 22,
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Berdasarkan $total ulasan pengguna',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF15803D), size: 14),
              SizedBox(width: 4),
              Text(
                '96% Pengguna Puas',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBars(ReviewStore store) {
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = store.countForRating(star);
        final pct = store.percentageForRating(star);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewCard(BuildContext context, AppReview review) {
    final theme = Theme.of(context);
    final initial = review.isAnonymous ? '?' : (review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: review.isAnonymous ? Colors.blueGrey : AppColors.navy,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              review.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              review.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.displayRole,
                        style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  Format.ago(review.createdAt),
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
