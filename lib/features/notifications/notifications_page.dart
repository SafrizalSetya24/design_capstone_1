import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_detail_page.dart';
import 'package:sipintar/features/consumables/consumable_user_pages.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _type = 'Semua';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    final store = context.watch<NotificationStore>();
    final all = store.forUser(user.id);
    final list = _type == 'Semua' ? all : all.where((n) => n.type.label == _type).toList();
    return AppPage(
      title: 'Notifikasi',
      actions: [
        IconButton(
          tooltip: 'Tandai semua dibaca',
          icon: const Icon(Icons.done_all),
          onPressed: store.unread(user.id) == 0
              ? null
              : () {
                  store.markAllRead(user.id);
                  snack(context, 'Semua notifikasi ditandai dibaca.');
                },
        ),
      ],
      body: SimLoading(
        child: PageList(children: [
          FilterRow(label: 'Jenis', options: ['Semua', ...NotifType.values.map((t) => t.label)], selected: _type, onSelected: (v) => setState(() => _type = v)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const SizedBox(height: 280, child: EmptyState(icon: Icons.notifications_off_outlined, title: 'Tidak ada notifikasi', message: 'Notifikasi persetujuan dan pengingat akan muncul di sini.'))
          else
            ResponsiveGrid(minItemWidth: 420, children: [
              for (final n in list)
                RowCard(
                  leading: CircleAvatar(backgroundColor: n.type.color.withOpacity(0.12), child: Icon(n.type.icon, color: n.type.color, size: 20)),
                  title: n.title,
                  subtitle: Fmt.ago(n.time),
                  extra: [Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))],
                  trailing: n.read ? null : const CircleAvatar(radius: 5, backgroundColor: AppColors.blue),
                  onTap: () => push(context, NotificationDetailPage(notifId: n.id)),
                ),
            ]),
        ]),
      ),
    );
  }
}

class NotificationDetailPage extends StatefulWidget {
  final String notifId;
  const NotificationDetailPage({super.key, required this.notifId});
  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationStore>().markRead(widget.notifId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationStore>();
    final matches = store.items.where((n) => n.id == widget.notifId);
    if (matches.isEmpty) {
      return const AppPage(title: 'Detail Notifikasi', body: EmptyState(icon: Icons.notifications_off_outlined, title: 'Notifikasi tidak ditemukan', message: 'Data mungkin sudah tidak tersedia.'));
    }
    final n = matches.first;
    return AppPage(
      title: 'Detail Notifikasi',
      body: PageList(children: [
        ResponsiveBody(
          maxWidth: 720,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 24, backgroundColor: n.type.color.withOpacity(0.12), child: Icon(n.type.icon, color: n.type.color)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(n.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 14),
                Text(n.body, style: const TextStyle(height: 1.5, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(rows: [('Jenis', n.type.label), ('Waktu', Fmt.dateTime(n.time)), if (n.refId != null) ('Referensi', n.refId!)]),
            if (n.refId != null) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Lihat transaksi',
                icon: Icons.open_in_new,
                onPressed: () => push(context, n.refIsLoan ? LoanDetailPage(loanId: n.refId!) : ConsumableRequestDetailPage(requestId: n.refId!)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
