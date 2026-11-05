import 'package:flutter/material.dart';
import 'package:sipintar/core/responsive/responsive.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/shared/widgets/app_card.dart';
import 'package:sipintar/shared/widgets/shell_scope.dart';

/// Grid adaptif: jumlah kolom dihitung dari lebar area dan [minItemWidth].
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  const ResponsiveGrid(
      {super.key,
      required this.children,
      this.minItemWidth = 260,
      this.spacing = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.isFinite
            ? c.maxWidth
            : MediaQuery.of(context).size.width;
        var cols = ((w + spacing) / (minItemWidth + spacing)).floor();
        if (cols < 1) cols = 1;
        final itemW = (w - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: itemW, child: c)
          ],
        );
      });
}

/// Baris form: dua kolom jika ruang cukup, satu kolom jika sempit.
class FormRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  const FormRow({super.key, required this.children, this.breakpoint = 560});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < breakpoint || children.length < 2) {
          return Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: children[i]),
            ]
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: children[i]),
          ]
        ]);
      });
}

/// Dua panel berdampingan pada layar lebar, bertumpuk pada layar sempit.
class TwoPane extends StatelessWidget {
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;
  final double breakpoint;
  const TwoPane(
      {super.key,
      required this.left,
      required this.right,
      this.leftFlex = 3,
      this.rightFlex = 2,
      this.breakpoint = 860});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: AppSpacing.md), right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: rightFlex, child: right),
        ]);
      });
}

/// Tabel responsif: DataTable dengan gulir horizontal pada layar lebar,
/// daftar kartu ringkas pada layar mobile.
class ResponsiveTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final void Function(int index)? onRowTap;
  final String emptyText;
  const ResponsiveTable(
      {super.key,
      required this.columns,
      required this.rows,
      this.onRowTap,
      this.emptyText = 'Tidak ada data.'});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppCard(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(emptyText,
                      style:
                          const TextStyle(color: AppColors.textSecondary)))));
    }
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < Breakpoints.mobile) {
        return Column(children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: onRowTap == null ? null : () => onRowTap!(i),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                          child: rows[i].first),
                      const SizedBox(height: 6),
                      for (var j = 1; j < rows[i].length; j++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 104,
                                    child: Text(columns[j],
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary))),
                                Expanded(
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: rows[i][j])),
                              ]),
                        ),
                    ]),
              ),
            ),
        ]);
      }
      return AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontSize: 13),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 28,
              columns: [
                for (final col in columns) DataColumn(label: Text(col))
              ],
              rows: [
                for (var i = 0; i < rows.length; i++)
                  DataRow(
                    onSelectChanged:
                        onRowTap == null ? null : (_) => onRowTap!(i),
                    cells: [for (final cell in rows[i]) DataCell(cell)],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Halaman standar: AppBar + isi. Di dalam shell adaptif, otomatis menampilkan
/// tombol menu (mobile) pada halaman tingkat atas atau tombol kembali pada halaman detail.
class AppPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  final PreferredSizeWidget? bottom;
  const AppPage(
      {super.key,
      required this.title,
      required this.body,
      this.actions,
      this.fab,
      this.bottom});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom,
        automaticallyImplyLeading: canPop,
        leading: (!canPop && shell != null && shell.showMenu)
            ? IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: shell.openDrawer)
            : null,
      ),
      body: body,
      floatingActionButton: fab,
    );
  }
}

/// Teks sel tabel.
Widget cellText(String t, {bool bold = false, Color? color}) => Text(t,
    style: TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color));
