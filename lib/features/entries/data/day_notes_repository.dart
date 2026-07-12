import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';

String _dateKey(DateTime d) {
  final l = DateTime(d.year, d.month, d.day);
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

DateTime dayKey(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Per-day notes ("how the day's eating went"). RLS scopes rows to the user.
class DayNotesRepository {
  DayNotesRepository(this._client);
  final SupabaseClient _client;

  Future<Map<DateTime, String>> all() async {
    final rows = await _client.from('day_notes').select('entry_date, note');
    return {
      for (final r in rows)
        DateTime.parse(r['entry_date'] as String): r['note'] as String,
    };
  }

  Future<void> upsert(DateTime date, String note) async {
    await _client.from('day_notes').upsert({
      'entry_date': _dateKey(date),
      'note': note,
      'updated_at': 'now()',
    }, onConflict: 'user_id,entry_date');
  }

  Future<void> remove(DateTime date) async {
    await _client.from('day_notes').delete().eq('entry_date', _dateKey(date));
  }
}

final dayNotesRepositoryProvider = Provider<DayNotesRepository>((ref) {
  return DayNotesRepository(ref.watch(supabaseClientProvider));
});

/// Loads and holds all of the user's day notes, keyed by local date.
class DayNotesController extends AsyncNotifier<Map<DateTime, String>> {
  @override
  Future<Map<DateTime, String>> build() {
    final userId = ref.watch(sessionProvider.select((s) => s?.user.id));
    if (userId == null) return Future.value({});
    return ref.watch(dayNotesRepositoryProvider).all();
  }

  Future<void> setNote(DateTime date, String note) async {
    final key = dayKey(date);
    final trimmed = note.trim();
    final repo = ref.read(dayNotesRepositoryProvider);
    final current = Map<DateTime, String>.of(state.value ?? {});
    if (trimmed.isEmpty) {
      await repo.remove(key);
      current.remove(key);
    } else {
      await repo.upsert(key, trimmed);
      current[key] = trimmed;
    }
    state = AsyncData(current);
  }
}

final dayNotesControllerProvider =
    AsyncNotifierProvider<DayNotesController, Map<DateTime, String>>(
      DayNotesController.new,
    );
