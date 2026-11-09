import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ReturnInspectionPage extends StatefulWidget {
  final LoanRequest request;

  const ReturnInspectionPage({super.key, required this.request});

  @override
  State<ReturnInspectionPage> createState() => _ReturnInspectionPageState();
}

class _ReturnInspectionPageState extends State<ReturnInspectionPage> {
  final Map<String, ItemCondition> _conditions = {};
  final _damageNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final code in widget.request.unitCodes) {
      _conditions[code] = ItemCondition.layak;
    }
  }

  @override
  void dispose() {
    _damageNoteCtrl.dispose();
    super.dispose();
  }

  void _submitReturn() {
    final loans = context.read<LoanStore>();
    loans.completeReturn(widget.request, _conditions, _damageNoteCtrl.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengembalian barang berhasil dikonfirmasi dan dicatat ke inventaris.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDamage = _conditions.values.any((c) => c != ItemCondition.layak);

    return Scaffold(
      appBar: AppBar(
        title: Text('Inspeksi Pengembalian ${widget.request.id}'),
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
                  // Info Peminjam
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data Peminjaman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 18),
                        Text('Peminjam: ${widget.request.borrower.name} (${widget.request.borrower.identityValue})'),
                        const SizedBox(height: 4),
                        Text('Keperluan: ${widget.request.purpose}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan Penting Bagian 27
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sesuai ketentuan, Barang Habis Pakai (ATK) tidak melalui proses pengembalian. Hanya unit fisik inventaris yang diperiksa kondisinya.',
                            style: TextStyle(fontSize: 11.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Daftar Unit Fisik & Pemeriksaan Kondisi
                  const Text('Pemeriksaan Kondisi Fisik Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  ...widget.request.unitCodes.map((code) {
                    final currentCond = _conditions[code] ?? ItemCondition.layak;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Barcode Unit: $code',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Kondisi Fisik Saat Pengembalian:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),

                            // Pilihan Kondisi (Layak, Perlu Diperbaiki, Rusak Total)
                            SegmentedButton<ItemCondition>(
                              segments: const [
                                ButtonSegment(
                                  value: ItemCondition.layak,
                                  label: Text('Layak Pakai', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.check_circle_outline, size: 16),
                                ),
                                ButtonSegment(
                                  value: ItemCondition.perluDiperbaiki,
                                  label: Text('Perlu Servis', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.build_outlined, size: 16),
                                ),
                                ButtonSegment(
                                  value: ItemCondition.rusakTotal,
                                  label: Text('Rusak Total', style: TextStyle(fontSize: 11)),
                                  icon: Icon(Icons.cancel_outlined, size: 16),
                                ),
                              ],
                              selected: {currentCond},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _conditions[code] = set.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Catatan Kerusakan (wajib diisi jika ada kerusakan)
                  if (hasDamage) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Catatan Kerusakan (Otomatis Masuk Tiket Perbaikan):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _damageNoteCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Jelaskan kerusakan fisik (misal: layar bergaris, kabel charger terkelupas)...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  PrimaryButton(
                    label: 'Selesaikan Pengembalian Unit',
                    icon: Icons.check,
                    onPressed: _submitReturn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
