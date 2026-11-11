// Model data ulasan kepuasan dan saran sarpras sekolah
enum ReviewStatus {
  belumDitanggapi,
  sudahDitanggapi,
  selesaiDitindaklanjuti,
}

extension ReviewStatusX on ReviewStatus {
  String get label => switch (this) {
        ReviewStatus.belumDitanggapi => 'Perlu Ditanggapi',
        ReviewStatus.sudahDitanggapi => 'Sudah Dibalas',
        ReviewStatus.selesaiDitindaklanjuti => 'Selesai Ditindaklanjuti',
      };
}

class AppReview {
  final String id;
  final String userId;
  final String userName;
  final String userRoleLabel;
  final int rating; // 1 - 5
  final String category;
  final String comment;
  final DateTime createdAt;
  final bool isAnonymous;

  // Atribut Pengelolaan & Moderasi Admin
  final bool isVisible;
  final bool isPinned;
  final String? adminReply;
  final DateTime? adminReplyAt;
  final String? adminReplyBy;
  final ReviewStatus status;

  const AppReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRoleLabel,
    required this.rating,
    required this.category,
    required this.comment,
    required this.createdAt,
    this.isAnonymous = false,
    this.isVisible = true,
    this.isPinned = false,
    this.adminReply,
    this.adminReplyAt,
    this.adminReplyBy,
    this.status = ReviewStatus.belumDitanggapi,
  });

  String get displayName => isAnonymous ? 'Pengguna Anonim' : userName;
  String get displayRole => isAnonymous ? 'Peminjam Terverifikasi' : userRoleLabel;

  AppReview copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRoleLabel,
    int? rating,
    String? category,
    String? comment,
    DateTime? createdAt,
    bool? isAnonymous,
    bool? isVisible,
    bool? isPinned,
    String? adminReply,
    DateTime? adminReplyAt,
    String? adminReplyBy,
    ReviewStatus? status,
  }) {
    return AppReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRoleLabel: userRoleLabel ?? this.userRoleLabel,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVisible: isVisible ?? this.isVisible,
      isPinned: isPinned ?? this.isPinned,
      adminReply: adminReply ?? this.adminReply,
      adminReplyAt: adminReplyAt ?? this.adminReplyAt,
      adminReplyBy: adminReplyBy ?? this.adminReplyBy,
      status: status ?? this.status,
    );
  }
}
