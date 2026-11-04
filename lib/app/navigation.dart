import 'package:flutter/material.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/account/profile_page.dart';
import 'package:sipintar/features/admin/admin_dashboard_page.dart';
import 'package:sipintar/features/admin/audit_log_page.dart';
import 'package:sipintar/features/admin/category_management_page.dart';
import 'package:sipintar/features/admin/role_management_page.dart';
import 'package:sipintar/features/admin/system_settings_page.dart';
import 'package:sipintar/features/admin/user_management_page.dart';
import 'package:sipintar/features/borrowing/handover_page.dart';
import 'package:sipintar/features/borrowing/loan_approvals_page.dart';
import 'package:sipintar/features/borrowing/returns_page.dart';
import 'package:sipintar/features/chatbot/chat_page.dart';
import 'package:sipintar/features/consumables/consumable_approvals_page.dart';
import 'package:sipintar/features/consumables/consumable_management_page.dart';
import 'package:sipintar/features/forecasting/forecasting_page.dart';
import 'package:sipintar/features/inventory/condition_repair_page.dart';
import 'package:sipintar/features/inventory/inventory_management_page.dart';
import 'package:sipintar/features/inventory/scan_page.dart';
import 'package:sipintar/features/notifications/notifications_page.dart';
import 'package:sipintar/features/reports/reports_page.dart';
import 'package:sipintar/features/sapras/sapras_dashboard_page.dart';
import 'package:sipintar/features/users/catalog_page.dart';
import 'package:sipintar/features/users/history_page.dart';
import 'package:sipintar/features/users/users_dashboard_page.dart';

class NavItem {
  final String id, label, short, group;
  final IconData icon, selectedIcon;
  final bool bottom;
  final Widget Function(int arg) builder;
  const NavItem({
    required this.id,
    required this.label,
    String? short,
    required this.group,
    required this.icon,
    IconData? selectedIcon,
    this.bottom = false,
    required this.builder,
  })  : short = short ?? label,
        selectedIcon = selectedIcon ?? icon;
}

/// Menu navigasi sesuai role. Siswa dan Guru memakai menu yang sama,
/// Sapras dan Admin memakai menu sesuai kewenangannya.
List<NavItem> navItemsFor(AppUser user, SettingsStore s) {
  final role = user.role;
  switch (role) {
    case UserRole.siswa:
    case UserRole.guru:
      return [
        NavItem(id: 'beranda', label: 'Beranda', group: 'Menu', icon: Icons.home_outlined, selectedIcon: Icons.home, bottom: true, builder: (_) => const UsersDashboardPage()),
        NavItem(id: 'katalog', label: 'Katalog', group: 'Menu', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, bottom: true, builder: (a) => CatalogPage(initialTab: a)),
        NavItem(id: 'riwayat', label: 'Riwayat', group: 'Menu', icon: Icons.history, bottom: true, builder: (_) => const HistoryPage()),
        NavItem(id: 'notifikasi', label: 'Notifikasi', group: 'Menu', icon: Icons.notifications_none, selectedIcon: Icons.notifications, bottom: true, builder: (_) => const NotificationsPage()),
        NavItem(id: 'profil', label: 'Profil', group: 'Menu', icon: Icons.person_outline, selectedIcon: Icons.person, bottom: true, builder: (_) => const ProfilePage()),
        if (s.can(role, 'chatbot'))
          NavItem(id: 'chatbot', label: 'Asisten AI', group: 'Bantuan', icon: Icons.smart_toy_outlined, selectedIcon: Icons.smart_toy, builder: (_) => const ChatPage()),
      ];
    case UserRole.sapras:
      return [
        NavItem(id: 'dashboard', label: 'Dashboard', group: 'Utama', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, builder: (_) => const SaprasDashboardPage()),
        NavItem(id: 'inventaris', label: 'Manajemen Inventaris', short: 'Inventaris', group: 'Inventaris', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, builder: (_) => const InventoryManagementPage()),
        NavItem(id: 'scan', label: 'Scan Barcode', short: 'Scan', group: 'Inventaris', icon: Icons.qr_code_scanner, builder: (_) => const ScanPage()),
        NavItem(id: 'kondisi', label: 'Kondisi dan Perbaikan', short: 'Kondisi', group: 'Inventaris', icon: Icons.build_outlined, selectedIcon: Icons.build, builder: (_) => const ConditionRepairPage()),
        NavItem(id: 'stok', label: 'Barang Habis Pakai', short: 'Stok', group: 'Inventaris', icon: Icons.layers_outlined, selectedIcon: Icons.layers, builder: (_) => const ConsumableManagementPage()),
        NavItem(id: 'persetujuan', label: 'Persetujuan Peminjaman', short: 'Persetujuan', group: 'Transaksi', icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check, builder: (_) => const LoanApprovalsPage()),
        NavItem(id: 'penyerahan', label: 'Penyerahan Barang', short: 'Penyerahan', group: 'Transaksi', icon: Icons.outbox_outlined, selectedIcon: Icons.outbox, builder: (_) => const HandoverPage()),
        NavItem(id: 'pengembalian', label: 'Pengembalian Barang', short: 'Pengembalian', group: 'Transaksi', icon: Icons.move_to_inbox_outlined, selectedIcon: Icons.move_to_inbox, builder: (_) => const ReturnsPage()),
        NavItem(id: 'persetujuan_hp', label: 'Persetujuan Habis Pakai', short: 'Permintaan', group: 'Transaksi', icon: Icons.rule_folder_outlined, selectedIcon: Icons.rule_folder, builder: (_) => const ConsumableApprovalsPage()),
        if (s.can(role, 'laporan'))
          NavItem(id: 'laporan', label: 'Laporan', group: 'Analitik', icon: Icons.assessment_outlined, selectedIcon: Icons.assessment, builder: (_) => const ReportsPage()),
        if (s.can(role, 'forecasting'))
          NavItem(id: 'forecasting', label: 'Forecasting', group: 'Analitik', icon: Icons.trending_up, builder: (_) => const ForecastingPage()),
        if (s.can(role, 'chatbot'))
          NavItem(id: 'chatbot', label: 'AI Chatbot', short: 'Chatbot', group: 'Analitik', icon: Icons.smart_toy_outlined, selectedIcon: Icons.smart_toy, builder: (_) => const ChatPage()),
        NavItem(id: 'profil', label: 'Profil dan Pengaturan', short: 'Profil', group: 'Akun', icon: Icons.person_outline, selectedIcon: Icons.person, builder: (_) => const ProfilePage()),
      ];
    case UserRole.admin:
      return [
        NavItem(id: 'dashboard', label: 'Dashboard', group: 'Utama', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, builder: (_) => const AdminDashboardPage()),
        NavItem(id: 'pengguna', label: 'Manajemen Pengguna', short: 'Pengguna', group: 'Pengguna', icon: Icons.people_outline, selectedIcon: Icons.people, builder: (_) => const UserManagementPage()),
        NavItem(id: 'role', label: 'Role dan Hak Akses', short: 'Role', group: 'Pengguna', icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, builder: (_) => const RoleManagementPage()),
        NavItem(id: 'kategori', label: 'Manajemen Kategori', short: 'Kategori', group: 'Sistem', icon: Icons.category_outlined, selectedIcon: Icons.category, builder: (_) => const CategoryManagementPage()),
        NavItem(id: 'audit', label: 'Audit Log', group: 'Sistem', icon: Icons.history_edu_outlined, selectedIcon: Icons.history_edu, builder: (_) => const AuditLogPage()),
        NavItem(id: 'pengaturan', label: 'Pengaturan Sistem', short: 'Pengaturan', group: 'Sistem', icon: Icons.settings_outlined, selectedIcon: Icons.settings, builder: (_) => const SystemSettingsPage()),
        NavItem(id: 'profil', label: 'Profil Admin', short: 'Profil', group: 'Akun', icon: Icons.person_outline, selectedIcon: Icons.person, builder: (_) => const ProfilePage()),
      ];
  }
}
