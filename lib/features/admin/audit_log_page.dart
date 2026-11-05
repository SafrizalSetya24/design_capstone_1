import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});
  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String _user = 'Semua pengguna';
  String _period = 'Semua';
  String _type = 'Semua';

  @override
  Widget build(BuildContext context) {
    final audit = context.watch<AuditStore>();
    final names = [
      'Semua pengguna',
      ...{for (final e in audit.entries) e.userName}
    ];
    final types = [
      'Semua',
      ...{for (final e in audit.entries) e.type}
    ];
    final now = DateTime.now();
    final list = audit.entries.where((e) {
      if (_user != 'Semua pengguna' && e.userName != _user) return false;
      if (_type != 'Semua' && e.type != _type) return false;
      final age = now.difference(e.time);
      if (_period == 'Hari ini' && age.inHours >= 24) return false;
      if (_period == '7 hari' && age.inDays >= 7) return false;
      if (_period == '30 hari' && age.inDays >= 30) return false;
      return true;
    }).toList();

    return AppPage(
      title: 'Audit Log',
      body: SimLoading(
        child: PageList(children: [
          AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppDropdown.strings(
                  label: 'Pengguna',
                  icon: Icons.person_search_outlined,
                  value: _user,
                  options: names,
                  onChanged: (v) => setState(() => _user = v ?? _user)),
              FilterRow(
                  label: 'Periode',
                  options: const ['Semua', 'Hari ini', '7 hari', '30 hari'],
                  selected: _period,
                  onSelected: (v) => setState(() => _period = v)),
              FilterRow(
                  label: 'Jenis aktivitas',
                  options: types,
                  selected: _type,
                  onSelected: (v) => setState(() => _type = v)),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${list.length} aktivitas',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ResponsiveTable(
            emptyText: 'Tidak ada aktivitas pada filter ini.',
            columns: const ['Waktu', 'Pengguna', 'Role', 'Jenis', 'Aktivitas'],
            onRowTap: (i) => push(context, AuditDetailPage(entry: list[i])),
            rows: [
              for (final e in list)
                [
                  cellText(Fmt.dateTime(e.time)),
                  cellText(e.userName, bold: true),
                  cellText(e.role),
                  StatusBadge(e.type, tone: BadgeTone.info),
                  cellText(e.detail)
                ],
            ],
          ),
        ]),
      ),
    );
  }
}

class AuditDetailPage extends StatelessWidget {
  final AuditEntry entry;
  const AuditDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Detail Aktivitas',
        body: PageList(children: [
          ResponsiveBody(
            maxWidth: 720,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                      child: Text(entry.detail,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.4))),
                  const SizedBox(height: AppSpacing.md),
                  InfoCard(rows: [
                    ('ID log', entry.id),
                    ('Pengguna', entry.userName),
                    ('Role', entry.role),
                    ('Jenis aktivitas', entry.type),
                    ('Waktu', Fmt.dateTime(entry.time)),
                  ]),
                ]),
          ),
        ]),
      );
}
