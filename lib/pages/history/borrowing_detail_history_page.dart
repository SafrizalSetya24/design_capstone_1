import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class BorrowingDetailHistoryPage extends StatelessWidget {
  final LoanRequest request;

  const BorrowingDetailHistoryPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = context.watch<LoanStore>();
    final liveReq = loans.byId(request.id) ?? request;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('riwayat');
            }
          },
        ),
        title: Text('Detail ${liveReq.id}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header Card
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              liveReq.id,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            ),
                            StatusBadge.status( liveReq.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (liveReq.status == LoanStatus.menungguPersetujuan) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sisa Waktu Persetujuan:', style: TextStyle(fontSize: 12)),
                              CountdownBadge(deadline: liveReq.expiresAt),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sapras memiliki waktu 2 jam sejak pengajuan untuk menyetujui request ini.',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ] else if (liveReq.status == LoanStatus.ditolak) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Alasan Penolakan: ${liveReq.rejectReason ?? "Kegiatan sekolah lain bersamaan"}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Informasi Peminjam & Jadwal
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informasi Peminjaman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 20),
                        _buildRow('Peminjam', liveReq.borrower.name),
                        _buildRow(liveReq.borrower.identityLabel, liveReq.borrower.identityValue),
                        if (liveReq.borrower.extraLabel != null)
                          _buildRow(liveReq.borrower.extraLabel!, liveReq.borrower.extraValue ?? '-'),
                        _buildRow('Jadwal Mulai', Format.dateTime(liveReq.start)),
                        _buildRow('Jadwal Selesai', Format.dateTime(liveReq.end)),
                        _buildRow('Keperluan', liveReq.purpose),
                        if (liveReq.faceVerified == true)
                          _buildRow('Verifikasi Wajah', '✓ Terverifikasi (${((liveReq.faceScore ?? 0.95) * 100).round()}%)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Daftar Barang
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rincian Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 20),
                        ...liveReq.lines.map((line) {
                          final isPerUnit = line.isPerUnit;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isPerUnit ? Icons.devices_other : Icons.draw_outlined,
                                  size: 18,
                                  color: isPerUnit ? AppColors.primary : Colors.teal,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(
                                        line.kind.label,
                                        style: TextStyle(fontSize: 11, color: isPerUnit ? AppColors.primary : Colors.teal),
                                      ),
                                      // Tampilkan Barcode Unit jika sudah diserahkan oleh Sapras
                                      if (isPerUnit && liveReq.unitCodes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          children: liveReq.unitCodes
                                              .map((code) => Chip(
                                                    visualDensity: VisualDensity.compact,
                                                    label: Text(code, style: const TextStyle(fontSize: 11)),
                                                    avatar: const Icon(Icons.qr_code, size: 14),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${line.qty} ${line.satuan}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Riwayat Status (Event Log)
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jejak Aktivitas Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 20),
                        ...liveReq.events.map((ev) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ev.status.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                      if (ev.note != null && ev.note!.isNotEmpty)
                                        Text(ev.note!, style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                                    ],
                                  ),
                                ),
                                Text(Format.dateTime(ev.time), style: TextStyle(fontSize: 11, color: theme.hintColor)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
