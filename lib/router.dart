import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/supabase/supabase_providers.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/entries/presentation/home_placeholder_screen.dart';

/// Turns a Stream into a Listenable so GoRouter re-evaluates redirects whenever
/// auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _authRoutes = {'/login', '/signup', '/forgot-password'};

/// App router. go_router uses the hash URL strategy by default on web, which is
/// what GitHub Pages needs so deep links survive a hard refresh (no 404).
///
/// Logged-out users are redirected to /login; logged-in users are kept out of
/// the auth routes. Isolation of actual data is enforced by Supabase RLS.
final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = _StreamListenable(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = client.auth.currentSession != null;
      final onAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (!signedIn && !onAuthRoute) return '/login';
      if (signedIn && onAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  );
});

/// Exposed for unit testing the redirect route set.
@visibleForTesting
bool isAuthRoute(String location) => _authRoutes.contains(location);
