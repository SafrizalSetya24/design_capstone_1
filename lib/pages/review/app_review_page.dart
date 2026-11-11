import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'user_feedback_page.dart';
import 'admin_review_summary_page.dart';

// Router ulasan berdasarkan peran pengguna:
// Siswa/Guru diarahkan ke UserFeedbackPage (form masukan).
// Admin/Sapras diarahkan ke AdminReviewSummaryPage (rekap kepuasan).
class AppReviewPage extends StatelessWidget {
  const AppReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthStore>().currentUser;
    final bool isAdminOrSapras = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.sapras;

    if (isAdminOrSapras) {
      return const AdminReviewSummaryPage();
    }
    return const UserFeedbackPage();
  }
}
