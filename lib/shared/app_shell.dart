import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/entries/presentation/entry_form_dialog.dart';

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
  _Dest('/calendar', 'Calendar', Icons.calendar_month_outlined),
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
        onPressed: () => showEntryForm(context),
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
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/insights')) return 3;
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Brand on the left, actions on the right.
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Food Journal',
                              style: TextStyle(
                                fontFamily: theme.headingFont,
                                fontSize: 22,
                                color: theme.ink,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Settings',
                          icon: Icon(
                            Icons.palette_outlined,
                            color: theme.inkMuted,
                          ),
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
                    // Tabs centered in the full bar width.
                    if (wide)
                      _SlidingTabBar(
                        theme: theme,
                        destinations: _destinations,
                        activeIndex: _activeIndex(),
                        onTap: (path) => context.go(path),
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

  int _activeIndex() {
    for (var i = 0; i < _destinations.length; i++) {
      if (_isActive(_destinations[i].path)) return i;
    }
    return 0;
  }
}

/// Centered nav tabs with an underline that slides to the active tab.
class _SlidingTabBar extends StatefulWidget {
  const _SlidingTabBar({
    required this.theme,
    required this.destinations,
    required this.activeIndex,
    required this.onTap,
  });

  final AppTheme theme;
  final List<_Dest> destinations;
  final int activeIndex;
  final void Function(String path) onTap;

  @override
  State<_SlidingTabBar> createState() => _SlidingTabBarState();
}

class _SlidingTabBarState extends State<_SlidingTabBar> {
  final _stackKey = GlobalKey();
  late List<GlobalKey> _labelKeys;
  double? _left;
  double? _width;
  double? _top;

  @override
  void initState() {
    super.initState();
    _labelKeys = List.generate(widget.destinations.length, (_) => GlobalKey());
  }

  void _measure() {
    if (!mounted) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    // Measure the label text itself, so the underline matches the word width.
    final labelBox =
        _labelKeys[widget.activeIndex].currentContext?.findRenderObject()
            as RenderBox?;
    if (stackBox == null || labelBox == null) return;
    final origin = labelBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final left = origin.dx;
    final width = labelBox.size.width;
    final top = origin.dy + labelBox.size.height + 4; // 4px under the word
    if (_left != left || _width != width || _top != top) {
      setState(() {
        _left = left;
        _width = width;
        _top = top;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure after layout each build (handles the active tab changing and
    // window resizes); the guard in _measure prevents a setState loop.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final t = widget.theme;
    return Stack(
      key: _stackKey,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.destinations.length; i++)
              _Tab(
                labelKey: _labelKeys[i],
                theme: t,
                label: widget.destinations[i].label,
                active: i == widget.activeIndex,
                onTap: () => widget.onTap(widget.destinations[i].path),
              ),
          ],
        ),
        if (_left != null && _width != null && _top != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            left: _left,
            width: _width,
            top: _top,
            height: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.labelKey,
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Key labelKey;
  final AppTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: theme.bodyFont,
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? theme.ink : theme.inkMuted,
          ),
          child: Text(label, key: labelKey),
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
