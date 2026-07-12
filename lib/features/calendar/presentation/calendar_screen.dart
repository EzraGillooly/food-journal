import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_label.dart';
import '../../../shared/rating_stars.dart';
import '../../entries/application/entries_controller.dart';
import '../../entries/data/day_notes_repository.dart';
import '../../entries/data/food_entry.dart';
import '../../entries/presentation/entry_detail_screen.dart';
import '../../entries/presentation/widgets/entry_photo.dart';

enum CalendarView { day, week, month, year }

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _weekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

DateTime _d(DateTime dt) {
  final l = dt.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Calendar with Day / Week / Month / Year views, per-day counts, and a note
/// for each day.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  late DateTime _anchor; // reference date for the current view
  late DateTime _selected; // selected day (day/week/month views)

  @override
  void initState() {
    super.initState();
    _anchor = _d(DateTime.now());
    _selected = _anchor;
  }

  void _shift(int dir) {
    setState(() {
      switch (_view) {
        case CalendarView.day:
          _anchor = _anchor.add(Duration(days: dir));
          _selected = _anchor;
        case CalendarView.week:
          _anchor = _anchor.add(Duration(days: 7 * dir));
        case CalendarView.month:
          _anchor = DateTime(_anchor.year, _anchor.month + dir);
        case CalendarView.year:
          _anchor = DateTime(_anchor.year + dir, _anchor.month);
      }
    });
  }

  String get _title => switch (_view) {
    CalendarView.day =>
      '${_weekdayNames[_anchor.weekday % 7]}, ${_monthShort[_anchor.month - 1]} ${_anchor.day}',
    CalendarView.week => _weekTitle(),
    CalendarView.month => '${_monthNames[_anchor.month - 1]} ${_anchor.year}',
    CalendarView.year => '${_anchor.year}',
  };

  String _weekTitle() {
    final start = _anchor.subtract(Duration(days: _anchor.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${_monthShort[start.month - 1]} ${start.day} - '
        '${_monthShort[end.month - 1]} ${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final entriesAsync = ref.watch(entriesControllerProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load your journal")),
      data: (entries) {
        final byDay = <DateTime, List<FoodEntry>>{};
        for (final e in entries) {
          byDay.putIfAbsent(_d(e.eatenAt), () => []).add(e);
        }
        return ContentColumn(
          maxWidth: 820,
          // Bottom gap lives inside the scroll view (like the home page) so
          // content scrolls to the physical bottom rather than being clipped by
          // an outer pad, which reads as a footer blocking the last rows.
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ViewToggle(
                  theme: theme,
                  view: _view,
                  onChanged: (v) => setState(() => _view = v),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: TextStyle(
                          fontFamily: theme.headingFont,
                          fontSize: 24,
                          color: theme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shift(-1),
                      icon: Icon(Icons.chevron_left, color: theme.inkMuted),
                    ),
                    IconButton(
                      onPressed: () => _shift(1),
                      icon: Icon(Icons.chevron_right, color: theme.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._body(theme, byDay),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _body(AppTheme theme, Map<DateTime, List<FoodEntry>> byDay) {
    switch (_view) {
      case CalendarView.day:
        return [
          _DaySection(date: _anchor, entries: byDay[_anchor] ?? const []),
        ];
      case CalendarView.week:
        return [
          _WeekStrip(
            anchor: _anchor,
            selected: _selected,
            byDay: byDay,
            theme: theme,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 22),
          _DaySection(date: _selected, entries: byDay[_selected] ?? const []),
        ];
      case CalendarView.month:
        return [
          _MonthGrid(
            month: _anchor,
            selected: _selected,
            byDay: byDay,
            theme: theme,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 24),
          _DaySection(date: _selected, entries: byDay[_selected] ?? const []),
        ];
      case CalendarView.year:
        return [
          _YearGrid(
            year: _anchor.year,
            byDay: byDay,
            theme: theme,
            onSelectMonth: (m) => setState(() {
              _view = CalendarView.month;
              _anchor = DateTime(_anchor.year, m);
            }),
          ),
        ];
    }
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.theme,
    required this.view,
    required this.onChanged,
  });
  final AppTheme theme;
  final CalendarView view;
  final ValueChanged<CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          for (final v in CalendarView.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(v),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == view ? theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    switch (v) {
                      CalendarView.day => 'Day',
                      CalendarView.week => 'Week',
                      CalendarView.month => 'Month',
                      CalendarView.year => 'Year',
                    },
                    style: TextStyle(
                      fontFamily: theme.bodyFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: v == view ? theme.onPrimary : theme.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single calendar day cell shaded by entry count, with the count shown.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool isToday;
  final bool isSelected;
  final AppTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = count > 0;
    final fill = !has
        ? Colors.transparent
        : count >= 3
        ? theme.primary
        : count == 2
        ? theme.primary.withValues(alpha: 0.55)
        : theme.tagBg;
    final onFill = has && count >= 2 ? theme.onPrimary : theme.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.ink
                : isToday
                ? theme.primary
                : Colors.transparent,
            width: isSelected || isToday ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontFamily: theme.bodyFont,
                  fontSize: 13.5,
                  fontWeight: has ? FontWeight.w700 : FontWeight.w400,
                  color: has ? onFill : theme.inkMuted,
                ),
              ),
            ),
            if (has)
              Positioned(
                right: 3,
                top: 2,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: theme.bodyFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: onFill.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.theme,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, List<FoodEntry>> byDay;
  final AppTheme theme;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = _d(DateTime.now());
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final cells = <Widget>[
      for (final l in _weekdayLetters)
        Center(
          child: Text(
            l,
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          count: byDay[DateTime(month.year, month.month, day)]?.length ?? 0,
          isToday: DateTime(month.year, month.month, day) == today,
          isSelected: DateTime(month.year, month.month, day) == selected,
          theme: theme,
          onTap: () => onSelect(DateTime(month.year, month.month, day)),
        ),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      // Wider-than-tall cells keep the whole month compact so the day detail
      // below stays close to the fold instead of being pushed off-screen.
      childAspectRatio: 1.35,
      children: cells,
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.anchor,
    required this.selected,
    required this.byDay,
    required this.theme,
    required this.onSelect,
  });

  final DateTime anchor;
  final DateTime selected;
  final Map<DateTime, List<FoodEntry>> byDay;
  final AppTheme theme;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = _d(DateTime.now());
    final start = anchor.subtract(Duration(days: anchor.weekday % 7));
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Text(
                    _weekdayLetters[i],
                    style: TextStyle(
                      fontFamily: theme.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _DayCell(
                      date: start.add(Duration(days: i)),
                      count: byDay[start.add(Duration(days: i))]?.length ?? 0,
                      isToday: start.add(Duration(days: i)) == today,
                      isSelected: start.add(Duration(days: i)) == selected,
                      theme: theme,
                      onTap: () => onSelect(start.add(Duration(days: i))),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.year,
    required this.byDay,
    required this.theme,
    required this.onSelectMonth,
  });

  final int year;
  final Map<DateTime, List<FoodEntry>> byDay;
  final AppTheme theme;
  final ValueChanged<int> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 620 ? 4 : (c.maxWidth >= 400 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
          children: [
            for (var m = 1; m <= 12; m++)
              _MiniMonth(
                year: year,
                month: m,
                byDay: byDay,
                theme: theme,
                onTap: () => onSelectMonth(m),
              ),
          ],
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.byDay,
    required this.theme,
    required this.onTap,
  });

  final int year;
  final int month;
  final Map<DateTime, List<FoodEntry>> byDay;
  final AppTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = DateTime(year, month, 1).weekday % 7;
    var monthTotal = 0;
    final dots = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(
          builder: (_) {
            final count = byDay[DateTime(year, month, day)]?.length ?? 0;
            monthTotal += count;
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: count == 0
                    ? theme.inkMuted.withValues(alpha: 0.08)
                    : count >= 3
                    ? theme.primary
                    : count == 2
                    ? theme.primary.withValues(alpha: 0.6)
                    : theme.tagBg,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _monthShort[month - 1],
              style: TextStyle(
                fontFamily: theme.headingFont,
                fontSize: 15,
                color: theme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                physics: const NeverScrollableScrollPhysics(),
                children: dots,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              monthTotal == 0 ? '-' : '$monthTotal logged',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 10.5,
                color: theme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day's header, its note, and its entries.
class _DaySection extends ConsumerWidget {
  const _DaySection({required this.date, required this.entries});
  final DateTime date;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_monthNames[date.month - 1]} ${date.day}',
              style: TextStyle(
                fontFamily: theme.headingFont,
                fontSize: 20,
                color: theme.ink,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              entries.isEmpty
                  ? 'nothing logged'
                  : entries.length == 1
                  ? '1 entry'
                  : '${entries.length} entries',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 13,
                color: theme.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DayNoteCard(date: date),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _EmptyDay(theme: theme)
        else
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayEntryTile(entry: e),
            ),
      ],
    );
  }
}

/// Shows and edits the note for a single day.
class _DayNoteCard extends ConsumerWidget {
  const _DayNoteCard({required this.date});
  final DateTime date;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note for this day'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'How did the day go? What stood out?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(dayNotesControllerProvider.notifier).setNote(date, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final notes = ref.watch(dayNotesControllerProvider).value ?? const {};
    final note = notes[dayKey(date)];

    return InkWell(
      onTap: () => _edit(context, ref, note ?? ''),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.edit_note, color: theme.inkMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: note == null || note.isEmpty
                  ? Text(
                      'Add a note about this day',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 13.5,
                        color: theme.inkMuted,
                      ),
                    )
                  : Text(
                      note,
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 14,
                        height: 1.5,
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

class _DayEntryTile extends ConsumerWidget {
  const _DayEntryTile({required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEntryDetail(context, entry.id!),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 60,
                  child: EntryPhoto(photoPath: entry.photoPath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: theme.headingFont,
                              fontSize: 16,
                              color: theme.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RatingStars(rating: entry.rating, size: 15),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        CategoryTag(category: entry.category),
                        const SizedBox(width: 8),
                        Flexible(
                          child: MadeBoughtLabel(isHomemade: entry.isHomemade),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatEntryTime(entry.eatenAt),
                          style: TextStyle(
                            fontFamily: theme.bodyFont,
                            fontSize: 11.5,
                            color: theme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.no_meals, color: theme.inkMuted, size: 26),
          const SizedBox(height: 8),
          Text(
            'Nothing logged this day.',
            style: TextStyle(fontFamily: theme.bodyFont, color: theme.inkMuted),
          ),
        ],
      ),
    );
  }
}
