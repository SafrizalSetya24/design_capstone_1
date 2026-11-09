import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

enum NotifType {
  pengajuan('Pengajuan berhasil', Icons.send_rounded, AppColors.blue),
  persetujuan('Persetujuan', Icons.check_circle_outline, AppColors.success),
  penolakan('Penolakan', Icons.cancel_outlined, AppColors.danger),
  kedaluwarsa('Booking kedaluwarsa', Icons.timer_off_outlined, AppColors.danger),
  pengingat('Pengingat pengembalian', Icons.alarm, AppColors.warning),
  habisPakai('Barang habis pakai', Icons.inventory_outlined, AppColors.blue);

  final String label;
  final IconData icon;
  final Color color;
  const NotifType(this.label, this.icon, this.color);
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
  String get actor => userName;
}
