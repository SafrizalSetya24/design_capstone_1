import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminTeacherFormPage extends StatefulWidget {
  final Guru? teacher;
  const AdminTeacherFormPage({super.key, this.teacher});

  @override
  State<AdminTeacherFormPage> createState() => _AdminTeacherFormPageState();
}

class _AdminTeacherFormPageState extends State<AdminTeacherFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _mapelCtrl = TextEditingController(text: 'Pemrograman Web & Mobile');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'guruMuhamka123');

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameCtrl.text = widget.teacher!.name;
      _nikCtrl.text = widget.teacher!.nik;
      _mapelCtrl.text = widget.teacher!.jabatan;
      _emailCtrl.text = widget.teacher!.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _mapelCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final isNew = widget.teacher == null;

    if (isNew) {
      auth.registerGuru(
        nik: _nikCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        jabatan: _mapelCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } else {
      auth.updateUser(widget.teacher!.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        extra: _mapelCtrl.text.trim(),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data guru ${_nameCtrl.text} berhasil disimpan.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.teacher != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Data Guru' : 'Tambah Akun Guru Baru'),
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
                          const Text('Informasi Akun Guru / Pengajar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Divider(height: 20),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Nama Lengkap Guru (dengan gelar)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nikCtrl,
                            enabled: !isEdit,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Nomor Induk Kependudukan / NIP (NIK)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _mapelCtrl,
                            decoration: const InputDecoration(labelText: 'Mata Pelajaran / Jabatan'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Mata pelajaran wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Guru'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                          ),
                          if (!isEdit) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: const InputDecoration(labelText: 'Password Awal Akun'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: isEdit ? 'Simpan Perubahan' : 'Buat Akun Guru',
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
