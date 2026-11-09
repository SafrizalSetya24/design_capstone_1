import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final notifs = context.watch<NotificationStore>();
    final items = user == null ? <AppNotification>[] : notifs.forUser(user.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('beranda');
            }
          },
        ),
        title: const Text('Notifikasi'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => notifs.markAll(user!.id),
              child: const Text('Tandai Dibaca', style: TextStyle(color: AppColors.navy)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 56, color: Theme.of(context).hintColor),
                  const SizedBox(height: 12),
                  Text('Belum ada notifikasi.', style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final n = items[idx];
                final icon = switch (n.type) {
                  NotifType.pengajuan => Icons.send_outlined,
                  NotifType.persetujuan => Icons.check_circle_outline,
                  NotifType.penolakan => Icons.cancel_outlined,
                  NotifType.kedaluwarsa => Icons.timer_off_outlined,
                  NotifType.pengingat => Icons.alarm,
                  _ => Icons.notifications_outlined,
                };
                final color = switch (n.type) {
                  NotifType.persetujuan => Colors.green,
                  NotifType.penolakan => Colors.red,
                  NotifType.kedaluwarsa => Colors.orange,
                  _ => AppColors.primary,
                };

                return InkWell(
                  onTap: () => notifs.markRead(n.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.read ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    Format.time(n.time),
                                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: n.read ? Theme.of(context).hintColor : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
