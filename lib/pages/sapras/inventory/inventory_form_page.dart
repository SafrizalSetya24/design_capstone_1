import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasInventoryFormPage extends StatefulWidget {
  const SaprasInventoryFormPage({super.key});

  @override
  State<SaprasInventoryFormPage> createState() => _SaprasInventoryFormPageState();
}

class _SaprasInventoryFormPageState extends State<SaprasInventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController(text: 'Elektronik');
  final _locCtrl = TextEditingController(text: 'Lab Komputer 1');
  final _descCtrl = TextEditingController();
  int _initialUnits = 3;
  String _prefix = 'LPT';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final inv = context.read<InventoryStore>();
    inv.addItem(
      name: _nameCtrl.text.trim(),
      category: _catCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      iconKey: 'laptop',
      count: _initialUnits,
      condition: ItemCondition.layak,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Model barang dan unit fisik berhasil ditambahkan.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Model Barang Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Model Inventaris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Divider(height: 20),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Nama Model / Spesifikasi Barang (contoh: ThinkPad E14)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _catCtrl,
                            decoration: const InputDecoration(labelText: 'Kategori (contoh: Elektronik, Multimedia)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Kategori wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _locCtrl,
                            decoration: const InputDecoration(labelText: 'Lokasi Penyimpanan (contoh: Gudang Sapras A)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Lokasi wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'Deskripsi Singkat / Kelengkapan'),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _prefix,
                                  decoration: const InputDecoration(labelText: 'Prefix Barcode (contoh: LPT, PRJ)'),
                                  onChanged: (v) => _prefix = v,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '$_initialUnits',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Jumlah Unit Awal'),
                                  onChanged: (v) => _initialUnits = int.tryParse(v) ?? 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Simpan Model & Buat Unit Barcode',
                      icon: Icons.save,
                      onPressed: _save,
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
