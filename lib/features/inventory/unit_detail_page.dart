import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/condition_repair_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Detail satu unit barang (berdasarkan kode barcode).
class UnitDetailPage extends StatelessWidget {
  final String code;
  const UnitDetailPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final loans = context.watch<LoanStore>();
    final ref = inv.findByCode(code);
    if (ref == null) {
      return const AppPage(
          title: 'Detail Unit',
          body: EmptyState(
              icon: Icons.qr_code_2,
              title: 'Unit tidak ditemukan',
              message: 'Kode unit tidak terdaftar.'));
    }
    final u = ref.unit;
    final history = loans.loans
        .where((l) => l.unitCodes.contains(code))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final repairs = inv.repairs.where((r) => r.unitCode == code).toList();
    final logs = inv.logs.where((l) => l.unitCode == code).toList();

    return AppPage(
      title: 'Detail Unit',
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ItemImage(iconKey: ref.item.iconKey, size: 160, height: 160),
            const SizedBox(height: AppSpacing.md),
            BarcodeView(code: code),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
                title: ref.item.name,
                rows: [
                  ('Kode unit', code),
                  ('Kategori', ref.item.category),
                  ('Lokasi', ref.item.location),
                ],
                trailing: StatusBadge.status(u.status)),
            const SizedBox(height: 8),
            AppCard(
              child: Row(children: [
                const Text('Kondisi',
                    style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                StatusBadge.fromStatus(u.condition.label),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: u.status == UnitStatus.dipinjam
                  ? null
                  : () => push(context, DamageFormPage(code: code)),
              icon: const Icon(Icons.report_problem_outlined),
              label: Text(u.status == UnitStatus.dipinjam
                  ? 'Sedang dipinjam'
                  : 'Catat kerusakan'),
            ),
          ]),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionHeader('Riwayat peminjaman'),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const AppCard(
                  child: Text('Belum ada riwayat peminjaman.',
                      style: TextStyle(color: AppColors.textSecondary)))
            else
              for (final l in history)
                RowCard(
                    title: '${l.id} - ${l.borrower.name}',
                    subtitle:
                        '${l.borrower.role.label} - ${Fmt.range(l.start, l.end)}',
                    trailing: StatusBadge.status(l.status)),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Riwayat kerusakan dan perbaikan'),
            const SizedBox(height: 8),
            if (repairs.isEmpty)
              const AppCard(
                  child: Text('Tidak ada catatan kerusakan.',
                      style: TextStyle(color: AppColors.textSecondary)))
            else
              for (final r in repairs)
                RowCard(
                  title: r.issue,
                  subtitle: 'Dilaporkan ${Fmt.date(r.reportedAt)}',
                  trailing: StatusBadge.status(r.status),
                  onTap: () => push(context, RepairDetailPage(repairId: r.id)),
                ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Riwayat kondisi'),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              const AppCard(
                  child: Text('Belum ada perubahan kondisi.',
                      style: TextStyle(color: AppColors.textSecondary)))
            else
              for (final l in logs)
                RowCard(
                    title: '${l.from.label} ke ${l.to.label}',
                    subtitle: '${Fmt.dateTime(l.date)} - ${l.actor}',
                    extra: [
                      Text(l.note, style: const TextStyle(fontSize: 13))
                    ]),
          ]),
        ),
      ]),
    );
  }
}
