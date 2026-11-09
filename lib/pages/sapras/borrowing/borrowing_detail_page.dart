import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/handover/handover_page.dart';
import 'package:sipintar/pages/sapras/return/return_inspection_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasBorrowingDetailPage extends StatelessWidget {
  final LoanRequest request;

  const SaprasBorrowingDetailPage({super.key, required this.request});

  void _showRejectDialog(BuildContext context, LoanStore loans) {
    final reasonCtrl = TextEditingController(text: 'Barang sedang digunakan untuk kegiatan resmi sekolah.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Pengajuan Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan penolakan untuk peminjam:', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tuliskan alasan penolakan...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              loans.reject(request, reasonCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengajuan berhasil ditolak.')),
              );
            },
            child: const Text('Tolak Pengajuan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = context.watch<LoanStore>();
    final liveReq = loans.byId(request.id) ?? request;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${liveReq.id}'),
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
                  // Status & SLA Bar
                  AppCard(
                    padding: const EdgeInsets.all(16),
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
                        if (liveReq.status == LoanStatus.menungguPersetujuan) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Batas Konfirmasi (SLA 2 Jam):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              CountdownBadge(deadline: liveReq.expiresAt),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jika melewati batas waktu 2 jam, sistem akan membatalkan peminjaman ini secara otomatis.',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Peminjam
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Identitas Peminjam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 18),
                        _buildRow('Nama', liveReq.borrower.name),
                        _buildRow('Peran', liveReq.borrower.role.label),
                        _buildRow(liveReq.borrower.identityLabel, liveReq.borrower.identityValue),
                        if (liveReq.borrower.extraLabel != null)
                          _buildRow(liveReq.borrower.extraLabel!, liveReq.borrower.extraValue ?? '-'),
                        _buildRow('Jadwal Mulai', Format.dateTime(liveReq.start)),
                        _buildRow('Jadwal Selesai', Format.dateTime(liveReq.end)),
                        _buildRow('Keperluan', liveReq.purpose),
                        _buildRow('Verifikasi Wajah', '✓ Lolos (${((liveReq.faceScore ?? 0.95) * 100).round()}%)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daftar Barang yang Diajukan
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Barang yang Diminta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 18),
                        ...liveReq.lines.map((line) {
                          final isPerUnit = line.isPerUnit;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
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
                                        isPerUnit
                                            ? 'Barang Per Unit (Wajib tentukan unit fisik saat handover)'
                                            : 'Barang Habis Pakai (Potong stok saat diserahkan)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isPerUnit ? AppColors.primary : Colors.teal,
                                        ),
                                      ),
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
                  const SizedBox(height: 24),

                  // Tombol Aksi Berdasarkan Status
                  if (liveReq.status == LoanStatus.menungguPersetujuan) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Tolak'),
                            onPressed: () => _showRejectDialog(context, loans),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: 'Setujui Pengajuan',
                            icon: Icons.check_circle_outline,
                            onPressed: () {
                              final err = loans.approve(liveReq);
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pengajuan peminjaman disetujui.')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (liveReq.status == LoanStatus.disetujui) ...[
                    PrimaryButton(
                      label: 'Proses Penyerahan Barang (Handover)',
                      icon: Icons.qr_code_scanner,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SaprasHandoverPage(request: liveReq)),
                      ),
                    ),
                  ] else if (liveReq.status == LoanStatus.sedangDipinjam || liveReq.status == LoanStatus.menungguPengembalian) ...[
                    PrimaryButton(
                      label: 'Proses Pengembalian (Return Inspection)',
                      icon: Icons.assignment_turned_in_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReturnInspectionPage(request: liveReq)),
                      ),
                    ),
                  ],
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
