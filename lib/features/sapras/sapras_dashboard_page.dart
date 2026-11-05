import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasDashboardPage extends StatelessWidget {
  const SaprasDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final loans = context.watch<LoanStore>();
    final audit = context.watch<AuditStore>();
    final settings = context.watch<SettingsStore>();
    final shell = ShellScope.maybeOf(context);

    final pendingLoans = loans.count({LoanStatus.menungguPersetujuan});
    final pendingCons = cons.countStatus(ConsumableStatus.menunggu);
    final layak = inv.countCond(ItemCondition.layak);
    final perlu = inv.countCond(ItemCondition.perluDiperbaiki);
    final rusak = inv.countCond(ItemCondition.rusakTotal);

    final perCat = <String, double>{};
    for (final i in inv.items) {
      perCat[i.category] = (perCat[i.category] ?? 0) + i.total;
    }

    final shortcuts = <(IconData, String, String)>[
      (Icons.qr_code_scanner, 'Scan barcode', 'scan'),
      (Icons.fact_check_outlined, 'Persetujuan', 'persetujuan'),
      (Icons.outbox_outlined, 'Penyerahan', 'penyerahan'),
      (Icons.move_to_inbox_outlined, 'Pengembalian', 'pengembalian'),
      (Icons.layers_outlined, 'Stok habis pakai', 'stok'),
      if (settings.can(UserRole.sapras, 'laporan'))
        (Icons.assessment_outlined, 'Laporan', 'laporan'),
      if (settings.can(UserRole.sapras, 'forecasting'))
        (Icons.trending_up, 'Forecasting', 'forecasting'),
    ];

    return AppPage(
      title: 'Dashboard Sapras',
      body: SimLoading(
        child: PageList(children: [
          StatGrid([
            StatCard(
                icon: Icons.inventory_2_outlined,
                value: '${inv.totalUnits}',
                label: 'Total inventaris (unit)',
                color: AppColors.navy,
                onTap: () => shell?.go('inventaris')),
            StatCard(
                icon: Icons.check_circle_outline,
                value: '$layak',
                label: 'Layak pakai',
                color: AppColors.success),
            StatCard(
                icon: Icons.build_outlined,
                value: '$perlu',
                label: 'Perlu diperbaiki',
                color: AppColors.warning,
                onTap: () => shell?.go('kondisi')),
            StatCard(
                icon: Icons.cancel_outlined,
                value: '$rusak',
                label: 'Rusak total',
                color: AppColors.danger),
            StatCard(
                icon: Icons.layers_outlined,
                value: '${cons.totalStock}',
                label: 'Stok habis pakai',
                color: AppColors.blue,
                onTap: () => shell?.go('stok')),
            StatCard(
                icon: Icons.hourglass_top_rounded,
                value: '$pendingLoans',
                label: 'Pengajuan menunggu',
                color: AppColors.warning,
                onTap: () => shell?.go('persetujuan')),
            StatCard(
                icon: Icons.rule_folder_outlined,
                value: '$pendingCons',
                label: 'Permintaan habis pakai',
                color: AppColors.warning,
                onTap: () => shell?.go('persetujuan_hp')),
          ], minItemWidth: 160),
          if (cons.lowStock.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: AppColors.warning.withValues(alpha: 0.08),
              onTap: () => shell?.go('stok'),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        '${cons.lowStock.length} barang habis pakai stoknya menipis: ${cons.lowStock.map((e) => e.name).take(3).join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Akses cepat'),
          const SizedBox(height: 8),
          ResponsiveGrid(minItemWidth: 150, children: [
            for (final s in shortcuts)
              AppCard(
                onTap: () => shell?.go(s.$3),
                child: Row(children: [
                  Icon(s.$1, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(s.$2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5))),
                ]),
              ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          ResponsiveGrid(minItemWidth: 420, spacing: 16, children: [
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kondisi inventaris',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 14),
                    DonutChartView(
                      centerValue: '${inv.totalUnits}',
                      centerLabel: 'unit',
                      segments: [
                        DonutSegment(
                            'Layak pakai', layak.toDouble(), AppColors.success),
                        DonutSegment('Perlu diperbaiki', perlu.toDouble(),
                            AppColors.warning),
                        DonutSegment(
                            'Rusak total', rusak.toDouble(), AppColors.danger),
                      ],
                    ),
                  ]),
            ),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unit per kategori',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 14),
                    BarChartView(labels: perCat.keys.toList(), series: [
                      ChartSeries(
                          'Unit', perCat.values.toList(), AppColors.blue)
                    ]),
                  ]),
            ),
            const AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grafik peminjaman (6 bulan)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 14),
                    LineChartView(labels: DummyData.months, series: [
                      ChartSeries(
                          'Peminjaman', DummyData.monthlyLoans, AppColors.blue),
                      ChartSeries('Pengembalian', DummyData.monthlyReturns,
                          AppColors.success),
                    ]),
                  ]),
            ),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktivitas terbaru',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    for (final a in audit.entries.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.bolt,
                                size: 16, color: AppColors.blue)),
                        title: Text(a.detail,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${a.userName} - ${Fmt.ago(a.time)}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ]),
            ),
          ]),
        ]),
      ),
    );
  }
}
