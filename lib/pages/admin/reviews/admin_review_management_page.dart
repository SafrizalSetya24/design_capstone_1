import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Halaman pengelolaan ulasan, kritik, dan saran untuk Admin Sarpras.
// Berfungsi untuk memoderasi ulasan, memberikan tanggapan resmi, dan mengelola konten publik.
class AdminReviewManagementPage extends StatefulWidget {
  const AdminReviewManagementPage({super.key});

  @override
  State<AdminReviewManagementPage> createState() => _AdminReviewManagementPageState();
}

class _AdminReviewManagementPageState extends State<AdminReviewManagementPage> {
  // Filter dan pencarian ulasan
  String _selectedTab = 'Semua';
  String _selectedRatingFilter = 'Semua Rating';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Template balasan cepat petugas
  final List<String> _quickReplyTemplates = const [
    'Terima kasih atas masukannya. Hal ini telah kami koordinasikan dan segera ditindaklanjuti oleh petugas sarpras.',
    'Apresiasi Anda sangat berharga bagi kami. Kami selalu berupaya memastikan seluruh fasilitas dalam kondisi prima.',
    'Kendala yang Anda sampaikan telah selesai diperbaiki dan unit terkait sudah siap digunakan kembali.',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dialog tanggapan admin
  void _showReplyDialog(BuildContext context, AppReview review) {
    final replyController = TextEditingController(text: review.adminReply ?? '');
    final formKey = GlobalKey<FormState>();
    final currentUser = context.read<AuthStore>().currentUser;
    final adminName = currentUser?.name ?? 'Administrator Sarpras';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.reply_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggapan Resmi Admin',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                        Text(
                          'Solusi atau respon dari pihak sekolah',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Ringkasan Ulasan Siswa / Guru yang Dibalas
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: review.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: '(${review.displayRole})',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 14,
                                        color: const Color(0xFFF59E0B),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '"${review.comment}"',
                                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Saran Template Cepat (One-Click Auto-Fill)
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Gunakan Template Balasan Cepat:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickReplyTemplates.map((template) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                setDialogState(() {
                                  replyController.text = template;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  template.length > 55 ? '${template.substring(0, 52)}...' : template,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Form Text Area Tanggapan
                        const Text(
                          'Pesan Tanggapan Resmi Sekolah:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: replyController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan tanggapan, klarifikasi, atau solusi dari sarpras...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 5) {
                              return 'Tanggapan minimal 5 karakter.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Simpan Tanggapan'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context.read<ReviewStore>().replyReview(
                            review.id,
                            replyController.text.trim(),
                            adminName,
                          );
                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Tanggapan resmi untuk ${review.displayName} berhasil disimpan.'),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.navy,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Konfirmasi hapus ulasan
  void _confirmDelete(BuildContext context, AppReview review) async {
    final confirmed = await confirm(
      context,
      title: 'Hapus Ulasan?',
      message: 'Ulasan dari "${review.displayName}" akan dihapus permanen dari sistem.',
      confirmLabel: 'Hapus',
      danger: true,
    );

    if (confirmed && context.mounted) {
      context.read<ReviewStore>().deleteReview(review.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan berhasil dihapus dari sistem.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Tampilan utama halaman
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewStore = context.watch<ReviewStore>();
    final allReviews = reviewStore.reviews;

    // Filter berdasarkan Tab Moderasi
    final filteredByTab = allReviews.where((r) {
      if (_selectedTab == 'Perlu Ditanggapi') {
        return r.status == ReviewStatus.belumDitanggapi && r.isVisible;
      }
      if (_selectedTab == 'Sudah Dibalas') {
        return r.adminReply != null;
      }
      if (_selectedTab == 'Disembunyikan') {
        return !r.isVisible;
      }
      return true;
    }).toList();

    // Filter berdasarkan Rating Bintang
    final filteredByRating = filteredByTab.where((r) {
      if (_selectedRatingFilter == 'Bintang 5') return r.rating == 5;
      if (_selectedRatingFilter == 'Bintang 4') return r.rating == 4;
      if (_selectedRatingFilter == 'Bintang 3') return r.rating == 3;
      if (_selectedRatingFilter == 'Bintang 1-2') return r.rating <= 2;
      return true;
    }).toList();

    // Filter berdasarkan Pencarian Kata Kunci
    final query = _searchQuery.trim().toLowerCase();
    final displayedReviews = filteredByRating.where((r) {
      if (query.isEmpty) return true;
      final matchName = r.userName.toLowerCase().contains(query);
      final matchComment = r.comment.toLowerCase().contains(query);
      final matchCategory = r.category.toLowerCase().contains(query);
      final matchReply = r.adminReply?.toLowerCase().contains(query) ?? false;
      return matchName || matchComment || matchCategory || matchReply;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengelolaan & Moderasi Ulasan'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header Pengelolaan Ulasan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.feedback_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moderasi Masukan & Saran Sarpras',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Kelola aspirasi warga sekolah dan berikan tanggapan resmi dari pihak sarpras.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // B. KPI SUMMARY METRIC CARDS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildKpiCard(
                            width: cardWidth,
                            title: 'Total Masukan',
                            value: '${reviewStore.totalReviews}',
                            subtitle: 'Rata-rata: ${reviewStore.averageRating.toStringAsFixed(1)} ★',
                            icon: Icons.rate_review_outlined,
                            color: Colors.blue,
                          ),
                          _buildKpiCard(
                            width: cardWidth,
                            title: 'Perlu Ditanggapi',
                            value: '${reviewStore.pendingReplyCount}',
                            subtitle: 'Menunggu respon',
                            icon: Icons.mark_chat_unread_outlined,
                            color: Colors.orange,
                            alert: reviewStore.pendingReplyCount > 0,
                          ),
                          _buildKpiCard(
                            width: cardWidth,
                            title: 'Sudah Dibalas',
                            value: '${reviewStore.repliedCount}',
                            subtitle: 'Solusi diberikan',
                            icon: Icons.mark_chat_read_outlined,
                            color: Colors.teal,
                          ),
                          _buildKpiCard(
                            width: cardWidth,
                            title: 'Disembunyikan',
                            value: '${reviewStore.hiddenCount}',
                            subtitle: 'Arsip / Moderasi',
                            icon: Icons.visibility_off_outlined,
                            color: Colors.blueGrey,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // C. FILTER BAR, SEARCH, & RATING SELECTOR
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar Modern
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari ulasan berdasarkan nama siswa/guru, kelas, isi masukan, atau tanggapan...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 14),

                        // Filter Tabs & Rating Filter Dropdown
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            // Tabs Status
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  'Semua',
                                  'Perlu Ditanggapi',
                                  'Sudah Dibalas',
                                  'Disembunyikan',
                                ].map((tabName) {
                                  final isSelected = _selectedTab == tabName;
                                  int count = 0;
                                  if (tabName == 'Semua') count = reviewStore.totalReviews;
                                  if (tabName == 'Perlu Ditanggapi') count = reviewStore.pendingReplyCount;
                                  if (tabName == 'Sudah Dibalas') count = reviewStore.repliedCount;
                                  if (tabName == 'Disembunyikan') count = reviewStore.hiddenCount;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text('$tabName ($count)'),
                                      selected: isSelected,
                                      selectedColor: AppColors.navy,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.navy,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedTab = tabName);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            // Filter Rating Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRatingFilter,
                                  isDense: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.navy),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                                  items: const [
                                    DropdownMenuItem(value: 'Semua Rating', child: Text('Semua Rating')),
                                    DropdownMenuItem(value: 'Bintang 5', child: Text('5 ★ Sempurna')),
                                    DropdownMenuItem(value: 'Bintang 4', child: Text('4 ★ Sangat Baik')),
                                    DropdownMenuItem(value: 'Bintang 3', child: Text('3 ★ Cukup')),
                                    DropdownMenuItem(value: 'Bintang 1-2', child: Text('1-2 ★ Perlu Perhatian')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRatingFilter = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // D. HEADER DAFTAR ULASAN & COUNTER
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.list_alt_rounded, color: AppColors.navy, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Daftar Masukan & Ulasan Pengguna (${displayedReviews.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy),
                          ),
                        ],
                      ),
                      Text(
                        'Filter: $_selectedTab • $_selectedRatingFilter',
                        style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // E. FEED KARTU MODERASI ULASAN
                  if (displayedReviews.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(36),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak Ada Ulasan yang Cocok',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tidak ditemukan ulasan berdasarkan tab "$_selectedTab" atau kata kunci pencarian Anda.',
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...displayedReviews.map((review) => _buildModerationCard(context, review)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Kartu statistik ringkasan
  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool alert = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert ? color.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
          width: alert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildModerationCard(BuildContext context, AppReview review) {
    final theme = Theme.of(context);
    final reviewStore = context.read<ReviewStore>();

    final initial = review.isAnonymous ? '?' : (review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U');

    // Tentukan warna badge kategori
    Color categoryBgColor = const Color(0xFFEFF6FF);
    Color categoryTextColor = AppColors.primary;
    if (review.category.contains('Pelayanan')) {
      categoryBgColor = const Color(0xFFECFDF5);
      categoryTextColor = const Color(0xFF059669);
    } else if (review.category.contains('Kondisi')) {
      categoryBgColor = const Color(0xFFFFFBEB);
      categoryTextColor = const Color(0xFFD97706);
    } else if (review.category.contains('Wajah')) {
      categoryBgColor = const Color(0xFFFAF5FF);
      categoryTextColor = const Color(0xFF7C3AED);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Header Pengirim, Role/Kelas, Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: review.isAnonymous ? Colors.blueGrey : AppColors.navy,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            review.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          // Badge Pin Unggulan
                          if (review.isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.push_pin, size: 12, color: Color(0xFFD97706)),
                                  SizedBox(width: 3),
                                  Text('Unggulan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                ],
                              ),
                            ),
                          // Badge Disembunyikan
                          if (!review.isVisible)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off, size: 12, color: Colors.red),
                                  SizedBox(width: 3),
                                  Text('Disembunyikan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                          // Badge Kategori
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              review.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: categoryTextColor,
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
            const SizedBox(height: 12),

            // Baris 2: Rating Bintang, Waktu Kirim, & Status Tanggapan
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 17,
                        );
                      }),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${review.rating}.0)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${Format.ago(review.createdAt)}',
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                  ],
                ),
                // Status Badge Tanggapan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: review.adminReply != null ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: review.adminReply != null ? const Color(0xFF86EFAC) : const Color(0xFFFED7AA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        review.adminReply != null ? Icons.check_circle : Icons.hourglass_top_rounded,
                        size: 12,
                        color: review.adminReply != null ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.status.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: review.adminReply != null ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 3: Isi Teks Kritik & Saran
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                review.comment,
                style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 12),

            // Baris 4: Kotak Tanggapan Resmi Sekolah (Jika Sudah Ada Balasan)
            if (review.adminReply != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
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
                            'Tanggapan Resmi (${review.adminReplyBy ?? "Admin"}):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF047857)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.adminReplyAt != null)
                          Text(
                            Format.ago(review.adminReplyAt!),
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.adminReply!,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF064E3B), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Baris 5: Tombol Aksi Moderasi (Balas, Sembunyikan, Pin, Hapus)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tombol Balas / Edit Tanggapan
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.reply, size: 16),
                  label: Text(
                    review.adminReply != null ? 'Edit Tanggapan' : 'Beri Tanggapan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showReplyDialog(context, review),
                ),

                // Tombol Sembunyikan / Tampilkan
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    foregroundColor: review.isVisible ? Colors.grey.shade700 : AppColors.primary,
                  ),
                  icon: Icon(review.isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
                  label: Text(
                    review.isVisible ? 'Sembunyikan' : 'Tampilkan ke Publik',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => reviewStore.toggleVisibility(review.id),
                ),

                // Tombol Pin / Unggulan
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    foregroundColor: review.isPinned ? const Color(0xFFD97706) : Colors.grey.shade700,
                  ),
                  icon: Icon(review.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16),
                  label: Text(
                    review.isPinned ? 'Lepas Pin' : 'Sematkan Unggulan',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => reviewStore.togglePin(review.id),
                ),

                // Tombol Hapus Ulasan
                IconButton(
                  tooltip: 'Hapus Ulasan',
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(context, review),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
