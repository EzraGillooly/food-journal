import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // The anon key is Supabase's publishable (public-safe) key.
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const ProviderScope(child: FoodJournalApp()));
}
