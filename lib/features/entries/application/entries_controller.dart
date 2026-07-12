import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/entries_repository.dart';
import '../data/food_entry.dart';

/// Loads and holds the current user's entries. Also the write path for
/// creating/editing/deleting so the list stays in sync after a save.
class EntriesController extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() {
    // Rebind to the current user id only: this re-queries on login/logout/switch
    // (so one account never shows another's data) but NOT on hourly token
    // refreshes, which would otherwise flash the feed to a spinner.
    final userId = ref.watch(sessionProvider.select((s) => s?.user.id));
    if (userId == null) return Future.value(const []);
    return ref.watch(entriesRepositoryProvider).list();
  }

  /// Creates an entry (uploading [photoBytes] if given) and inserts it in order.
  Future<FoodEntry> add(FoodEntry draft, {Uint8List? photoBytes}) async {
    final saved = await ref
        .read(entriesRepositoryProvider)
        .create(draft, photoBytes: photoBytes);
    _mergeSorted((current) => [saved, ...current]);
    return saved;
  }

  /// Updates an entry (optionally replacing its photo) and syncs the list.
  Future<FoodEntry> edit(FoodEntry entry, {Uint8List? newPhotoBytes}) async {
    final saved = await ref
        .read(entriesRepositoryProvider)
        .update(entry, newPhotoBytes: newPhotoBytes);
    // Photo path is reused on replace, so drop the cached signed URL to force
    // viewers to fetch the new image.
    if (newPhotoBytes != null && saved.photoPath != null) {
      ref.invalidate(photoUrlProvider(saved.photoPath!));
    }
    _mergeSorted(
      (current) => [for (final e in current) e.id == saved.id ? saved : e],
    );
    return saved;
  }

  /// Deletes an entry (and its photo) and removes it from the list.
  Future<void> remove(FoodEntry entry) async {
    await ref.read(entriesRepositoryProvider).delete(entry);
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData([
      for (final e in current)
        if (e.id != entry.id) e,
    ]);
  }

  Future<void> refresh() async {
    // Keep showing the current list (the RefreshIndicator provides the spinner)
    // instead of tearing the feed down to a full-screen loader.
    state = await AsyncValue.guard(
      () => ref.read(entriesRepositoryProvider).list(),
    );
  }

  /// Applies [transform] to the current list and re-sorts newest-eaten-first.
  /// If the list never loaded (error/loading), triggers a fresh load instead of
  /// fabricating a partial list from nothing.
  void _mergeSorted(List<FoodEntry> Function(List<FoodEntry>) transform) {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    final next = transform(current)
      ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
    state = AsyncData(next);
  }
}

final entriesControllerProvider =
    AsyncNotifierProvider<EntriesController, List<FoodEntry>>(
      EntriesController.new,
    );
