import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'food_entry.dart';

const _photoBucket = 'entry-photos';
const _uuid = Uuid();

/// Data access for food entries. All queries run as the signed-in user, so
/// Supabase RLS scopes every read/write to their own rows automatically.
class EntriesRepository {
  EntriesRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Cannot access entries while signed out.');
    }
    return id;
  }

  /// Fetches the current user's entries, newest eaten first.
  Future<List<FoodEntry>> list() async {
    final rows = await _client
        .from('food_entries')
        .select()
        .order('eaten_at', ascending: false);
    return rows.map(FoodEntry.fromMap).toList();
  }

  /// Uploads a photo for [entryId] and returns its storage path.
  Future<String> uploadPhoto({
    required String entryId,
    required Uint8List bytes,
  }) async {
    final path = '$_userId/$entryId.jpg';
    await _client.storage
        .from(_photoBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  /// Signed URL for displaying a stored photo (bucket is private).
  Future<String> photoUrl(String path, {int expiresIn = 3600}) {
    return _client.storage.from(_photoBucket).createSignedUrl(path, expiresIn);
  }

  /// Inserts [draft], then uploads [photoBytes] if given. The row is written
  /// first so a failed insert never orphans an uploaded photo; if the upload
  /// then fails, the entry simply has no photo (recoverable via edit).
  Future<FoodEntry> create(FoodEntry draft, {Uint8List? photoBytes}) async {
    final id = _uuid.v4();
    final row = await _client
        .from('food_entries')
        .insert({'id': id, ...draft.toInsert()})
        .select()
        .single();
    var saved = FoodEntry.fromMap(row);

    if (photoBytes != null) {
      final path = await uploadPhoto(entryId: id, bytes: photoBytes);
      saved = await _setPhotoPath(id, path);
    }
    return saved;
  }

  /// Updates an existing entry. Writes the fields first, then (if a new photo is
  /// given) uploads it, so a failed field update never overwrites the existing
  /// photo the upsert would replace.
  Future<FoodEntry> update(FoodEntry entry, {Uint8List? newPhotoBytes}) async {
    final id = entry.id;
    if (id == null) throw ArgumentError('Cannot update an unsaved entry.');

    final row = await _client
        .from('food_entries')
        .update(entry.toInsert())
        .eq('id', id)
        .select()
        .single();
    var saved = FoodEntry.fromMap(row);

    if (newPhotoBytes != null) {
      final path = await uploadPhoto(entryId: id, bytes: newPhotoBytes);
      if (path != saved.photoPath) saved = await _setPhotoPath(id, path);
    }
    return saved;
  }

  Future<FoodEntry> _setPhotoPath(String id, String path) async {
    final row = await _client
        .from('food_entries')
        .update({'photo_path': path})
        .eq('id', id)
        .select()
        .single();
    return FoodEntry.fromMap(row);
  }

  /// Deletes an entry and its photo. Removes the row first so a failed delete
  /// never leaves a live row pointing at an already-deleted photo; a leftover
  /// storage object (if the row delete succeeds but removal fails) is only
  /// wasted space, not a broken reference.
  Future<void> delete(FoodEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    await _client.from('food_entries').delete().eq('id', id);
    if (entry.photoPath != null) {
      await _client.storage.from(_photoBucket).remove([entry.photoPath!]);
    }
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository(ref.watch(supabaseClientProvider));
});

/// Signed URL for a stored photo path, cached per path. Invalidate this for a
/// path after replacing that photo so viewers re-fetch a fresh URL.
final photoUrlProvider = FutureProvider.family<String, String>((ref, path) {
  return ref.watch(entriesRepositoryProvider).photoUrl(path);
});
