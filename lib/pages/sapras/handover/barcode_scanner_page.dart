import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Halaman pemindai barcode unit fisik untuk konfirmasi penyerahan barang (Handover)
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
  State<SaprasBarcodeScannerPage> createState() =>
      _SaprasBarcodeScannerPageState();
}

class _SaprasBarcodeScannerPageState extends State<SaprasBarcodeScannerPage> {
  final TextEditingController _manualInputController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _manualInputController.dispose();
    super.dispose();
  }

  // Validasi kode barcode unit fisik
  void _handleScannedCode(String scannedBarcode) {
    final inventoryStore = context.read<InventoryStore>();
    final targetItem = inventoryStore.itemById(widget.itemId);

    if (targetItem == null) {
      setState(() => _errorMessage = 'Barang tidak ditemukan di sistem.');
      return;
    }

    // Cek barcode pada unit barang
    final matchedUnit = targetItem.units
        .where(
          (unit) =>
              unit.code.toUpperCase() == scannedBarcode.trim().toUpperCase(),
        )
        .firstOrNull;

    if (matchedUnit == null) {
      setState(() => _errorMessage =
          'Barcode $scannedBarcode bukan unit dari ${widget.itemName}.');
      return;
    }

    // Cegah scan unit yang sama dua kali
    if (widget.alreadySelected.contains(matchedUnit.code)) {
      setState(() => _errorMessage =
          'Unit ${matchedUnit.code} sudah dipilih pada penyerahan ini.');
      return;
    }

    // Pastikan status unit dapat dipinjam
    if (!matchedUnit.borrowable) {
      setState(() => _errorMessage =
          'Unit ${matchedUnit.code} tidak dapat diserahkan (Status: ${matchedUnit.status.label}, Kondisi: ${matchedUnit.condition.label}).');
      return;
    }

    // Barcode cocok dan valid
    Navigator.of(context).pop(matchedUnit.code);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryStore = context.watch<InventoryStore>();
    final targetItem = inventoryStore.itemById(widget.itemId);
    final availableUnits = targetItem?.units
            .where((unit) =>
                unit.borrowable && !widget.alreadySelected.contains(unit.code))
            .toList() ??
        [];

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
                  // Area kamera scanner
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
                                border: Border.all(
                                    color: Colors.redAccent, width: 2),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner,
                                      color: Colors.white70, size: 40),
                                  SizedBox(height: 6),
                                  Text(
                                    'Arahkan kamera ke Barcode unit fisik',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11),
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

                  // Pesan kesalahan validasi
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Input manual kode barcode
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          decoration: const InputDecoration(
                            hintText: 'Atau ketik barcode (contoh: LPT-001)',
                            prefixIcon: Icon(Icons.keyboard),
                          ),
                          onSubmitted: _handleScannedCode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            _handleScannedCode(_manualInputController.text),
                        child: const Text('Input'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pilihan cepat barcode unit
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Cepat Unit Tersedia (Mode Uji Coba):',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (availableUnits.isEmpty)
                    const Text(
                      'Tidak ada unit fisik yang tersedia.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableUnits.map((unit) {
                        return ActionChip(
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: const BorderSide(
                              color: Color(0xFF93C5FD), width: 1.2),
                          avatar: const Icon(Icons.qr_code,
                              size: 14, color: AppColors.primary),
                          label: Text(
                            unit.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.navy,
                            ),
                          ),
                          onPressed: () => _handleScannedCode(unit.code),
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
