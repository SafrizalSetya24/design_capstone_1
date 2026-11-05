import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Forecasting SIMULASI. Seluruh angka prediksi adalah data dummy, bukan hasil model ML sungguhan.
class ForecastingPage extends StatefulWidget {
  const ForecastingPage({super.key});
  @override
  State<ForecastingPage> createState() => _ForecastingPageState();
}

class _ForecastingPageState extends State<ForecastingPage> {
  String _cat = 'Semua';
  int _months = 3;

  List<double> _hist(String c) {
    if (c != 'Semua') return DummyData.forecastHistory[c]!;
    return List.generate(6,
        (i) => DummyData.forecastHistory.values.fold(0.0, (a, v) => a + v[i]));
  }

  List<double> _pred(String c) {
    if (c != 'Semua') return DummyData.forecastPrediction[c]!;
    return List.generate(
        3,
        (i) =>
            DummyData.forecastPrediction.values.fold(0.0, (a, v) => a + v[i]));
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final hist = _hist(_cat);
    final pred = _pred(_cat).sublist(0, _months);
    final labels = [
      ...DummyData.months,
      ...DummyData.forecastMonths.sublist(0, _months)
    ];
    final today = DateTime.now();

    // Potensi kekurangan (simulasi aturan sederhana)
    final unitRisk = <(String, int, int, double)>[];
    for (final e in DummyData.forecastPrediction.entries) {
      final units = inv.items
          .where((i) =>
              i.category == e.key ||
              (e.key == 'Audio' && i.category == 'Audio'))
          .fold<int>(0, (a, i) => a + i.total);
      final cap = units * 3;
      final next = e.value.first;
      if (cap > 0 && next / cap > 0.8) {
        unitRisk.add((e.key, units, next.round(), next / cap));
      }
    }
    final consRisk =
        cons.items.where((i) => i.stock < (i.minStock * 1.5).round()).toList();

    final recs = <String>[
      for (final r in consRisk)
        'Siapkan tambahan ${r.name} minimal ${((r.minStock * 1.5).round() - r.stock)} ${r.satuan} sebelum bulan depan.',
      for (final u in unitRisk)
        'Kategori ${u.$1} (${u.$2} unit) diperkirakan ramai. Pertimbangkan penambahan unit atau penjadwalan lebih awal.',
      'Lakukan pengecekan kondisi unit sebelum periode ujian dan kegiatan akhir semester.',
    ];

    return AppPage(
      title: 'Forecasting',
      body: SimLoading(
        child: PageList(children: [
          AppCard(
            color: AppColors.warning.withValues(alpha: 0.10),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Tampilan simulasi. Prediksi di bawah adalah data dummy dan belum menggunakan model Machine Learning sungguhan.',
                          style: TextStyle(fontSize: 13, height: 1.4))),
                ]),
          ),
          const SizedBox(height: AppSpacing.md),
          TwoPane(
            leftFlex: 3,
            rightFlex: 2,
            left: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tren permintaan dan prediksi',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          FilterRow(
                              label: 'Kategori',
                              options: [
                                'Semua',
                                ...DummyData.forecastHistory.keys
                              ],
                              selected: _cat,
                              onSelected: (v) => setState(() => _cat = v)),
                          const SizedBox(height: 14),
                          LineChartView(labels: labels, series: [
                            ChartSeries(
                                'Riwayat permintaan',
                                [
                                  ...hist,
                                  ...List<double?>.filled(_months, null)
                                ],
                                AppColors.blue),
                            ChartSeries(
                                'Prediksi (simulasi)',
                                [
                                  ...List<double?>.filled(5, null),
                                  hist.last,
                                  ...pred
                                ],
                                AppColors.warning,
                                dashed: true),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionHeader('Prediksi kebutuhan per kategori'),
                  const SizedBox(height: 8),
                  ResponsiveTable(
                    columns: const [
                      'Kategori',
                      'Rata-rata 6 bulan',
                      'Prediksi bulan depan',
                      'Perubahan'
                    ],
                    rows: [
                      for (final e in DummyData.forecastHistory.entries)
                        () {
                          final avg = e.value.fold(0.0, (a, b) => a + b) /
                              e.value.length;
                          final next =
                              DummyData.forecastPrediction[e.key]!.first;
                          final ch = (next - avg) / avg * 100;
                          return [
                            cellText(e.key, bold: true),
                            cellText(avg.toStringAsFixed(1)),
                            cellText('${next.round()} permintaan', bold: true),
                            cellText('${ch >= 0 ? '+' : ''}${ch.round()}%',
                                color: ch >= 0
                                    ? AppColors.warning
                                    : AppColors.success)
                          ];
                        }(),
                    ],
                  ),
                ]),
            right: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoCard(title: 'Informasi model', rows: [
                    ('Model', 'Proyeksi tren (simulasi)'),
                    ('Tanggal prediksi', Fmt.date(today)),
                    ('Data historis', 'Jun - Nov 2026'),
                    (
                      'Prediksi bulan depan',
                      '${_pred(_cat).first.round()} permintaan'
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<int>(
                    label: 'Periode prediksi',
                    icon: Icons.calendar_month_outlined,
                    value: _months,
                    items: const [
                      DropdownMenuItem(
                          value: 1, child: Text('1 bulan ke depan')),
                      DropdownMenuItem(
                          value: 2, child: Text('2 bulan ke depan')),
                      DropdownMenuItem(
                          value: 3, child: Text('3 bulan ke depan'))
                    ],
                    onChanged: (v) => setState(() => _months = v ?? _months),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Berpotensi kekurangan',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 8),
                          if (consRisk.isEmpty && unitRisk.isEmpty)
                            const Text('Tidak ada potensi kekurangan.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          for (final r in consRisk)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(Icons.layers_outlined,
                                  color: AppColors.warning),
                              title: Text(r.name),
                              subtitle: Text(
                                  'Stok ${r.stock} ${r.satuan}, perkiraan kebutuhan ${(r.minStock * 1.5).round()}'),
                              trailing: const StatusBadge('Stok menipis',
                                  tone: BadgeTone.warning),
                            ),
                          for (final u in unitRisk)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(Icons.laptop_mac_rounded,
                                  color: AppColors.danger),
                              title: Text(u.$1),
                              subtitle: Text(
                                  '${u.$2} unit, prediksi ${u.$3} permintaan'),
                              trailing: const StatusBadge('Padat',
                                  tone: BadgeTone.danger),
                            ),
                        ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rekomendasi persiapan inventaris',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 8),
                          for (final r in recs)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline,
                                        size: 18, color: AppColors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(r,
                                            style: const TextStyle(
                                                fontSize: 13.5, height: 1.4))),
                                  ]),
                            ),
                        ]),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}
