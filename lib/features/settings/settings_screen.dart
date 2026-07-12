import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

/// Settings (F7): switch between the saved themes. The choice persists.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Theme', style: text.titleLarge),
              const SizedBox(height: 4),
              Text('Pick the look of your journal.', style: text.bodySmall),
              const SizedBox(height: 16),
              for (final theme in AppTheme.all)
                _ThemeOption(
                  theme: theme,
                  selected: theme.preset == active.preset,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .select(theme.preset),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.primary
                  : theme.inkMuted.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _Swatches(theme: theme),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  theme.label,
                  style: TextStyle(
                    fontFamily: theme.headingFont,
                    fontSize: 18,
                    color: theme.ink,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? theme.primary : theme.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final colors = [theme.primary, theme.secondary, theme.ink];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in colors)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
      ],
    );
  }
}
