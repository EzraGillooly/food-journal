import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/entries_repository.dart';
import '../data/food_entry.dart';

/// Loads and holds the current user's entries. Also the write path for
/// creating new entries so the list stays in sync after a save.
class EntriesController extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() {
    // Rebind to the current user: when auth changes (login/logout/switch), this
    // rebuilds and re-queries so one account never shows another's cached data.
    final session = ref.watch(sessionProvider);
    if (session == null) return Future.value(const []);
    return ref.watch(entriesRepositoryProvider).list();
  }

  /// Creates an entry (uploading [photoBytes] if given) and prepends it.
  Future<FoodEntry> add(FoodEntry draft, {Uint8List? photoBytes}) async {
    final repo = ref.read(entriesRepositoryProvider);
    final saved = await repo.create(draft, photoBytes: photoBytes);
    final current = state.value ?? const <FoodEntry>[];
    state = AsyncData([saved, ...current]);
    return saved;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(entriesRepositoryProvider).list(),
    );
  }
}

final entriesControllerProvider =
    AsyncNotifierProvider<EntriesController, List<FoodEntry>>(
      EntriesController.new,
    );
