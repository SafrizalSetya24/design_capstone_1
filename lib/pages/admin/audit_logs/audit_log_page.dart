import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminAuditLogPage extends StatelessWidget {
  const AdminAuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audit = context.watch<AuditStore>();
    final logs = audit.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log Sistem'),
      ),
      body: SafeArea(
        child: logs.isEmpty
            ? const Center(child: Text('Belum ada riwayat aktivitas sistem.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final e = logs[idx];
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(Format.dateTime(e.time), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(e.detail, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Pelaku: ${e.actor} (${e.role})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
