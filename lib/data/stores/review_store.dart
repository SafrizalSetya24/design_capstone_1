import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

// State management untuk ulasan dan kepuasan pengguna.
// Menghitung metrik rata-rata rating serta menangani moderasi dan tanggapan admin.
class ReviewStore extends ChangeNotifier {
  /// Koleksi ulasan realistis dari siswa dan guru untuk demonstrasi aplikasi
  final List<AppReview> _reviews = [
    AppReview(
      id: 'rev-1',
      userId: 'sw1',
      userName: 'Safrizal Setya Wira Budiman',
      userRoleLabel: 'Siswa - XI RPL 1',
      rating: 5,
      category: 'Kemudahan Peminjaman',
      comment:
          'Proses pinjam laptop dan proyektor untuk presentasi kelompok jadi jauh lebih cepat dan tertib. Tidak perlu antre manual di ruang sarpras lagi!',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      status: ReviewStatus.belumDitanggapi,
    ),
    AppReview(
      id: 'rev-2',
      userId: 'gr1',
      userName: 'Ade Anang Kurniawan',
      userRoleLabel: 'Guru - Informatika',
      rating: 5,
      category: 'Pelayanan Sarpras',
      comment:
          'Sangat membantu efisiensi mengajar di lab komputer. Approval Sarpras cepat sesuai SLA 2 jam dan unit laptop yang diserahkan selalu siap pakai.',
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      adminReply:
          'Terima kasih atas apresiasinya Pak Ade. Petugas sarpras selalu memastikan baterai dan kondisi laptop siap pakai sebelum jam KBM dimulai.',
      adminReplyAt: DateTime.now().subtract(const Duration(days: 2)),
      adminReplyBy: 'Petugas Sarpras (M. Fajar Ramadhan)',
      status: ReviewStatus.sudahDitanggapi,
      isPinned: true,
    ),
    AppReview(
      id: 'rev-3',
      userId: 'sw2',
      userName: 'Aulia Rahma',
      userRoleLabel: 'Siswa - X TKJ 2',
      rating: 4,
      category: 'Fitur Verifikasi Wajah',
      comment:
          'Fitur face verification di kamera depan sangat futuristik dan aman, jadi tidak bisa dijokiin teman. Desain aplikasinya juga rapi dan modern.',
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 8)),
      status: ReviewStatus.belumDitanggapi,
    ),
    AppReview(
      id: 'rev-4',
      userId: 'sw3',
      userName: 'Dimas Saputra',
      userRoleLabel: 'Siswa - XII MM 1',
      rating: 5,
      category: 'Kondisi Barang & Alat',
      comment:
          'Kamera DSLR dan tripod yang dipinjam dari sarpras kondisinya sangat prima dan baterainya sudah terisi penuh. Recommended banget!',
      createdAt: DateTime.now().subtract(const Duration(days: 7, hours: 1)),
      status: ReviewStatus.belumDitanggapi,
    ),
    AppReview(
      id: 'rev-5',
      userId: 'gr2',
      userName: 'Ahmad Fauzi, S.Kom.',
      userRoleLabel: 'Wali kelas XI RPL 1',
      rating: 4,
      category: 'Umum & Saran',
      comment:
          'Aplikasi sangat responsif di laptop dan HP. Saran untuk ke depannya bisa ditambahkan opsi perpanjangan waktu pinjam secara otomatis jika alat belum ada antrean berikutnya.',
      createdAt: DateTime.now().subtract(const Duration(days: 9, hours: 4)),
      adminReply:
          'Saran yang sangat solutif Pak Ahmad. Fitur perpanjangan otomatis jika unit tidak ada antrean sedang kami siapkan untuk rilis pembaruan berikutnya.',
      adminReplyAt: DateTime.now().subtract(const Duration(days: 8)),
      adminReplyBy: 'Administrator Sistem (Irfan Maulana Saputra)',
      status: ReviewStatus.selesaiDitindaklanjuti,
    ),
  ];

  /// Seluruh daftar ulasan di sistem (untuk Admin)
  List<AppReview> get reviews => List.unmodifiable(_reviews);

  /// Daftar ulasan yang dipublikasikan (untuk umum)
  List<AppReview> get publicReviews =>
      _reviews.where((review) => review.isVisible).toList();

  // Metrik dan statistik penilaian
  /// Skor rata-rata bintang dari skala 1.0 sampai 5.0
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final totalStars = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return totalStars / _reviews.length;
  }

  /// Total ulasan yang terkumpul
  int get totalReviews => _reviews.length;

  /// Mengambil daftar ulasan / saran yang dikirim oleh pengguna tertentu
  List<AppReview> reviewsForUser(String userId) =>
      _reviews.where((review) => review.userId == userId).toList();

  /// Jumlah ulasan untuk rating bintang tertentu (1, 2, 3, 4, 5)
  int countForRating(int starRating) =>
      _reviews.where((review) => review.rating == starRating).length;

  /// Persentase ulasan untuk rating bintang tertentu (0.0 sampai 1.0)
  double percentageForRating(int starRating) {
    if (_reviews.isEmpty) return 0.0;
    return countForRating(starRating) / _reviews.length;
  }

  // Statistik moderasi admin
  int get pendingReplyCount =>
      _reviews.where((r) => r.status == ReviewStatus.belumDitanggapi && r.isVisible).length;

  int get repliedCount =>
      _reviews.where((r) => r.adminReply != null).length;

  int get hiddenCount =>
      _reviews.where((r) => !r.isVisible).length;

  // Simpan ulasan baru
  void addReview({
    required String userId,
    required String userName,
    required String userRoleLabel,
    required int rating,
    required String category,
    required String comment,
    bool isAnonymous = false,
  }) {
    final newReview = AppReview(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userRoleLabel: userRoleLabel,
      rating: rating,
      category: category,
      comment: comment,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      status: ReviewStatus.belumDitanggapi,
    );

    // Sisipkan ulasan baru di baris paling atas feed
    _reviews.insert(0, newReview);
    notifyListeners();
  }

  // Moderasi ulasan oleh admin
  /// Memberikan tanggapan resmi dari Admin / Petugas Sarpras
  void replyReview(String reviewId, String replyMessage, String adminName) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index >= 0) {
      _reviews[index] = _reviews[index].copyWith(
        adminReply: replyMessage.trim(),
        adminReplyAt: DateTime.now(),
        adminReplyBy: adminName.trim(),
        status: ReviewStatus.sudahDitanggapi,
      );
      notifyListeners();
    }
  }

  /// Menandai ulasan selesai ditindaklanjuti
  void markResolved(String reviewId) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index >= 0) {
      _reviews[index] = _reviews[index].copyWith(
        status: ReviewStatus.selesaiDitindaklanjuti,
      );
      notifyListeners();
    }
  }

  /// Menyembunyikan atau menampilkan ulasan dari publik (Moderasi Konten)
  void toggleVisibility(String reviewId) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index >= 0) {
      final currentVisible = _reviews[index].isVisible;
      _reviews[index] = _reviews[index].copyWith(isVisible: !currentVisible);
      notifyListeners();
    }
  }

  /// Menyematkan ulasan sebagai testimoni unggulan
  void togglePin(String reviewId) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index >= 0) {
      final currentPin = _reviews[index].isPinned;
      _reviews[index] = _reviews[index].copyWith(isPinned: !currentPin);
      notifyListeners();
    }
  }

  /// Menghapus ulasan secara permanen (misal: spam atau kata kasar)
  void deleteReview(String reviewId) {
    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }
}
