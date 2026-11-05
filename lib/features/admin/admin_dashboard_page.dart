import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final audit = context.watch<AuditStore>();
    final shell = ShellScope.maybeOf(context);
    final siswa = auth.countRole(UserRole.siswa);
    final guru = auth.countRole(UserRole.guru);
    final sapras = auth.countRole(UserRole.sapras);
    final admin = auth.countRole(UserRole.admin);
    final active = auth.accounts.where((a) => a.active).length;

    return AppPage(
      title: 'Dashboard Admin',
      body: SimLoading(
        child: PageList(children: [
          StatGrid([
            StatCard(
                icon: Icons.people_outline,
                value: '${auth.accounts.length}',
                label: 'Total pengguna',
                color: AppColors.navy,
                onTap: () => shell?.go('pengguna')),
            StatCard(
                icon: Icons.school_outlined,
                value: '$siswa',
                label: 'Siswa',
                color: AppColors.blue),
            StatCard(
                icon: Icons.person_pin_outlined,
                value: '$guru',
                label: 'Guru',
                color: const Color(0xFF3B5BA9)),
            StatCard(
                icon: Icons.inventory_2_outlined,
                value: '$sapras',
                label: 'Sapras',
                color: AppColors.success),
            StatCard(
                icon: Icons.admin_panel_settings_outlined,
                value: '$admin',
                label: 'Admin',
                color: AppColors.warning),
            StatCard(
                icon: Icons.block,
                value: '${auth.accounts.length - active}',
                label: 'Akun nonaktif',
                color: AppColors.danger),
          ], minItemWidth: 150),
          const SizedBox(height: AppSpacing.lg),
          ResponsiveGrid(minItemWidth: 420, spacing: 16, children: [
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statistik pengguna',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 14),
                    DonutChartView(
                        centerValue: '${auth.accounts.length}',
                        centerLabel: 'pengguna',
                        segments: [
                          DonutSegment(
                              'Siswa', siswa.toDouble(), AppColors.blue),
                          DonutSegment('Guru', guru.toDouble(), AppColors.navy),
                          DonutSegment(
                              'Sapras', sapras.toDouble(), AppColors.success),
                          DonutSegment(
                              'Admin', admin.toDouble(), AppColors.warning),
                        ]),
                  ]),
            ),
            const AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktivitas pengguna (7 hari)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 14),
                    BarChartView(labels: DummyData.weekdays, series: [
                      ChartSeries(
                          'Aktivitas', DummyData.weeklyActivity, AppColors.blue)
                    ]),
                  ]),
            ),
            const AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grafik aktivitas bulanan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 14),
                    LineChartView(labels: DummyData.months, series: [
                      ChartSeries(
                          'Transaksi', DummyData.monthlyLoans, AppColors.blue),
                      ChartSeries('Permintaan barang',
                          DummyData.monthlyConsumableOut, AppColors.warning),
                    ]),
                  ]),
            ),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Text('Aktivitas terbaru',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15))),
                      TextButton(
                          onPressed: () => shell?.go('audit'),
                          child: const Text('Audit log')),
                    ]),
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
                        subtitle: Text(
                            '${a.userName} (${a.role}) - ${Fmt.ago(a.time)}',
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
