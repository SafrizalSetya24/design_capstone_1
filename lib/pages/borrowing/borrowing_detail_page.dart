import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/borrowing/face_verification_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class BorrowingDetailPage extends StatefulWidget {
  const BorrowingDetailPage({super.key});

  @override
  State<BorrowingDetailPage> createState() => _BorrowingDetailPageState();
}

class _BorrowingDetailPageState extends State<BorrowingDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController(text: 'Praktikum Informatika di Laboratorium');

  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  DateTime _endDate = DateTime.now().add(const Duration(hours: 5));
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  bool _availabilityChecked = true;
  String? _availabilityError;

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDateTime => DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

  DateTime get _endDateTime => DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
        _checkAvailability();
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _checkAvailability();
      });
    }
  }

  void _checkAvailability() {
    setState(() {
      _availabilityError = null;
    });

    final cart = context.read<CartStore>();
    final inv = context.read<InventoryStore>();

    // Validasi Waktu
    if (_endDateTime.isBefore(_startDateTime) || _endDateTime.isAtSameMomentAs(_startDateTime)) {
      _availabilityError = 'Waktu selesai peminjaman harus setelah waktu mulai.';
      _availabilityChecked = false;
      return;
    }

    // Validasi Kapasitas Barang Per Unit
    for (final item in cart.items) {
      if (item.kind == ItemKind.perUnit) {
        final it = inv.itemById(item.itemId);
        if (it != null && it.available < item.qty) {
          _availabilityError = 'Barang ${item.itemName} hanya tersedia ${it.available} unit untuk jadwal tersebut.';
          _availabilityChecked = false;
          return;
        }
      }
    }

    _availabilityChecked = true;
  }

  void _proceedToFaceVerification() {
    if (!_formKey.currentState!.validate()) return;
    _checkAvailability();
    if (!_availabilityChecked) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FaceVerificationPage(
          start: _startDateTime,
          end: _endDateTime,
          purpose: _purposeCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('keranjang');
            }
          },
        ),
        title: const Text('Detail Peminjaman'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alur SOP Langkah 4
                    const BorrowingFlowStepper(
                      currentStep: 4,
                    ),
                    const SizedBox(height: 12),

                    // Ringkasan Barang
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar Barang yang Dipinjam',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Text(
                                '${cart.itemCount} jenis',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          ...cart.items.map(
                            (it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    it.kind == ItemKind.perUnit ? Icons.devices_other : Icons.draw_outlined,
                                    size: 16,
                                    color: it.kind == ItemKind.perUnit ? AppColors.primary : Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(it.itemName, style: const TextStyle(fontSize: 13))),
                                  Text(
                                    '${it.qty} ${it.satuan}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pemilihan Waktu Mulai & Selesai
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jadwal Waktu Peminjaman',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 14),

                          // Waktu Mulai
                          const Text('Waktu Mulai:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(dateFormat.format(_startDate), style: const TextStyle(fontSize: 12)),
                                  onPressed: () => _pickDate(true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.access_time, size: 16),
                                  label: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                                  onPressed: () => _pickTime(true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Waktu Selesai
                          const Text('Waktu Selesai:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(dateFormat.format(_endDate), style: const TextStyle(fontSize: 12)),
                                  onPressed: () => _pickDate(false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.access_time, size: 16),
                                  label: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                                  onPressed: () => _pickTime(false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Keperluan Peminjaman
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keperluan Peminjaman',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _purposeCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Praktikum Pemrograman Mobile di Lab RPL 2',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Keperluan peminjaman wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Hasil Cek Ketersediaan (Section 12)
                    if (_availabilityError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _availabilityError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_availabilityChecked)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ketersediaan Terverifikasi: Seluruh unit dan stok barang tersedia pada rentang waktu yang dipilih.',
                                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Lanjutkan ke Verifikasi Wajah',
                      icon: Icons.face_retouching_natural,
                      onPressed: _proceedToFaceVerification,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
