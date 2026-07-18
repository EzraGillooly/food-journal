import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

/// Shared frame for the auth screens: centred card, brand mark, title, and a
/// consistent max width.
class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // LayoutBuilder + minHeight-constrained scroll view: the card is centered
      // when there's room and scrolls (never overflows) when the viewport is
      // short - e.g. a small phone or with the keyboard open.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: theme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: text.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Inline error banner shown above auth forms.
class AuthErrorBanner extends ConsumerWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.tagBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.tagInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 13,
                color: theme.tagInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
