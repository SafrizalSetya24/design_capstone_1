import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_detail_page.dart';
import 'package:sipintar/features/consumables/consumable_user_pages.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _status = 'Semua';
  DateTimeRange? _range;

  static const _loanOpts = [
    'Semua',
    'Menunggu persetujuan',
    'Disetujui',
    'Ditolak',
    'Booking kedaluwarsa',
    'Sedang dipinjam'
  ];
  static const _consOpts = [
    'Semua',
    'Menunggu persetujuan',
    'Disetujui',
    'Ditolak',
    'Sudah diserahkan'
  ];

  bool _inRange(DateTime d) =>
      _range == null ||
      (!d.isBefore(_range!.start) &&
          d.isBefore(_range!.end.add(const Duration(days: 1))));

  bool _loanMatch(LoanStatus s, String o) {
    switch (o) {
      case 'Menunggu persetujuan':
        return const {
          LoanStatus.menungguVerifikasiWajah,
          LoanStatus.verifikasiBerhasil,
          LoanStatus.menungguPersetujuan
        }.contains(s);
      case 'Disetujui':
        return s == LoanStatus.disetujui;
      case 'Ditolak':
        return s == LoanStatus.ditolak;
      case 'Booking kedaluwarsa':
        return s == LoanStatus.kedaluwarsa;
      case 'Sedang dipinjam':
        return s == LoanStatus.sedangDipinjam ||
            s == LoanStatus.menungguPengembalian;
      default:
        return true;
    }
  }

  bool _consMatch(ConsumableStatus s, String o) => switch (o) {
        'Menunggu persetujuan' => s == ConsumableStatus.menunggu,
        'Disetujui' => s == ConsumableStatus.disetujui,
        'Ditolak' => s == ConsumableStatus.ditolak,
        'Sudah diserahkan' => s == ConsumableStatus.diserahkan,
        _ => true,
      };

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  Widget _filters(List<String>? opts) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (opts != null)
            FilterRow(
                label: 'Status',
                options: opts,
                selected: opts.contains(_status) ? _status : 'Semua',
                onSelected: (v) => setState(() => _status = v)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_range == null
                      ? 'Filter tanggal'
                      : '${Fmt.date(_range!.start)} - ${Fmt.date(_range!.end)}'),
                ),
                if (_range != null)
                  TextButton(
                      onPressed: () => setState(() => _range = null),
                      child: const Text('Hapus tanggal')),
              ]),
        ]),
      );

  Widget _list(List<Widget> cards, String empty) => cards.isEmpty
      ? SizedBox(
          height: 260,
          child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Belum ada data',
              message: empty))
      : ResponsiveGrid(minItemWidth: 400, children: cards);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    final loans = context.watch<LoanStore>().forUser(user.id);
    final reqs = context.watch<ConsumableStore>().forUser(user.id);
    final st = _loanOpts.contains(_status) ? _status : 'Semua';
    final cst = _consOpts.contains(_status) ? _status : 'Semua';

    RowCard loanCard(LoanRequest l) => RowCard(
          leading: ItemImage(iconKey: l.lines.first.iconKey, size: 46),
          title: '${l.id} - ${l.summary}',
          subtitle: Fmt.range(l.start, l.end),
          trailing: StatusBadge.status(l.status),
          onTap: () => push(context, LoanDetailPage(loanId: l.id)),
        );

    final active = loans
        .where((l) =>
            l.status != LoanStatus.selesai &&
            _loanMatch(l.status, st) &&
            _inRange(l.submittedAt))
        .map(loanCard)
        .toList();
    final returned = loans
        .where((l) => l.status == LoanStatus.selesai && _inRange(l.submittedAt))
        .map(loanCard)
        .toList();
    final consCards = reqs
        .where((r) => _consMatch(r.status, cst) && _inRange(r.createdAt))
        .map((r) => RowCard(
              leading: ItemImage(iconKey: r.lines.first.iconKey, size: 46),
              title: '${r.id} - ${r.summary}',
              subtitle: Fmt.dateTime(r.createdAt),
              trailing: StatusBadge.status(r.status),
              onTap: () =>
                  push(context, ConsumableRequestDetailPage(requestId: r.id)),
            ))
        .toList();

    return DefaultTabController(
      length: 3,
      child: AppPage(
        title: 'Riwayat',
        bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Peminjaman'),
              Tab(text: 'Dikembalikan'),
              Tab(text: 'Habis pakai')
            ]),
        body: TabBarView(children: [
          PageList(children: [
            _filters(_loanOpts),
            const SizedBox(height: 12),
            _list(active, 'Pengajuan peminjaman Anda akan muncul di sini.')
          ]),
          PageList(children: [
            _filters(null),
            const SizedBox(height: 12),
            _list(
                returned, 'Barang yang sudah dikembalikan akan muncul di sini.')
          ]),
          PageList(children: [
            _filters(_consOpts),
            const SizedBox(height: 12),
            _list(
                consCards, 'Permintaan barang habis pakai akan muncul di sini.')
          ]),
        ]),
      ),
    );
  }
}
