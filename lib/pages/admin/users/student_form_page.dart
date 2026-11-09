import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminStudentFormPage extends StatefulWidget {
  final Siswa? student;
  const AdminStudentFormPage({super.key, this.student});

  @override
  State<AdminStudentFormPage> createState() => _AdminStudentFormPageState();
}

class _AdminStudentFormPageState extends State<AdminStudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nisCtrl = TextEditingController();
  final _classCtrl = TextEditingController(text: 'XI RPL 1');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'smkmuhamka123');

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameCtrl.text = widget.student!.name;
      _nisCtrl.text = widget.student!.nis;
      _classCtrl.text = widget.student!.kelas;
      _emailCtrl.text = widget.student!.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nisCtrl.dispose();
    _classCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final isNew = widget.student == null;

    if (isNew) {
      auth.registerSiswa(
        nis: _nisCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        kelas: _classCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } else {
      auth.updateUser(widget.student!.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        extra: _classCtrl.text.trim(),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data siswa ${_nameCtrl.text} berhasil disimpan.')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Data Siswa' : 'Tambah Akun Siswa Baru'),
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
                          const Text('Informasi Akun Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Divider(height: 20),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Nama Lengkap Siswa'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nisCtrl,
                            enabled: !isEdit,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Nomor Induk Siswa (NIS)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'NIS wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _classCtrl,
                            decoration: const InputDecoration(labelText: 'Kelas (contoh: X TKJ 1, XI RPL 1)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Kelas wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Siswa'),
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
                      label: isEdit ? 'Simpan Perubahan' : 'Buat Akun Siswa',
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
