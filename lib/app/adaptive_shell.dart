import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/navigation.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_actions.dart';
import 'package:sipintar/pages/auth/login_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});
  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final _navKey = GlobalKey<NavigatorState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _id;

  void _go(List<NavItem> items, String id, {int arg = 0}) {
    if (_id == id) return;
    final it = items.firstWhere((i) => i.id == id, orElse: () => items.first);
    setState(() => _id = it.id);
    _navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => it.builder(arg)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final settings = context.watch<SettingsStore>();
    final unread =
        user == null ? 0 : context.watch<NotificationStore>().unread(user.id);
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
      return const LoginPage();
    }

    final items = navItemsFor(user, settings);
    final id = items.any((i) => i.id == _id) ? _id! : items.first.id;
    final size = Breakpoints.of(MediaQuery.of(context).size.width);
    final bottomItems = items.where((i) => i.bottom).toList();
    final useBottom = size == ScreenSize.mobile && bottomItems.isNotEmpty;
    void go(String i, {int arg = 0}) => _go(items, i, arg: arg);

    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final n = _navKey.currentState;
        if (n != null && n.canPop()) {
          n.pop();
        } else if (id != items.first.id) {
          go(items.first.id);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (s) => MaterialPageRoute(
            settings: s, builder: (_) => items.first.builder(0)),
      ),
    );

    Widget layout;
    switch (size) {
      case ScreenSize.desktop:
        layout = Scaffold(
          body: Row(children: [
            SizedBox(
                width: 264,
                child: _SidebarPanel(
                    items: items,
                    current: id,
                    user: user,
                    unread: unread,
                    onSelect: go)),
            Expanded(
                child: Column(children: [
              _Header(
                  user: user,
                  unread: unread,
                  onGo: go,
                  school: settings.schoolName,
                  year: settings.academicYear,
                  showName: true),
              Expanded(child: content),
            ])),
          ]),
        );
      case ScreenSize.tablet:
        final idx = items.indexWhere((i) => i.id == id);
        layout = Scaffold(
          body: Row(children: [
            Container(
              color: Colors.white,
              child: LayoutBuilder(
                builder: (c, cons) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: cons.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        minWidth: 84,
                        selectedIndex: idx < 0 ? 0 : idx,
                        labelType: NavigationRailLabelType.all,
                        leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SipintarLogo(size: 44)),
                        onDestinationSelected: (i) => go(items[i].id),
                        destinations: [
                          for (final it in items)
                            NavigationRailDestination(
                              icon: _icon(it, false, unread),
                              selectedIcon: _icon(it, true, unread),
                              label: Text(it.short,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
                child: Column(children: [
              _Header(
                  user: user,
                  unread: unread,
                  onGo: go,
                  school: settings.schoolName,
                  year: settings.academicYear,
                  showName: true),
              Expanded(child: content),
            ])),
          ]),
        );
      case ScreenSize.mobile:
        final bIdx = bottomItems.indexWhere((i) => i.id == id);
        layout = Scaffold(
          key: _scaffoldKey,
          drawer: useBottom
              ? null
              : Drawer(
                  child: _SidebarPanel(
                    items: items,
                    current: id,
                    user: user,
                    unread: unread,
                    onSelect: (i, {int arg = 0}) {
                      _scaffoldKey.currentState?.closeDrawer();
                      go(i, arg: arg);
                    },
                  ),
                ),
          body: content,
          bottomNavigationBar: useBottom
              ? NavigationBar(
                  selectedIndex: bIdx < 0 ? 0 : bIdx,
                  onDestinationSelected: (i) => go(bottomItems[i].id),
                  destinations: [
                    for (final it in bottomItems)
                      NavigationDestination(
                          icon: _icon(it, false, unread),
                          selectedIcon: _icon(it, true, unread),
                          label: it.label),
                  ],
                )
              : null,
        );
    }

    return ShellScope(
      showMenu: size == ScreenSize.mobile && !useBottom,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      go: go,
      current: id,
      child: layout,
    );
  }
}

Widget _icon(NavItem it, bool selected, int unread) {
  final icon = Icon(selected ? it.selectedIcon : it.icon);
  if (it.id != 'notifikasi' || unread == 0) return icon;
  return Badge(label: Text('$unread'), child: icon);
}

class _SidebarPanel extends StatelessWidget {
  final List<NavItem> items;
  final String current;
  final AppUser user;
  final int unread;
  final void Function(String id, {int arg}) onSelect;
  const _SidebarPanel(
      {required this.items,
      required this.current,
      required this.user,
      required this.unread,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? group;
    for (final it in items) {
      if (it.group != group) {
        group = it.group;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
          child: Text(it.group.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary)),
        ));
      }
      final sel = it.id == current;
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: sel ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelect(it.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(children: [
                IconTheme(
                    data: IconThemeData(
                        size: 20,
                        color: sel ? Colors.white : AppColors.textSecondary),
                    child: _icon(it, sel, unread)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(it.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: sel ? Colors.white : AppColors.textPrimary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
      ));
    }
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: AppColors.border))),
      child: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 16, 4),
            child: Row(children: [
              SipintarLogo(size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('inventarisMuhamka',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                      Text('Inventaris Sekolah',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ]),
              ),
            ]),
          ),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: children)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.navy,
                  child: Text(user.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                          '${user.role.label} - ${user.identityLabel}: ${user.identityValue}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ]),
              ),
              IconButton(
                  tooltip: 'Keluar',
                  onPressed: () => confirmLogout(context),
                  icon: const Icon(Icons.logout, size: 20)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser user;
  final int unread;
  final void Function(String id, {int arg}) onGo;
  final String school;
  final String year;
  final bool showName;
  const _Header(
      {required this.user,
      required this.unread,
      required this.onGo,
      required this.school,
      required this.year,
      required this.showName});

  @override
  Widget build(BuildContext context) {
    final isUser = user.role == UserRole.siswa || user.role == UserRole.guru;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.navy)),
                Text('Tahun ajaran $year',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
        ),
        if (isUser)
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => onGo('notifikasi'),
            icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none)),
          ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Akun',
          onSelected: (v) =>
              v == 'profil' ? onGo('profil') : confirmLogout(context),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profil', child: Text('Profil')),
            PopupMenuItem(value: 'logout', child: Text('Keluar')),
          ],
          child: Row(children: [
            CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.navy,
                child: Text(user.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800))),
            if (showName && MediaQuery.of(context).size.width >= 760) ...[
              const SizedBox(width: 8),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(user.role.label,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]),
            ],
            const Icon(Icons.arrow_drop_down),
          ]),
        ),
      ]),
    );
  }
}
