import 'package:flutter/foundation.dart';
import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/misc_models.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/data/stores/auth_store.dart';
import 'package:sipintar/data/stores/consumable_store.dart';
import 'package:sipintar/data/stores/inventory_store.dart';
import 'package:sipintar/data/stores/loan_store.dart';

/// Chatbot SIMULASI: jawaban disusun dari data dummy lokal, bukan model AI sungguhan.
class ChatStore extends ChangeNotifier {
  ChatStore(this._auth, this._inv, this._cons, this._loans);
  final AuthStore _auth;
  final InventoryStore _inv;
  final ConsumableStore _cons;
  final LoanStore _loans;

  final Map<String, List<ChatSession>> _sessions = {};
  final Map<String, String> _activeId = {};
  bool loading = false;
  int _n = 0;

  String get _uid => _auth.currentUser?.id ?? '-';
  List<ChatSession> get sessions => _sessions.putIfAbsent(_uid, () => [_fresh()]);
  ChatSession get active {
    final id = _activeId[_uid];
    return sessions.firstWhere((s) => s.id == id, orElse: () => sessions.first);
  }

  ChatSession _fresh() => ChatSession(id: 'c${_n++}', title: 'Percakapan baru');

  void newChat() {
    final s = _fresh();
    sessions.insert(0, s);
    _activeId[_uid] = s.id;
    notifyListeners();
  }

  void open(ChatSession s) {
    _activeId[_uid] = s.id;
    notifyListeners();
  }

  void deleteSession(ChatSession s) {
    sessions.remove(s);
    if (sessions.isEmpty) sessions.add(_fresh());
    notifyListeners();
  }

  List<String> suggestions(UserRole role) => role == UserRole.sapras
      ? [
          'Berapa laptop yang tersedia?',
          'Barang apa yang stoknya menipis?',
          'Ada berapa pengajuan menunggu persetujuan?',
          'Berapa unit yang perlu diperbaiki?',
        ]
      : [
          'Bagaimana cara meminjam laptop?',
          'Apakah proyektor tersedia?',
          'Bagaimana status pengajuan saya?',
          'Stok kertas masih ada?',
        ];

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || loading) return;
    final s = active;
    if (s.messages.isEmpty) s.title = t.length > 32 ? '${t.substring(0, 32)}...' : t;
    s.messages.add(ChatMessage(t, true));
    s.updated = DateTime.now();
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1300));
    s.messages.add(ChatMessage(_answer(t.toLowerCase()), false));
    loading = false;
    notifyListeners();
  }

  String _answer(String q) {
    final me = _auth.currentUser;
    final isStaff = me?.role == UserRole.sapras;
    if (q.contains('stok') || q.contains('habis pakai') || q.contains('menipis') || q.contains('kertas') || q.contains('spidol')) {
      for (final i in _cons.items) {
        if (q.contains(i.name.toLowerCase().split(' ').first) && !q.contains('menipis')) {
          return 'Stok ${i.name} saat ini ${i.stock} ${i.satuan} (minimum ${i.minStock}).'
              '${i.low ? ' Stok sudah menipis.' : ''}';
        }
      }
      final low = _cons.lowStock;
      if (low.isEmpty) return 'Semua barang habis pakai masih di atas stok minimum.';
      return 'Barang dengan stok menipis:\n${low.map((i) => '- ${i.name}: ${i.stock} ${i.satuan} (min. ${i.minStock})').join('\n')}';
    }
    if (q.contains('rusak') || q.contains('perbaik')) {
      return 'Kondisi unit saat ini: ${_inv.countCond(ItemCondition.layak)} layak pakai, '
          '${_inv.countCond(ItemCondition.perluDiperbaiki)} perlu diperbaiki, '
          '${_inv.countCond(ItemCondition.rusakTotal)} rusak total.';
    }
    if (q.contains('cara') || q.contains('ajukan')) {
      return 'Cara meminjam barang per unit:\n1. Buka tab Katalog lalu pilih barang.\n2. Tekan Ajukan peminjaman dan isi jumlah, jadwal, serta tujuan.\n3. Konfirmasi ringkasan, lalu lakukan verifikasi wajah.\n4. Tunggu persetujuan Sapras maksimal 12 jam.';
    }
    if (q.contains('status') || q.contains('pengajuan') || q.contains('pinjam') || q.contains('peminjaman')) {
      if (isStaff) {
        final p = _loans.count({LoanStatus.menungguPersetujuan});
        final c = _cons.countStatus(ConsumableStatus.menunggu);
        return 'Saat ini ada $p pengajuan peminjaman dan $c permintaan barang habis pakai yang menunggu persetujuan.';
      }
      final mine = me == null ? <LoanRequest>[] : _loans.forUser(me.id);
      if (mine.isEmpty) return 'Anda belum memiliki pengajuan peminjaman.';
      final l = mine.first;
      return 'Pengajuan terbaru Anda ${l.id} (${l.summary}) berstatus "${l.status.label}".';
    }
    for (final i in _inv.items) {
      final key = i.name.toLowerCase().split(' ').first;
      if (q.contains(key)) {
        return '${i.name}: ${i.available} dari ${i.total} unit tersedia untuk dipinjam. Lokasi: ${i.location}.';
      }
    }
    if (q.contains('tersedia') || q.contains('inventaris')) {
      return 'Total ${_inv.totalUnits} unit terdata. ${_inv.items.map((i) => '${i.name}: ${i.available}/${i.total}').join('; ')}.';
    }
    return 'Maaf, saya belum memahami pertanyaan itu. Coba tanyakan tentang ketersediaan barang, stok, atau status peminjaman.';
  }
}
