import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import 'theme_creator.dart';

/// Opens settings (theme picker) as a centered popup.
Future<void> showSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const _SettingsDialog(),
    ),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(themeControllerProvider);
    final theme = active;
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 480, maxHeight: size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: theme.headingFont,
                    fontSize: 20,
                    color: theme.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.inkMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Text('Theme', style: text.titleLarge),
                const SizedBox(height: 4),
                Text('Pick the look of your journal.', style: text.bodySmall),
                const SizedBox(height: 16),
                for (final t in AppTheme.all)
                  _ThemeOption(
                    theme: t,
                    selected: t.preset == active.preset,
                    onTap: () => ref
                        .read(themeControllerProvider.notifier)
                        .select(t.preset),
                  ),
                if (ref.read(themeControllerProvider.notifier).customTheme
                    case final custom?)
                  _ThemeOption(
                    theme: custom,
                    selected: active.preset == AppThemePreset.custom,
                    onTap: () => ref
                        .read(themeControllerProvider.notifier)
                        .select(AppThemePreset.custom),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => showThemeCreator(context),
                  icon: Icon(
                    ref.read(themeControllerProvider.notifier).customTheme ==
                            null
                        ? Icons.add
                        : Icons.edit_outlined,
                  ),
                  label: Text(
                    ref.read(themeControllerProvider.notifier).customTheme ==
                            null
                        ? 'Create a custom theme'
                        : 'Edit custom theme',
                  ),
                ),
              ],
            ),
          ),
        ],
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
