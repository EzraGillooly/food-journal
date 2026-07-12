import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

/// Opens the custom theme creator popup.
Future<void> showThemeCreator(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const _ThemeCreator(),
    ),
  );
}

/// The colour tokens the user can set, with a label and what each affects.
const _tokens = <(String, String, String)>[
  ('background', 'Background', 'The page behind everything'),
  ('surface', 'Cards', 'Cards, the nav bar, sheets'),
  ('primary', 'Accent', 'Buttons, stars, highlights'),
  ('secondary', 'Secondary', 'Secondary accents'),
  ('ink', 'Text', 'Headings and body text'),
  ('inkMuted', 'Muted text', 'Times, captions'),
  ('tagBg', 'Tag background', 'Category pill background'),
  ('tagInk', 'Tag text', 'Category pill text'),
];

class _ThemeCreator extends ConsumerStatefulWidget {
  const _ThemeCreator();

  @override
  ConsumerState<_ThemeCreator> createState() => _ThemeCreatorState();
}

class _ThemeCreatorState extends ConsumerState<_ThemeCreator> {
  late Map<String, Color> _colors;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(themeControllerProvider.notifier).customTheme;
    _colors = Map.of((existing ?? AppTheme.customSeed).colors);
  }

  AppTheme get _preview => AppTheme.custom(_colors);

  Future<void> _pick(String key) async {
    var temp = _colors[key]!;
    final chosen = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _colors[key]!,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            hexInputBar: true,
            displayThumbColor: true,
            portraitOnly: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, temp),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (chosen != null) setState(() => _colors[key] = chosen);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(themeControllerProvider.notifier).saveCustom(_preview);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 860, maxHeight: size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Text(
                  'Custom theme',
                  style: TextStyle(
                    fontFamily: theme.headingFont,
                    fontSize: 22,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _ThemePreview(theme: _preview),
                        ),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: _pickers()),
                      ],
                    )
                  : Column(
                      children: [
                        _ThemePreview(theme: _preview),
                        const SizedBox(height: 20),
                        _pickers(),
                      ],
                    ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.inkMuted.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(
                    () => _colors = Map.of(AppTheme.customSeed.colors),
                  ),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save & apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickers() {
    final labelColor = ref.watch(themeControllerProvider).inkMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in _tokens)
          _SwatchRow(
            color: _colors[t.$1]!,
            label: t.$2,
            description: t.$3,
            labelColor: labelColor,
            onTap: () => _pick(t.$1),
          ),
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.color,
    required this.label,
    required this.description,
    required this.labelColor,
    required this.onTap,
  });

  final Color color;
  final String label;
  final String description;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12.5,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 12,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small live preview of the app rendered from [theme] so the user sees what
/// each colour affects.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nav bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  'Food Journal',
                  style: TextStyle(
                    fontFamily: theme.headingFont,
                    fontSize: 16,
                    color: theme.ink,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(height: 2, width: 30, color: theme.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sample entry card
          Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 74,
                  height: 96,
                  color: theme.tagBg,
                  child: Icon(Icons.restaurant, color: theme.tagInk, size: 22),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Blueberry pancakes',
                          style: TextStyle(
                            fontFamily: theme.headingFont,
                            fontSize: 16,
                            color: theme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: i < 4
                                    ? theme.primary
                                    : theme.primary.withValues(alpha: 0.35),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.tagBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Breakfast',
                                style: TextStyle(
                                  fontFamily: theme.bodyFont,
                                  fontSize: 10.5,
                                  color: theme.tagInk,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Made it',
                              style: TextStyle(
                                fontFamily: theme.bodyFont,
                                fontSize: 11,
                                color: theme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Secondary accent + primary button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border(
                    left: BorderSide(color: theme.secondary, width: 3),
                  ),
                ),
                child: Text(
                  'Recipe',
                  style: TextStyle(
                    fontFamily: theme.bodyFont,
                    fontSize: 12,
                    color: theme.ink,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: theme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Add entry',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
