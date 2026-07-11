/// Supabase connection config, supplied at build time via --dart-define.
///
/// The anon key is public-safe (it is shipped in the compiled web bundle by
/// design); it is still passed as a define rather than hardcoded so the value
/// lives in build config / CI variables, not in committed source.
///
/// Local dev:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
