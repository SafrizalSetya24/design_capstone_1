import 'package:flutter/material.dart';
import 'package:sipintar/features/consumables/consumable_user_pages.dart';
import 'package:sipintar/features/inventory/unit_catalog.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class CatalogPage extends StatelessWidget {
  final int initialTab;
  const CatalogPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: const AppPage(
        title: 'Katalog',
        bottom: TabBar(tabs: [Tab(text: 'Barang Per Unit'), Tab(text: 'Barang Habis Pakai')]),
        body: TabBarView(children: [UnitCatalogView(), ConsumableCatalogView()]),
      ),
    );
  }
}
