import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_label.dart';
import '../../../shared/rating_badge.dart';
import '../../entries/application/entries_controller.dart';
import '../../entries/data/food_entry.dart';
import '../../entries/presentation/widgets/entry_photo.dart';

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
const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

DateTime _dayOf(DateTime dt) {
  final l = dt.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Calendar: a month grid where days with entries are shaded, and the selected
/// day's entries are listed below.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month; // first day of the displayed month
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
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
          byDay.putIfAbsent(_dayOf(e.eatenAt), () => []).add(e);
        }
        final selectedEntries = byDay[_selected] ?? const [];
        return ContentColumn(
          maxWidth: 760,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthHeader(
                  month: _month,
                  onPrev: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: 16),
                _MonthGrid(
                  month: _month,
                  selected: _selected,
                  byDay: byDay,
                  theme: theme,
                  onSelect: (d) => setState(() => _selected = d),
                ),
                const SizedBox(height: 28),
                _SelectedDayHeader(
                  day: _selected,
                  count: selectedEntries.length,
                ),
                const SizedBox(height: 12),
                if (selectedEntries.isEmpty)
                  _EmptyDay(theme: theme)
                else
                  for (final e in selectedEntries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayEntryTile(entry: e),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Row(
      children: [
        Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: TextStyle(
            fontFamily: theme.headingFont,
            fontSize: 26,
            color: theme.ink,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left, color: theme.inkMuted),
          tooltip: 'Previous month',
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: theme.inkMuted),
          tooltip: 'Next month',
        ),
      ],
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
    final today = _dayOf(DateTime.now());
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7; // Sun=0
    final cells = <Widget>[];

    for (final l in _weekdayLetters) {
      cells.add(
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
      );
    }
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(
        _DayCell(
          date: date,
          count: byDay[date]?.length ?? 0,
          isToday: date == today,
          isSelected: date == selected,
          theme: theme,
          onTap: () => onSelect(date),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }
}

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
    // Shade intensity grows with entry count.
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
        alignment: Alignment.center,
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
    );
  }
}

class _SelectedDayHeader extends ConsumerWidget {
  const _SelectedDayHeader({required this.day, required this.count});
  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final label = '${_monthNames[day.month - 1]} ${day.day}';
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: theme.headingFont,
            fontSize: 20,
            color: theme.ink,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          count == 0
              ? 'nothing logged'
              : count == 1
              ? '1 entry'
              : '$count entries',
          style: TextStyle(
            fontFamily: theme.bodyFont,
            fontSize: 13,
            color: theme.inkMuted,
          ),
        ),
      ],
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
        onTap: () => context.go('/entry/${entry.id}'),
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
                        RatingBadge(rating: entry.rating),
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
      padding: const EdgeInsets.symmetric(vertical: 26),
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
