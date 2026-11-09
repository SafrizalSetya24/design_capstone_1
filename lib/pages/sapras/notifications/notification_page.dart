import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasNotificationPage extends StatelessWidget {
  const SaprasNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final notifs = context.watch<NotificationStore>();
    final items = user == null ? <AppNotification>[] : notifs.forUser(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Operasional Sapras'),
        actions: [
          if (items.isNotEmpty && user != null)
            TextButton(
              onPressed: () => notifs.markAll(user.id),
              child: const Text('Tandai Dibaca', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 54, color: Theme.of(context).hintColor),
                  const SizedBox(height: 12),
                  Text('Tidak ada notifikasi baru untuk Sapras.', style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final n = items[idx];
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
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.bold, fontSize: 13.5)),
                                  Text(Format.time(n.time), style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, style: TextStyle(fontSize: 12, color: n.read ? Theme.of(context).hintColor : null)),
                            ],
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
