import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasRepairDetailPage extends StatefulWidget {
  final RepairRecord record;

  const SaprasRepairDetailPage({super.key, required this.record});

  @override
  State<SaprasRepairDetailPage> createState() => _SaprasRepairDetailPageState();
}

class _SaprasRepairDetailPageState extends State<SaprasRepairDetailPage> {
  late RepairStatus _status;
  final _technicianCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _technicianCtrl.text = widget.record.technician;
    _notesCtrl.text = widget.record.notes;
  }

  @override
  void dispose() {
    _technicianCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final inv = context.read<InventoryStore>();

    if (_status == RepairStatus.selesai) {
      inv.confirmRepair(widget.record, ItemCondition.layak, _notesCtrl.text.trim());
    } else {
      inv.updateRepair(
        widget.record,
        status: _status,
        technician: _technicianCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status perbaikan berhasil diperbarui.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket Servis ${widget.record.unitCode}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.record.unitCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            Text('ID: ${widget.record.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 18),
                        Text('Barang: ${widget.record.itemName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text('Keluhan Kerusakan: ${widget.record.issue}', style: const TextStyle(fontSize: 12.5)),
                        const SizedBox(height: 4),
                        Text('Waktu Dilaporkan: ${Format.dateTime(widget.record.reportedAt)}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Update Status Perbaikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RepairStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(labelText: 'Status Servis'),
                          items: RepairStatus.values.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.label));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _technicianCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Teknisi / Vendor'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Catatan Penanganan / Sparepart yang Diganti'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: _status == RepairStatus.selesai
                        ? 'Selesaikan Servis & Kembalikan ke Tersedia'
                        : 'Simpan Update Perbaikan',
                    icon: Icons.save,
                    onPressed: _save,
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
