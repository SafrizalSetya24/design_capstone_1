import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/borrowing/borrowing_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasBorrowingListPage extends StatefulWidget {
  final int initialTab;
  const SaprasBorrowingListPage({super.key, this.initialTab = 0});

  @override
  State<SaprasBorrowingListPage> createState() => _SaprasBorrowingListPageState();
}

class _SaprasBorrowingListPageState extends State<SaprasBorrowingListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanStore>();

    final waiting = loans.withStatus({LoanStatus.menungguPersetujuan});
    final approved = loans.withStatus({LoanStatus.disetujui});
    final borrowed = loans.withStatus({LoanStatus.sedangDipinjam, LoanStatus.menungguPengembalian});
    final history = loans.withStatus({LoanStatus.selesai, LoanStatus.ditolak, LoanStatus.kedaluwarsa});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Peminjaman Barang'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Menunggu (${waiting.length})'),
            Tab(text: 'Disetujui (${approved.length})'),
            Tab(text: 'Dipinjam (${borrowed.length})'),
            Tab(text: 'Riwayat (${history.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari kode request, peminjam, atau barang...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(context, waiting, 'Tidak ada pengajuan yang menunggu persetujuan.'),
                _buildList(context, approved, 'Tidak ada pengajuan yang menunggu penyerahan unit.'),
                _buildList(context, borrowed, 'Tidak ada barang yang sedang dipinjam.'),
                _buildList(context, history, 'Belum ada arsip riwayat peminjaman.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<LoanRequest> rawList, String emptyMsg) {
    final list = rawList.where((l) {
      if (_search.isEmpty) return true;
      return l.id.toLowerCase().contains(_search) ||
          l.borrower.name.toLowerCase().contains(_search) ||
          l.borrower.identityValue.toLowerCase().contains(_search) ||
          l.summary.toLowerCase().contains(_search);
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final req = list[idx];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaprasBorrowingDetailPage(request: req)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    StatusBadge.status( req.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${req.borrower.name} • ${req.borrower.identityLabel}: ${req.borrower.identityValue} (${req.borrower.extraValue ?? req.borrower.role.label})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(req.summary, style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(
                  'Jadwal: ${Format.range(req.start, req.end)}',
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                ),
                if (req.status == LoanStatus.menungguPersetujuan) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Batas SLA 2 Jam:', style: TextStyle(fontSize: 11)),
                      CountdownBadge(deadline: req.expiresAt),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
