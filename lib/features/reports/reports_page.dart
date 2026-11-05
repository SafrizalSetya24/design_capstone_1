import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = '6 bulan';

  int get _n => switch (_period) { 'Bulan ini' => 1, '3 bulan' => 3, _ => 6 };
  List<String> get _labels => DummyData.months.sublist(6 - _n);
  List<double> _cut(List<double> v) => v.sublist(6 - _n);

  String _file(String t, String ext) {
    final d = DateTime.now();
    return 'laporan_${t}_${d.year}-${Fmt.two(d.month)}.$ext';
  }

  Widget _tab(BuildContext context, String key,
      {required Widget chart,
      required String chartTitle,
      required Widget table,
      String? summary}) {
    return PageList(children: [
      AppCard(
        child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.date_range, color: AppColors.blue),
              Text('Periode: $_period',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (summary != null)
                Text(summary,
                    style: const TextStyle(color: AppColors.textSecondary)),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(150, 44)),
                onPressed: () => simulateExport(context, _file(key, 'xlsx')),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Ekspor Excel'),
              ),
              OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(150, 44)),
                onPressed: () => simulateExport(context, _file(key, 'pdf')),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Ekspor PDF'),
              ),
            ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(chartTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          chart,
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      table,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final loans = context.watch<LoanStore>();
    final real = loans.loans
        .where((l) => l.status != LoanStatus.menungguVerifikasiWajah)
        .toList();
    final returned = loans.loans.where((l) => l.returnedAt != null).toList();

    final perCat = <String, double>{};
    for (final i in inv.items) {
      perCat[i.category] = (perCat[i.category] ?? 0) + i.total;
    }

    return DefaultTabController(
      length: 6,
      child: AppPage(
        title: 'Laporan',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Periode',
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (v) => setState(() => _period = v),
            itemBuilder: (_) => [
              for (final p in const ['Bulan ini', '3 bulan', '6 bulan'])
                CheckedPopupMenuItem(
                    value: p, checked: p == _period, child: Text(p))
            ],
          ),
        ],
        bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Inventaris'),
              Tab(text: 'Kondisi barang'),
              Tab(text: 'Peminjaman'),
              Tab(text: 'Pengembalian'),
              Tab(text: 'Habis pakai'),
              Tab(text: 'Masuk dan keluar'),
            ]),
        body: TabBarView(children: [
          _tab(context, 'inventaris',
              chartTitle: 'Jumlah unit per kategori',
              summary: '${inv.totalUnits} unit',
              chart: BarChartView(labels: perCat.keys.toList(), series: [
                ChartSeries('Unit', perCat.values.toList(), AppColors.blue)
              ]),
              table: ResponsiveTable(
                columns: const [
                  'Barang',
                  'Kategori',
                  'Total unit',
                  'Tersedia',
                  'Lokasi'
                ],
                rows: [
                  for (final i in inv.items)
                    [
                      cellText(i.name, bold: true),
                      cellText(i.category),
                      cellText('${i.total}'),
                      cellText('${i.available}'),
                      cellText(i.location)
                    ]
                ],
              )),
          _tab(context, 'kondisi',
              chartTitle: 'Distribusi kondisi unit',
              chart: DonutChartView(
                  centerValue: '${inv.totalUnits}',
                  centerLabel: 'unit',
                  segments: [
                    DonutSegment(
                        'Layak pakai',
                        inv.countCond(ItemCondition.layak).toDouble(),
                        AppColors.success),
                    DonutSegment(
                        'Perlu diperbaiki',
                        inv.countCond(ItemCondition.perluDiperbaiki).toDouble(),
                        AppColors.warning),
                    DonutSegment(
                        'Rusak total',
                        inv.countCond(ItemCondition.rusakTotal).toDouble(),
                        AppColors.danger),
                  ]),
              table: ResponsiveTable(
                columns: const ['Kode unit', 'Barang', 'Kondisi', 'Status'],
                rows: [
                  for (final r in inv.allUnits())
                    [
                      cellText(r.unit.code, bold: true),
                      cellText(r.item.name),
                      StatusBadge.fromStatus(r.unit.condition.label),
                      StatusBadge.fromStatus(r.unit.status.label)
                    ]
                ],
              )),
          _tab(context, 'peminjaman',
              chartTitle: 'Peminjaman per bulan',
              summary: '${real.length} transaksi tercatat',
              chart: BarChartView(labels: _labels, series: [
                ChartSeries(
                    'Peminjaman', _cut(DummyData.monthlyLoans), AppColors.blue)
              ]),
              table: ResponsiveTable(
                columns: const [
                  'ID',
                  'Peminjam',
                  'Jenis',
                  'Barang',
                  'Jadwal',
                  'Status'
                ],
                rows: [
                  for (final l in real)
                    [
                      cellText(l.id, bold: true),
                      cellText(l.borrower.name),
                      cellText(l.borrower.role.label),
                      cellText(l.summary),
                      cellText(Fmt.range(l.start, l.end)),
                      StatusBadge.fromStatus(l.status.label)
                    ],
                ],
              )),
          _tab(context, 'pengembalian',
              chartTitle: 'Pengembalian per bulan',
              chart: LineChartView(labels: _labels, series: [
                ChartSeries(
                    'Dipinjam', _cut(DummyData.monthlyLoans), AppColors.blue),
                ChartSeries('Dikembalikan', _cut(DummyData.monthlyReturns),
                    AppColors.success),
              ]),
              table: ResponsiveTable(
                emptyText: 'Belum ada pengembalian tercatat.',
                columns: const [
                  'ID',
                  'Peminjam',
                  'Barang',
                  'Dikembalikan',
                  'Kondisi'
                ],
                rows: [
                  for (final l in returned)
                    [
                      cellText(l.id, bold: true),
                      cellText(l.borrower.name),
                      cellText(l.summary),
                      cellText(Fmt.dateTime(l.returnedAt!)),
                      StatusBadge.fromStatus(l.returnConditions.values
                              .any((c) => c != ItemCondition.layak)
                          ? 'Perlu diperbaiki'
                          : 'Layak pakai'),
                    ],
                ],
              )),
          _tab(context, 'habis_pakai',
              chartTitle: 'Stok saat ini dan stok minimum',
              summary: '${cons.lowStock.length} stok menipis',
              chart: BarChartView(
                labels: [for (final i in cons.items) i.name.split(' ').first],
                series: [
                  ChartSeries(
                      'Stok',
                      [for (final i in cons.items) i.stock.toDouble()],
                      AppColors.blue),
                  ChartSeries(
                      'Minimum',
                      [for (final i in cons.items) i.minStock.toDouble()],
                      AppColors.warning),
                ],
              ),
              table: ResponsiveTable(
                columns: const [
                  'Barang',
                  'Kategori',
                  'Stok',
                  'Minimum',
                  'Status'
                ],
                rows: [
                  for (final i in cons.items)
                    [
                      cellText(i.name, bold: true),
                      cellText(i.category),
                      cellText('${i.stock} ${i.satuan}'),
                      cellText('${i.minStock} ${i.satuan}'),
                      StatusBadge(i.low ? 'Stok menipis' : 'Stok aman',
                          tone: i.low ? BadgeTone.warning : BadgeTone.success)
                    ]
                ],
              )),
          _tab(context, 'masuk_keluar',
              chartTitle: 'Barang masuk dan keluar per bulan',
              chart: BarChartView(labels: _labels, series: [
                ChartSeries('Masuk', _cut(DummyData.monthlyConsumableIn),
                    AppColors.success),
                ChartSeries('Keluar', _cut(DummyData.monthlyConsumableOut),
                    AppColors.danger),
              ]),
              table: ResponsiveTable(
                columns: const [
                  'Tanggal',
                  'Barang',
                  'Jenis',
                  'Jumlah',
                  'Catatan'
                ],
                rows: [
                  for (final m in cons.movements)
                    [
                      cellText(Fmt.dateTime(m.date)),
                      cellText(m.itemName, bold: true),
                      StatusBadge(m.isIn ? 'Masuk' : 'Keluar',
                          tone: m.isIn ? BadgeTone.success : BadgeTone.danger),
                      cellText('${m.isIn ? '+' : '-'}${m.qty}'),
                      cellText(m.note)
                    ]
                ],
              )),
        ]),
      ),
    );
  }
}
