import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/entries/presentation/home_placeholder_screen.dart';

/// App router. go_router uses the hash URL strategy by default on web, which is
/// what GitHub Pages needs so deep links survive a hard refresh (no 404).
///
/// Auth-based redirects are added in T2.1.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
  );
});
