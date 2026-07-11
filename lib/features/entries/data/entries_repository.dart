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

  /// Inserts [draft], optionally uploading [photoBytes] first. Returns the
  /// saved entry (with DB-assigned fields).
  Future<FoodEntry> create(FoodEntry draft, {Uint8List? photoBytes}) async {
    final id = _uuid.v4();
    String? photoPath;
    if (photoBytes != null) {
      photoPath = await uploadPhoto(entryId: id, bytes: photoBytes);
    }

    final payload = {
      'id': id,
      ...draft.copyWith(photoPath: photoPath).toInsert(),
    };

    final row = await _client
        .from('food_entries')
        .insert(payload)
        .select()
        .single();
    return FoodEntry.fromMap(row);
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository(ref.watch(supabaseClientProvider));
});
