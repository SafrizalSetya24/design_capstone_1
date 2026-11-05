import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

enum NotifType {
  pengajuan,
  persetujuan,
  penolakan,
  kedaluwarsa,
  pengingat,
  habisPakai
}

extension NotifTypeX on NotifType {
  String get label => switch (this) {
        NotifType.pengajuan => 'Pengajuan berhasil',
        NotifType.persetujuan => 'Persetujuan',
        NotifType.penolakan => 'Penolakan',
        NotifType.kedaluwarsa => 'Booking kedaluwarsa',
        NotifType.pengingat => 'Pengingat pengembalian',
        NotifType.habisPakai => 'Barang habis pakai',
      };
  IconData get icon => switch (this) {
        NotifType.pengajuan => Icons.send_rounded,
        NotifType.persetujuan => Icons.check_circle_outline,
        NotifType.penolakan => Icons.cancel_outlined,
        NotifType.kedaluwarsa => Icons.timer_off_outlined,
        NotifType.pengingat => Icons.alarm,
        NotifType.habisPakai => Icons.inventory_outlined,
      };
  Color get color => switch (this) {
        NotifType.pengajuan => AppColors.blue,
        NotifType.persetujuan => AppColors.success,
        NotifType.penolakan => AppColors.danger,
        NotifType.kedaluwarsa => AppColors.danger,
        NotifType.pengingat => AppColors.warning,
        NotifType.habisPakai => AppColors.blue,
      };
}

class AppNotification {
  final String id, userId, title, body;
  final NotifType type;
  final DateTime time;
  bool read;
  final String? refId;
  final bool refIsLoan;
  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.read = false,
    this.refId,
    this.refIsLoan = true,
  });
}

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  ChatMessage(this.text, this.fromUser) : time = DateTime.now();
}

class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;
  DateTime updated;
  ChatSession(
      {required this.id, required this.title, List<ChatMessage>? messages})
      : messages = messages ?? [],
        updated = DateTime.now();
}

class AuditEntry {
  final String id, userName, role, type, detail;
  final DateTime time;
  AuditEntry({
    required this.id,
    required this.userName,
    required this.role,
    required this.type,
    required this.detail,
    required this.time,
  });
}
