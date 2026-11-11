import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/navigation.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_actions.dart';
import 'package:sipintar/pages/auth/login_page.dart';
import 'package:sipintar/pages/profile/profile_page.dart';
import 'package:sipintar/pages/review/app_review_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Shell navigasi utama aplikasi (adaptif untuk Desktop, Tablet, dan Mobile)
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _currentMenuId;

  // Navigasi ke menu yang dipilih
  void _navigateToMenu(List<NavItem> navigationItems, String targetId, {int arg = 0}) {
    if (_currentMenuId == targetId) return;

    final selectedItem = navigationItems.firstWhere(
      (item) => item.id == targetId,
      orElse: () => targetId == 'profil'
          ? NavItem(
              id: 'profil',
              label: 'Profil Pengguna',
              group: 'Akun',
              icon: Icons.person_outline,
              builder: (_) => const ProfilePage(),
            )
          : targetId == 'ulasan'
              ? NavItem(
                  id: 'ulasan',
                  label: 'Ulasan Aplikasi',
                  group: 'Akun',
                  icon: Icons.rate_review_outlined,
                  builder: (_) => const AppReviewPage(),
                )
              : navigationItems.first,
    );

    setState(() => _currentMenuId = selectedItem.id);

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => selectedItem.builder(arg)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthStore>().currentUser;
    final settingsStore = context.watch<SettingsStore>();
    final unreadNotificationCount = currentUser == null
        ? 0
        : context.watch<NotificationStore>().unread(currentUser.id);

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
      return const LoginPage();
    }

    final navigationItems = navItemsFor(currentUser, settingsStore);
    final activeId = navigationItems.any((item) => item.id == _currentMenuId)
        ? _currentMenuId!
        : navigationItems.first.id;

    final activeItem = navigationItems.firstWhere(
      (item) => item.id == activeId,
      orElse: () => navigationItems.first,
    );

    final screenSize = Breakpoints.of(MediaQuery.of(context).size.width);
    final bottomNavigationItems = navigationItems.where((item) => item.bottom).toList();
    final bool useBottomNav = screenSize == ScreenSize.mobile && bottomNavigationItems.isNotEmpty;

    void handleNavigation(String menuId, {int arg = 0}) =>
        _navigateToMenu(navigationItems, menuId, arg: arg);

    final contentWidget = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = _navigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (activeId != navigationItems.first.id) {
          handleNavigation(navigationItems.first.id);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (routeSettings) => MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => navigationItems.first.builder(0),
        ),
      ),
    );

    Widget responsiveLayout;
    switch (screenSize) {
      // Mode desktop
      case ScreenSize.desktop:
        responsiveLayout = Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 264,
                child: _SidebarPanel(
                  items: navigationItems,
                  current: activeId,
                  user: currentUser,
                  unread: unreadNotificationCount,
                  onSelect: handleNavigation,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _Header(
                      user: currentUser,
                      unread: unreadNotificationCount,
                      onGo: handleNavigation,
                      school: settingsStore.schoolName,
                      year: settingsStore.academicYear,
                      showName: true,
                      pageTitle: activeItem.label,
                    ),
                    Expanded(child: contentWidget),
                  ],
                ),
              ),
            ],
          ),
        );

      // Mode tablet
      case ScreenSize.tablet:
        final selectedIndex = navigationItems.indexWhere((item) => item.id == activeId);
        responsiveLayout = Scaffold(
          body: Row(
            children: [
              Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          minWidth: 84,
                          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                          labelType: NavigationRailLabelType.all,
                          leading: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SipintarLogo(size: 44),
                          ),
                          onDestinationSelected: (idx) =>
                              handleNavigation(navigationItems[idx].id),
                          destinations: [
                            for (final navItem in navigationItems)
                              NavigationRailDestination(
                                icon: _buildNavigationIcon(navItem, false, unreadNotificationCount),
                                selectedIcon:
                                    _buildNavigationIcon(navItem, true, unreadNotificationCount),
                                label: Text(
                                  navItem.short,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
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
                child: Column(
                  children: [
                    _Header(
                      user: currentUser,
                      unread: unreadNotificationCount,
                      onGo: handleNavigation,
                      school: settingsStore.schoolName,
                      year: settingsStore.academicYear,
                      showName: true,
                      pageTitle: activeItem.label,
                    ),
                    Expanded(child: contentWidget),
                  ],
                ),
              ),
            ],
          ),
        );

      // Mode mobile
      case ScreenSize.mobile:
        final bottomIndex = bottomNavigationItems.indexWhere((item) => item.id == activeId);
        responsiveLayout = Scaffold(
          key: _scaffoldKey,
          drawer: useBottomNav
              ? null
              : Drawer(
                  child: _SidebarPanel(
                    items: navigationItems,
                    current: activeId,
                    user: currentUser,
                    unread: unreadNotificationCount,
                    onSelect: (menuId, {int arg = 0}) {
                      _scaffoldKey.currentState?.closeDrawer();
                      handleNavigation(menuId, arg: arg);
                    },
                  ),
                ),
          body: contentWidget,
          bottomNavigationBar: useBottomNav
              ? NavigationBar(
                  selectedIndex: bottomIndex < 0 ? 0 : bottomIndex,
                  onDestinationSelected: (idx) =>
                      handleNavigation(bottomNavigationItems[idx].id),
                  destinations: [
                    for (final navItem in bottomNavigationItems)
                      NavigationDestination(
                        icon: _buildNavigationIcon(navItem, false, unreadNotificationCount),
                        selectedIcon:
                            _buildNavigationIcon(navItem, true, unreadNotificationCount),
                        label: navItem.label,
                      ),
                  ],
                )
              : null,
        );
    }

    return ShellScope(
      showMenu: screenSize == ScreenSize.mobile && !useBottomNav,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      go: handleNavigation,
      current: activeId,
      child: responsiveLayout,
    );
  }
}

/// Helper pembentuk ikon menu dengan badge notifikasi jika ada pesan belum terbaca
Widget _buildNavigationIcon(NavItem item, bool isSelected, int unreadCount) {
  final iconWidget = Icon(isSelected ? item.selectedIcon : item.icon);
  if (item.id != 'notifikasi' || unreadCount == 0) return iconWidget;
  return Badge(label: Text('$unreadCount'), child: iconWidget);
}

/// Panel Sidebar Kiri untuk Desktop & Drawer Mobile
class _SidebarPanel extends StatelessWidget {
  final List<NavItem> items;
  final String current;
  final AppUser user;
  final int unread;
  final void Function(String id, {int arg}) onSelect;

  const _SidebarPanel({
    required this.items,
    required this.current,
    required this.user,
    required this.unread,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final menuWidgets = <Widget>[];
    String? currentGroup;

    for (final navItem in items) {
      // Header kelompok menu (e.g. OPERASIONAL, MASTER DATA, AKUN)
      if (navItem.group != currentGroup) {
        currentGroup = navItem.group;
        menuWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
            child: Text(
              navItem.group.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }

      final isSelected = navItem.id == current;
      menuWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFFDBEAFE), width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(navItem.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      if (isSelected)
                        Container(
                          width: 3.5,
                          height: 18,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      IconTheme(
                        data: IconThemeData(
                          size: 20,
                          color: isSelected ? AppColors.navy : const Color(0xFF64748B),
                        ),
                        child: _buildNavigationIcon(navItem, isSelected, unread),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          navItem.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? AppColors.navy : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Logo Aplikasi
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 16, 4),
              child: Row(
                children: [
                  SipintarLogo(size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'inventarisMuhamka',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Inventaris Sekolah',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: menuWidgets,
              ),
            ),
            const Divider(height: 1),
            // Profil Ringkas & Tombol Keluar di Bawah Sidebar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect('profil'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.navy,
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                '${user.role.label} • ${user.identityValue}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Keluar',
                          onPressed: () => confirmLogout(context),
                          icon: const Icon(Icons.logout, size: 18, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header Navigasi Atas (Top App Bar) pada mode Desktop & Tablet
class _Header extends StatelessWidget {
  final AppUser user;
  final int unread;
  final void Function(String id, {int arg}) onGo;
  final String school;
  final String year;
  final bool showName;
  final String pageTitle;

  const _Header({
    required this.user,
    required this.unread,
    required this.onGo,
    required this.school,
    required this.year,
    required this.showName,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isStudentOrTeacher = user.role == UserRole.siswa || user.role == UserRole.guru;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Nama Sekolah & Tahun Ajaran
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tahun ajaran $year',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isStudentOrTeacher)
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () => onGo('notifikasi'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
          const SizedBox(width: 8),

          // Menu Dropdown Profil di Pojok Kanan Atas
          PopupMenuButton<String>(
            tooltip: 'Akun',
            onSelected: (selectedValue) {
              if (selectedValue == 'profil') {
                onGo('profil');
              } else if (selectedValue == 'ulasan') {
                onGo('ulasan');
              } else {
                confirmLogout(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profil',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Profil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ulasan',
                child: Row(
                  children: [
                    const Icon(Icons.rate_review_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      (user.role == UserRole.siswa || user.role == UserRole.guru)
                          ? 'Kritik & Saran'
                          : 'Rekap Ulasan',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Keluar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showName && MediaQuery.of(context).size.width >= 760) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
