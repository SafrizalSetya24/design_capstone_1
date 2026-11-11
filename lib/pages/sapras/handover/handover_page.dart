import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/handover/barcode_scanner_page.dart';
import 'package:sipintar/pages/sapras/handover/manual_unit_selection_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasHandoverPage extends StatefulWidget {
  final LoanRequest request;

  const SaprasHandoverPage({super.key, required this.request});

  @override
  State<SaprasHandoverPage> createState() => _SaprasHandoverPageState();
}

class _SaprasHandoverPageState extends State<SaprasHandoverPage> {
  // Mapping itemId -> List of assigned unit codes
  final Map<String, List<String>> _assignedUnits = {};
  // Mapping itemId -> handed over qty for consumables
  final Map<String, int> _consumableHandoverQty = {};

  final _receiverCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _receiverCtrl.text = widget.request.borrower.name;

    for (final line in widget.request.lines) {
      if (line.isPerUnit) {
        _assignedUnits[line.itemId] = List.from(line.assignedUnits);
      } else {
        _consumableHandoverQty[line.itemId] = line.qty;
      }
    }
  }

  @override
  void dispose() {
    _receiverCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScanner(LoanLine line) async {
    final current = _assignedUnits[line.itemId] ?? [];
    if (current.length >= line.qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seluruh unit untuk ${line.itemName} sudah terpilih.')),
      );
      return;
    }

    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SaprasBarcodeScannerPage(
          itemId: line.itemId,
          itemName: line.itemName,
          alreadySelected: current,
        ),
      ),
    );

    if (scannedCode != null) {
      setState(() {
        _assignedUnits[line.itemId] = [...current, scannedCode];
      });
    }
  }

  Future<void> _openManualSelection(LoanLine line) async {
    final current = _assignedUnits[line.itemId] ?? [];
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => SaprasManualUnitSelectionPage(
          itemId: line.itemId,
          itemName: line.itemName,
          requiredQty: line.qty,
          currentSelected: current,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _assignedUnits[line.itemId] = selected;
      });
    }
  }

  void _confirmHandover() {
    // Validasi kelengkapan penyerahan
    for (final line in widget.request.lines) {
      if (line.isPerUnit) {
        final assigned = _assignedUnits[line.itemId] ?? [];
        if (assigned.length != line.qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pilih ${line.qty} unit barcode untuk ${line.itemName} (baru ${assigned.length}).')),
          );
          return;
        }
      }
    }

    final loans = context.read<LoanStore>();
    final cons = context.read<ConsumableStore>();

    // Ambil barcode unit yang telah dipilih
    final allCodes = <String>[];
    for (final line in widget.request.lines) {
      if (line.isPerUnit) {
        final codes = _assignedUnits[line.itemId] ?? [];
        line.assignedUnits = List.from(codes);
        allCodes.addAll(codes);
      } else {
        // Kurangi stok barang habis pakai
        final qtyHanded = _consumableHandoverQty[line.itemId] ?? line.qty;
        line.handedOverQty = qtyHanded;
        final item = cons.itemById(line.itemId);
        if (item != null) {
          cons.removeStock(item, qtyHanded, 'Penyerahan peminjaman ${widget.request.id} ke ${_receiverCtrl.text}');
        }
      }
    }

    // Perbarui status peminjaman menjadi telah diserahkan
    loans.handover(widget.request, _receiverCtrl.text.trim(), allCodes);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Penyerahan barang berhasil dikonfirmasi.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cons = context.watch<ConsumableStore>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Penyerahan Barang (Handover) ${widget.request.id}'),
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
                        const Text('Data Penyerahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 18),
                        Text('Peminjam: ${widget.request.borrower.name} (${widget.request.borrower.identityValue})'),
                        const SizedBox(height: 4),
                        Text('Keperluan: ${widget.request.purpose}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _receiverCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Penerima Fisik',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Daftar Barang & Penentuan Unit Fisik
                  const Text('Penentuan Unit & Stok Fisik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  ...widget.request.lines.map((line) {
                    final isPerUnit = line.isPerUnit;

                    if (isPerUnit) {
                      final assigned = _assignedUnits[line.itemId] ?? [];
                      final isComplete = assigned.length == line.qty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.devices, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isComplete ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${assigned.length} / ${line.qty} unit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isComplete ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (assigned.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: assigned.map((code) {
                                    return Chip(
                                      avatar: const Icon(Icons.qr_code, size: 14),
                                      label: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onDeleted: () {
                                        setState(() {
                                          _assignedUnits[line.itemId]?.remove(code);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                                      label: const Text('Scan Barcode'),
                                      onPressed: () => _openScanner(line),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.list_alt, size: 16),
                                      label: const Text('Pilih Manual'),
                                      onPressed: () => _openManualSelection(line),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Barang Habis Pakai (ATK)
                      final currentQty = _consumableHandoverQty[line.itemId] ?? line.qty;
                      final stockItem = cons.itemById(line.itemId);
                      final stock = stockItem?.stock ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.draw_outlined, color: Colors.teal, size: 20),
                                      const SizedBox(width: 8),
                                      Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Text(
                                    'Stok Gudang: $stock ${line.satuan}',
                                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Diminta: ${line.qty} ${line.satuan}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text('Diserahkan: ', style: TextStyle(fontSize: 12)),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: currentQty > 1
                                            ? () => setState(() => _consumableHandoverQty[line.itemId] = currentQty - 1)
                                            : null,
                                      ),
                                      Text(
                                        '$currentQty ${line.satuan}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: currentQty < stock
                                            ? () => setState(() => _consumableHandoverQty[line.itemId] = currentQty + 1)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'Konfirmasi Penyerahan (Confirm Handover)',
                    icon: Icons.check_circle,
                    onPressed: _confirmHandover,
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
