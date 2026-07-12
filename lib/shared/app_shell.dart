import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/application/auth_providers.dart';

/// Width at or above which the app uses a desktop website layout (top nav);
/// below it, a phone layout (top bar + bottom navigation).
const kWideBreakpoint = 760.0;

/// Max content width for the "website" feel.
const kContentMaxWidth = 1080.0;

class _Dest {
  const _Dest(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const _destinations = [
  _Dest('/', 'Home', Icons.home_outlined),
  _Dest('/journal', 'Journal', Icons.menu_book_outlined),
  _Dest('/insights', 'Insights', Icons.insights_outlined),
];

/// Persistent navigation frame around the primary pages (Home, Journal,
/// Insights). Detail/form/settings are pushed full-screen outside this shell.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final wide = MediaQuery.sizeOf(context).width >= kWideBreakpoint;
    final currentIndex = _indexFor(location);

    return Scaffold(
      appBar: _TopBar(theme: theme, wide: wide, location: location),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new'),
        backgroundColor: theme.primary,
        foregroundColor: theme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              backgroundColor: theme.surface,
              indicatorColor: theme.tagBg,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
      // Opaque, full-size background so route changes fully repaint (CanvasKit
      // otherwise leaves the previous page's pixels showing through). The keyed
      // RepaintBoundary forces a clean layer per route.
      body: RepaintBoundary(
        child: SizedBox.expand(
          child: ColoredBox(
            color: theme.background,
            child: KeyedSubtree(key: ValueKey(location), child: child),
          ),
        ),
      ),
    );
  }

  int _indexFor(String location) {
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/insights')) return 2;
    if (location == '/') return 0;
    return -1;
  }
}

class _TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopBar({
    required this.theme,
    required this.wide,
    required this.location,
  });

  final AppTheme theme;
  final bool wide;
  final String location;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.inkMuted.withValues(alpha: 0.18)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 59,
                child: Row(
                  children: [
                    Text(
                      'Food Journal',
                      style: TextStyle(
                        fontFamily: theme.headingFont,
                        fontSize: 22,
                        color: theme.ink,
                      ),
                    ),
                    if (wide) ...[
                      const SizedBox(width: 36),
                      for (final d in _destinations)
                        _NavLink(
                          theme: theme,
                          label: d.label,
                          active: _isActive(d.path),
                          onTap: () => context.go(d.path),
                        ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: 'Settings',
                      icon: Icon(Icons.palette_outlined, color: theme.inkMuted),
                      onPressed: () => context.go('/settings'),
                    ),
                    IconButton(
                      tooltip: 'Log out',
                      icon: Icon(Icons.logout, color: theme.inkMuted),
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
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

  bool _isActive(String path) {
    if (path == '/') return location == '/';
    return location.startsWith(path);
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final AppTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
          child: Container(
            padding: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? theme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? theme.ink : theme.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A page-body wrapper that centers content and caps its width, so pages inside
/// the shell read as a website rather than a phone column.
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 120),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
