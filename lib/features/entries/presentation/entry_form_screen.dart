import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/made_bought_toggle.dart';
import '../../../shared/rating_control.dart';
import '../application/entries_controller.dart';
import '../data/food_category.dart';
import '../data/food_entry.dart';
import '../data/photo_picker.dart';

/// Screen for creating a new journal entry (F2).
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key});

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _recipe = TextEditingController();
  final _location = TextEditingController();

  int? _rating;
  FoodCategory _category = FoodCategory.breakfast;
  bool _homemade = true;
  DateTime _eatenAt = DateTime.now();
  Uint8List? _photoBytes;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _recipe.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final bytes = await ref.read(photoPickerProvider).pick(source);
    if (bytes != null) setState(() => _photoBytes = bytes);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eatenAt),
    );
    if (!mounted) return;
    setState(() {
      _eatenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _eatenAt.hour,
        time?.minute ?? _eatenAt.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_rating == null) {
      setState(() => _error = 'Give it a rating from 1 to 10.');
      return;
    }
    setState(() => _saving = true);
    try {
      final draft = FoodEntry(
        name: _name.text.trim(),
        rating: _rating!,
        category: _category,
        isHomemade: _homemade,
        notes: _notes.text,
        recipe: _recipe.text,
        location: _location.text,
        eatenAt: _eatenAt,
      );
      await ref
          .read(entriesControllerProvider.notifier)
          .add(draft, photoBytes: _photoBytes);
      if (mounted) context.go('/');
    } catch (_) {
      setState(() => _error = 'Could not save. Check your connection.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: const Text('New entry'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PhotoField(bytes: _photoBytes, onPick: _pickPhoto),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What is it?',
                    hintText: 'Miso ramen',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
                ),
                const SizedBox(height: 22),
                _label(text, 'Rating'),
                RatingControl(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 22),
                _label(text, 'Category'),
                _CategoryPicker(
                  selected: _category,
                  onChanged: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 22),
                _label(text, 'Made or bought'),
                MadeBoughtToggle(
                  isHomemade: _homemade,
                  onChanged: (v) => setState(() => _homemade = v),
                ),
                const SizedBox(height: 22),
                _label(text, 'When'),
                _DateTimeField(value: _eatenAt, onTap: _pickDateTime),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Home, or where you got it',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipe,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients / recipe',
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: theme.tagInk)),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save entry'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(TextTheme text, String s) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(s, style: text.titleLarge),
  );
}

class _PhotoField extends ConsumerWidget {
  const _PhotoField({required this.bytes, required this.onPick});

  final Uint8List? bytes;
  final void Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Material(
        color: theme.tagBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showSourceSheet(context),
          child: bytes == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 32,
                      color: theme.tagInk,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a photo (optional)',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        color: theme.tagInk,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({required this.selected, required this.onChanged});

  final FoodCategory selected;
  final ValueChanged<FoodCategory> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in FoodCategory.values)
          _chip(theme, c, c == selected, () => onChanged(c)),
      ],
    );
  }

  Widget _chip(AppTheme theme, FoodCategory c, bool sel, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? theme.primary : theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? theme.primary : theme.inkMuted.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.icon, size: 15, color: sel ? Colors.white : theme.inkMuted),
            const SizedBox(width: 6),
            Text(
              c.label,
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white : theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends ConsumerWidget {
  const _DateTimeField({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.inkMuted.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 18, color: theme.inkMuted),
            const SizedBox(width: 10),
            Text(
              _format(value),
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 15,
                color: theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}  $h:$m $ampm';
  }
}
