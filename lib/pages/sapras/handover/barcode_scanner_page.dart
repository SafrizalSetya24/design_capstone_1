import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasBarcodeScannerPage extends StatefulWidget {
  final String itemId;
  final String itemName;
  final List<String> alreadySelected;

  const SaprasBarcodeScannerPage({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.alreadySelected,
  });

  @override
  State<SaprasBarcodeScannerPage> createState() => _SaprasBarcodeScannerPageState();
}

class _SaprasBarcodeScannerPageState extends State<SaprasBarcodeScannerPage> {
  final _manualCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onScanCode(String code) {
    final inv = context.read<InventoryStore>();
    final it = inv.itemById(widget.itemId);

    if (it == null) {
      setState(() => _error = 'Barang tidak ditemukan di sistem.');
      return;
    }

    // Validasi Unit Fisik (Sesuai Bagian 23)
    final unit = it.units.where((u) => u.code.toUpperCase() == code.trim().toUpperCase()).firstOrNull;

    if (unit == null) {
      setState(() => _error = 'Barcode $code bukan unit dari ${widget.itemName}.');
      return;
    }

    if (widget.alreadySelected.contains(unit.code)) {
      setState(() => _error = 'Unit ${unit.code} sudah dipilih pada penyerahan ini.');
      return;
    }

    if (!unit.borrowable) {
      setState(() => _error = 'Unit ${unit.code} tidak dapat diserahkan (Status: ${unit.status.label}, Kondisi: ${unit.condition.label}).');
      return;
    }

    // Valid Sukses
    Navigator.of(context).pop(unit.code);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final it = inv.itemById(widget.itemId);
    final availableUnits = it?.units.where((u) => u.borrowable && !widget.alreadySelected.contains(u.code)).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode: ${widget.itemName}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Scanner Camera View
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const FakeCamera(isFront: false),
                          Center(
                            child: Container(
                              width: 220,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent, width: 2),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner, color: Colors.white70, size: 40),
                                  SizedBox(height: 6),
                                  Text(
                                    'Arahkan kamera ke Barcode unit fisik',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
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
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Input Manual Barcode Cepat
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Atau ketik barcode (contoh: LPT-001)',
                            prefixIcon: Icon(Icons.keyboard),
                          ),
                          onSubmitted: _onScanCode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _onScanCode(_manualCtrl.text),
                        child: const Text('Input'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Click Chips (Unit yang Tersedia di Sekolah)
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Cepat Unit Tersedia (Mode Uji Coba):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (availableUnits.isEmpty)
                    const Text('Tidak ada unit tersedia.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableUnits.map((u) {
                        return ActionChip(
                          avatar: const Icon(Icons.qr_code, size: 14),
                          label: Text(u.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _onScanCode(u.code),
                        );
                      }).toList(),
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
