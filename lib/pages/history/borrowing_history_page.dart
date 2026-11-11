import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/history/borrowing_detail_history_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class BorrowingHistoryPage extends StatefulWidget {
  final bool isSubPage;
  const BorrowingHistoryPage({super.key, this.isSubPage = false});

  @override
  State<BorrowingHistoryPage> createState() => _BorrowingHistoryPageState();
}

class _BorrowingHistoryPageState extends State<BorrowingHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging || _tabController.index != _selectedTab) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final loans = context.watch<LoanStore>();

    final allUserLoans =
        user == null ? <LoanRequest>[] : loans.forUser(user.id);

    // Sedang berlangsung
    final ongoing = allUserLoans
        .where((l) =>
            l.status == LoanStatus.menungguPersetujuan ||
            l.status == LoanStatus.disetujui ||
            l.status == LoanStatus.sedangDipinjam ||
            l.status == LoanStatus.menungguPengembalian)
        .toList();

    // Selesai
    final completed =
        allUserLoans.where((l) => l.status == LoanStatus.selesai).toList();

    // Ditolak atau kedaluwarsa
    final rejectedOrExpired = allUserLoans
        .where((l) =>
            l.status == LoanStatus.ditolak ||
            l.status == LoanStatus.kedaluwarsa)
        .toList();

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
        title: const Text('Riwayat Peminjaman'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (idx) => setState(() => _selectedTab = idx),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Berlangsung (${ongoing.length})'),
            Tab(text: 'Selesai (${completed.length})'),
            Tab(text: 'Ditolak/Expired (${rejectedOrExpired.length})'),
          ],
        ),
      ),
      body: switch (_selectedTab) {
        0 => _buildLoanList(context, ongoing,
            'Tidak ada peminjaman yang sedang berlangsung.'),
        1 => _buildLoanList(
            context, completed, 'Belum ada riwayat peminjaman selesai.'),
        _ => _buildLoanList(context, rejectedOrExpired,
            'Tidak ada pengajuan yang ditolak atau kedaluwarsa.'),
      },
    );
  }

  Widget _buildLoanList(
      BuildContext context, List<LoanRequest> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off,
                  size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(emptyMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final req = list[idx];
            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => BorrowingDetailHistoryPage(request: req)),
              ),
              borderRadius: BorderRadius.circular(12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          req.id,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary),
                        ),
                        StatusBadge.status(req.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      req.summary,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadwal: ${Format.range(req.start, req.end)}',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keperluan: ${req.purpose}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (req.status == LoanStatus.menungguPersetujuan) ...[
                      const SizedBox(height: 10),
                      CountdownBadge(deadline: req.expiresAt),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
