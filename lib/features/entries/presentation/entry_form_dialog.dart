import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/made_bought_toggle.dart';
import '../../../shared/rating_control.dart';
import '../../../shared/selectable_chip.dart';
import '../application/entries_controller.dart';
import '../data/dish.dart';
import '../data/food_category.dart';
import '../data/food_entry.dart';
import '../data/entries_repository.dart';
import '../data/photo_cropper.dart';
import '../data/photo_picker.dart';
import 'widgets/entry_card.dart';
import 'widgets/entry_photo.dart';
import 'widgets/framed_image.dart';

/// Opens the add/edit entry form as a centered popup.
Future<void> showEntryForm(BuildContext context, {FoodEntry? existing}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _EntryForm(existing: existing),
    ),
  );
}

/// Mutable draft of a single dish (its own controllers + rating).
class _DishDraft {
  _DishDraft({
    String name = '',
    this.rating,
    int? calories,
    String notes = '',
    String recipe = '',
  }) : name = TextEditingController(text: name),
       calories = TextEditingController(text: calories?.toString() ?? ''),
       notes = TextEditingController(text: notes),
       recipe = TextEditingController(text: recipe);

  final TextEditingController name;
  int? rating;
  final TextEditingController calories;
  final TextEditingController notes;
  final TextEditingController recipe;

  void dispose() {
    name.dispose();
    calories.dispose();
    notes.dispose();
    recipe.dispose();
  }
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.existing});
  final FoodEntry? existing;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  final _location = TextEditingController();
  final _dishes = <_DishDraft>[];
  int _activeDish = 0;

  FoodCategory _category = FoodCategory.breakfast;
  bool _homemade = true;
  DateTime _eatenAt = DateTime.now();
  Uint8List? _photoBytes;

  // How the photo is framed in the card thumbnails.
  double _focusX = 0;
  double _focusY = 0;
  double _zoom = 1;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _location.text = e.location ?? '';
      _category = e.category;
      _homemade = e.isHomemade;
      _eatenAt = e.eatenAt.toLocal();
      _focusX = e.photoFocusX;
      _focusY = e.photoFocusY;
      _zoom = e.photoZoom;
      for (final d in e.dishes) {
        _dishes.add(
          _DishDraft(
            name: d.name,
            rating: d.rating,
            calories: d.calories,
            notes: d.notes ?? '',
            recipe: d.recipe ?? '',
          ),
        );
      }
    } else {
      _dishes.add(_DishDraft());
    }
  }

  @override
  void dispose() {
    _location.dispose();
    for (final d in _dishes) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDish() {
    setState(() {
      _dishes.add(_DishDraft());
      _activeDish = _dishes.length - 1;
    });
  }

  void _removeDish(int i) {
    if (_dishes.length <= 1) return;
    setState(() {
      _dishes.removeAt(i).dispose();
      if (_activeDish >= _dishes.length) _activeDish = _dishes.length - 1;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ref.read(photoPickerProvider).pick(source);
    if (file == null || !mounted) return;
    final bytes = await cropPhotoToCard(context, file.path);
    if (bytes != null && mounted) {
      // A fresh image starts centered/unzoomed - old framing wouldn't fit it.
      setState(() {
        _photoBytes = bytes;
        _focusX = 0;
        _focusY = 0;
        _zoom = 1;
      });
    }
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

  List<Dish>? _collectDishes() {
    final result = <Dish>[];
    for (var i = 0; i < _dishes.length; i++) {
      final d = _dishes[i];
      if (d.name.text.trim().isEmpty) {
        setState(() {
          _activeDish = i;
          _error = 'Give dish ${i + 1} a name.';
        });
        return null;
      }
      if (d.rating == null) {
        setState(() {
          _activeDish = i;
          _error = 'Rate dish ${i + 1} with the stars.';
        });
        return null;
      }
      result.add(
        Dish(
          name: d.name.text.trim(),
          rating: d.rating!,
          calories: int.tryParse(d.calories.text.trim()),
          notes: d.notes.text,
          recipe: d.recipe.text,
        ),
      );
    }
    return result;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final dishes = _collectDishes();
    if (dishes == null) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(entriesControllerProvider.notifier);
      final existing = widget.existing;
      if (existing != null) {
        await notifier.edit(
          FoodEntry(
            id: existing.id,
            userId: existing.userId,
            dishes: dishes,
            category: _category,
            isHomemade: _homemade,
            location: _location.text,
            photoPath: existing.photoPath,
            photoFocusX: _focusX,
            photoFocusY: _focusY,
            photoZoom: _zoom,
            eatenAt: _eatenAt,
            createdAt: existing.createdAt,
          ),
          newPhotoBytes: _photoBytes,
        );
      } else {
        await notifier.add(
          FoodEntry(
            dishes: dishes,
            category: _category,
            isHomemade: _homemade,
            location: _location.text,
            photoFocusX: _focusX,
            photoFocusY: _focusY,
            photoZoom: _zoom,
            eatenAt: _eatenAt,
          ),
          photoBytes: _photoBytes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = 'Could not save. Check your connection.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 720;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 760, maxHeight: size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(theme),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _sharedColumn(theme)),
                        const SizedBox(width: 22),
                        Expanded(flex: 6, child: _dishColumn(theme)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sharedColumn(theme),
                        const SizedBox(height: 18),
                        _dishColumn(theme),
                      ],
                    ),
            ),
          ),
          _footer(theme),
        ],
      ),
    );
  }

  Widget _header(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.inkMuted.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _isEditing ? 'Edit entry' : 'New entry',
            style: TextStyle(
              fontFamily: theme.headingFont,
              fontSize: 22,
              color: theme.ink,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: theme.inkMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Left column: preview, photo, and the entry-wide fields.
  Widget _sharedColumn(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, 'Preview'),
        const SizedBox(height: 8),
        _Preview(
          dishes: _dishes,
          category: _category,
          isHomemade: _homemade,
          eatenAt: _eatenAt,
          photoBytes: _photoBytes,
          existingPhotoPath: widget.existing?.photoPath,
          focusX: _focusX,
          focusY: _focusY,
          zoom: _zoom,
        ),
        const SizedBox(height: 16),
        _PhotoField(
          bytes: _photoBytes,
          existingPhotoPath: widget.existing?.photoPath,
          onPick: _pickPhoto,
        ),
        if (_photoBytes != null || widget.existing?.photoPath != null) ...[
          const SizedBox(height: 16),
          _label(theme, 'Card framing'),
          const SizedBox(height: 8),
          _FramingField(
            bytes: _photoBytes,
            existingPhotoPath: widget.existing?.photoPath,
            focusX: _focusX,
            focusY: _focusY,
            zoom: _zoom,
            onChanged: (fx, fy, z) => setState(() {
              _focusX = fx;
              _focusY = fy;
              _zoom = z;
            }),
          ),
        ],
        const SizedBox(height: 16),
        _label(theme, 'Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in FoodCategory.values)
              SelectableChip(
                label: c.label,
                icon: c.icon,
                selected: c == _category,
                onTap: () => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label(theme, 'Made or bought'),
        const SizedBox(height: 8),
        MadeBoughtToggle(
          isHomemade: _homemade,
          onChanged: (v) => setState(() => _homemade = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateTimeField(value: _eatenAt, onTap: _pickDateTime),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Home, or where you got it',
            isDense: true,
          ),
        ),
      ],
    );
  }

  // Right column: the dish selector and the active dish's fields.
  Widget _dishColumn(AppTheme theme) {
    final active = _dishes[_activeDish];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label(theme, 'Dishes'),
            const Spacer(),
            TextButton.icon(
              onPressed: _addDish,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add dish'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_dishes.length > 1)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _dishes.length; i++)
                _DishChip(
                  theme: theme,
                  label: _dishes[i].name.text.trim().isEmpty
                      ? 'Dish ${i + 1}'
                      : _dishes[i].name.text.trim(),
                  selected: i == _activeDish,
                  onTap: () => setState(() => _activeDish = i),
                  onRemove: () => _removeDish(i),
                ),
            ],
          ),
        const SizedBox(height: 12),
        TextField(
          controller: active.name,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'What is it?',
            hintText: 'Miso ramen',
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        // Rating + calories sit side by side when there's room, but the 5-star
        // control has a fixed minimum width, so on a narrow (phone) column they
        // stack instead of overflowing.
        LayoutBuilder(
          builder: (context, c) {
            final rating = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(theme, 'Rating'),
                const SizedBox(height: 4),
                RatingControl(
                  value: active.rating,
                  onChanged: (v) => setState(() => active.rating = v),
                ),
              ],
            );
            final calories = TextField(
              controller: active.calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories',
                suffixText: 'kcal',
                isDense: true,
              ),
            );
            if (c.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  rating,
                  const SizedBox(height: 14),
                  calories,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: rating),
                const SizedBox(width: 12),
                SizedBox(width: 110, child: calories),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _BulletBar(theme: theme, controller: active.notes),
        TextField(
          controller: active.notes,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notes', isDense: true),
        ),
        const SizedBox(height: 12),
        _BulletBar(theme: theme, controller: active.recipe),
        TextField(
          controller: active.recipe,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Ingredients / recipe',
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _footer(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.inkMuted.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          if (_error != null)
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: theme.tagInk, fontSize: 13),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
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
                : Text(_isEditing ? 'Save changes' : 'Save entry'),
          ),
        ],
      ),
    );
  }

  Widget _label(AppTheme theme, String s) => Text(
    s.toUpperCase(),
    style: TextStyle(
      fontFamily: theme.bodyFont,
      fontSize: 11,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
      color: theme.inkMuted,
    ),
  );
}

class _DishChip extends StatelessWidget {
  const _DishChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final AppTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.primary
                : theme.inkMuted.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? theme.onPrimary : theme.ink,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 15,
                color: selected ? theme.onPrimary : theme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({
    required this.dishes,
    required this.category,
    required this.isHomemade,
    required this.eatenAt,
    required this.photoBytes,
    required this.existingPhotoPath,
    required this.focusX,
    required this.focusY,
    required this.zoom,
  });

  final List<_DishDraft> dishes;
  final FoodCategory category;
  final bool isHomemade;
  final DateTime eatenAt;
  final Uint8List? photoBytes;
  final String? existingPhotoPath;
  final double focusX;
  final double focusY;
  final double zoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([for (final d in dishes) d.name]),
      builder: (context, _) {
        final dishList = [
          for (final d in dishes)
            Dish(
              name: d.name.text.trim().isEmpty
                  ? 'Your dish'
                  : d.name.text.trim(),
              rating: d.rating ?? 0,
            ),
        ];
        final entry = FoodEntry(
          dishes: dishList,
          category: category,
          isHomemade: isHomemade,
          // With a freshly picked image the card renders from the override
          // below; otherwise it loads the existing photo with this framing.
          photoPath: photoBytes == null ? existingPhotoPath : null,
          photoFocusX: focusX,
          photoFocusY: focusY,
          photoZoom: zoom,
          eatenAt: eatenAt,
        );
        return IgnorePointer(
          child: EntryCard(
            entry: entry,
            photoOverride: photoBytes != null
                ? FramedImage(
                    provider: MemoryImage(photoBytes!),
                    focusX: focusX,
                    focusY: focusY,
                    zoom: zoom,
                    background: theme.tagBg,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Interactive framing control: drag the photo to reposition and use the slider
/// to zoom. Reports changes back so the card preview updates live.
class _FramingField extends ConsumerWidget {
  const _FramingField({
    required this.bytes,
    required this.existingPhotoPath,
    required this.focusX,
    required this.focusY,
    required this.zoom,
    required this.onChanged,
  });

  final Uint8List? bytes;
  final String? existingPhotoPath;
  final double focusX;
  final double focusY;
  final double zoom;
  final void Function(double focusX, double focusY, double zoom) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    ImageProvider? provider;
    if (bytes != null) {
      provider = MemoryImage(bytes!);
    } else if (existingPhotoPath != null) {
      provider = ref
          .watch(photoUrlProvider(existingPhotoPath!))
          .whenOrNull(data: (url) => NetworkImage(url));
    }

    if (provider == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.tagBg,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: LayoutBuilder(
              builder: (context, c) {
                return GestureDetector(
                  onPanUpdate: (d) {
                    final nx = (focusX - d.delta.dx * 2 / c.maxWidth).clamp(
                      -1.0,
                      1.0,
                    );
                    final ny = (focusY - d.delta.dy * 2 / c.maxHeight).clamp(
                      -1.0,
                      1.0,
                    );
                    onChanged(nx, ny, zoom);
                  },
                  child: FramedImage(
                    provider: provider!,
                    focusX: focusX,
                    focusY: focusY,
                    zoom: zoom,
                    background: theme.tagBg,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.zoom_out, size: 18, color: theme.inkMuted),
            Expanded(
              child: Slider(
                value: zoom.clamp(0.5, 3),
                min: 0.5,
                max: 3,
                onChanged: (v) => onChanged(focusX, focusY, v),
              ),
            ),
            Icon(Icons.zoom_in, size: 18, color: theme.inkMuted),
          ],
        ),
        Row(
          children: [
            Icon(Icons.open_with, size: 13, color: theme.inkMuted),
            const SizedBox(width: 6),
            Text(
              'Drag the photo to reposition',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 12,
                color: theme.inkMuted,
              ),
            ),
            const Spacer(),
            if (focusX != 0 || focusY != 0 || zoom != 1)
              TextButton(
                onPressed: () => onChanged(0, 0, 1),
                child: const Text('Reset'),
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoField extends ConsumerWidget {
  const _PhotoField({
    required this.bytes,
    required this.onPick,
    this.existingPhotoPath,
  });

  final Uint8List? bytes;
  final String? existingPhotoPath;
  final void Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final hasImage = bytes != null || existingPhotoPath != null;
    return SizedBox(
      height: 120,
      child: Material(
        color: theme.tagBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showSourceSheet(context),
          child: !hasImage
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 28,
                      color: theme.tagInk,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add a photo (optional)',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        color: theme.tagInk,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bytes != null)
                      Image.memory(bytes!, fit: BoxFit.cover)
                    else
                      EntryPhoto(photoPath: existingPhotoPath),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crop, size: 13, color: Colors.white),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.inkMuted.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 17, color: theme.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatEntryDateTime(value),
                style: TextStyle(
                  fontFamily: theme.bodyFont,
                  fontSize: 14,
                  color: theme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small toolbar of bullet styles. Tapping one inserts that bullet at the
/// start of the current line in [controller], so users can make lists in the
/// notes / ingredients fields if they want.
class _BulletBar extends StatelessWidget {
  const _BulletBar({required this.theme, required this.controller});

  final AppTheme theme;
  final TextEditingController controller;

  static const _bullets = ['•', '◦', '–', '▸', '★', '✓'];

  void _insert(String bullet) {
    final text = controller.text;
    final sel = controller.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final before = text.substring(0, pos);
    final atLineStart = before.isEmpty || before.endsWith('\n');
    final insert = atLineStart ? '$bullet ' : '\n$bullet ';
    controller.value = TextEditingValue(
      text: before + insert + text.substring(pos),
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            'Bullets',
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 10.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
          const SizedBox(width: 8),
          for (final b in _bullets)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => _insert(b),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.inkMuted.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    b,
                    style: TextStyle(fontSize: 14, color: theme.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
