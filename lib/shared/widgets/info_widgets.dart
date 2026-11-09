import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/shared/widgets/app_card.dart';
import 'package:sipintar/shared/widgets/primary_button.dart';
import 'package:sipintar/shared/widgets/responsive_body.dart';
import 'package:sipintar/shared/widgets/state_views.dart';
import 'package:sipintar/shared/widgets/status_badge.dart';

/// Daftar vertikal dengan lebar terbatas dan padding standar.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const PageList(
      {super.key,
      required this.children,
      this.padding = const EdgeInsets.all(AppSpacing.md)});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: padding,
        child: ResponsiveBody(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children)),
      );
}

class InfoCard extends StatelessWidget {
  final String? title;
  final List<(String, String)> rows;
  final Widget? trailing;
  const InfoCard({super.key, this.title, required this.rows, this.trailing});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                    child: Text(title!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15))),
                if (trailing != null) trailing!,
              ]),
            ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 118,
                    child: Text(r.$1,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13))),
                Expanded(
                    child: Text(r.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14))),
              ]),
            ),
        ]),
      );
}

class RowCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> extra;
  final VoidCallback? onTap;
  const RowCard(
      {super.key,
      this.leading,
      required this.title,
      this.subtitle,
      this.trailing,
      this.extra = const [],
      this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          onTap: onTap,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                      ),
                    for (final e in extra)
                      Padding(padding: const EdgeInsets.only(top: 8), child: e),
                  ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      );
}

/// Identitas peminjam/pemohon. Label identitas mengikuti role: Siswa = NIS + Kelas, Guru = NIK + Jabatan/mapel.
class BorrowerCard extends StatelessWidget {
  final Borrower b;
  final String title;
  const BorrowerCard(this.b, {super.key, this.title = 'Identitas'});
  @override
  Widget build(BuildContext context) {
    final isSiswa = b.role == UserRole.siswa;
    final c = isSiswa ? AppColors.blue : AppColors.navy;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        Row(children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: c,
              child: Text(
                  b.name.trim().isEmpty ? '?' : b.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _chip(b.role.label, c, bold: true),
                _chip('${b.identityLabel}: ${b.identityValue}', c),
                if (b.extraValue != null)
                  _chip('${b.extraLabel}: ${b.extraValue}', c),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _chip(String t, Color c, {bool bold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      );
}

class FormScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final GlobalKey<FormState>? formKey;
  final bool loading;
  final IconData? submitIcon;
  final List<Widget>? actions;
  const FormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.formKey,
    this.loading = false,
    this.submitIcon,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ResponsiveBody(
              maxWidth: 780,
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in children) ...[
                        c,
                        const SizedBox(height: AppSpacing.md)
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                          label: submitLabel,
                          icon: submitIcon,
                          loading: loading,
                          onPressed: onSubmit),
                    ]),
              ),
            ),
          ),
        ),
      );
}

class SimLoading extends StatefulWidget {
  final Widget child;
  final int ms;
  const SimLoading({super.key, required this.child, this.ms = 600});
  @override
  State<SimLoading> createState() => _SimLoadingState();
}

class _SimLoadingState extends State<SimLoading> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.ms), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : const LoadingView();
}

class SuccessView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? extra;
  final String primaryLabel;
  final void Function(BuildContext context) onPrimary;
  final String? secondaryLabel;
  final void Function(BuildContext context)? onSecondary;
  const SuccessView({
    super.key,
    this.icon = Icons.check_circle,
    this.color = AppColors.success,
    required this.title,
    required this.message,
    this.extra,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ResponsiveBody(
                maxWidth: 520,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                      radius: 46,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(icon, size: 56, color: color)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5)),
                  if (extra != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    extra!
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                      label: primaryLabel, onPressed: () => onPrimary(context)),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                        onPressed: () => onSecondary?.call(context),
                        child: Text(secondaryLabel!)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

/// Riwayat status vertikal untuk peminjaman.
class LoanTimeline extends StatelessWidget {
  final List<LoanEvent> events;
  const LoanTimeline(this.events, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < events.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 26,
              child: Column(children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                      color: StatusBadge.colorOf(
                          StatusBadge.toneOf(StatusBadge.extractLabel(events[i].status))),
                      shape: BoxShape.circle),
                ),
                if (i != events.length - 1)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(StatusBadge.extractLabel(events[i].status),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(_t(events[i].time),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      if (events[i].note != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(events[i].note!,
                                style: const TextStyle(fontSize: 12.5))),
                    ]),
              ),
            ),
          ]),
        ),
    ]);
  }

  String _t(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
}
