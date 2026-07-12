import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/category_tag.dart';
import '../../entries/application/entries_controller.dart';
import '../../entries/application/journal_stats.dart';
import '../../entries/data/food_entry.dart';
import '../../entries/presentation/entry_detail_screen.dart';
import '../../entries/presentation/widgets/entry_photo.dart';

/// Insights (Direction B): resurfaced memories + logging streak, plus a few
/// at-a-glance numbers. All derived from the loaded entries.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesControllerProvider);
    final theme = ref.watch(themeControllerProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load insights")),
      data: (entries) {
        if (entries.isEmpty) {
          return const _Empty();
        }
        final stats = JournalStats(entries);
        return ContentColumn(
          maxWidth: 760,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(theme, 'On this day'),
                const SizedBox(height: 12),
                _OnThisDay(entries: stats.onThisDay),
                const SizedBox(height: 30),
                _label(theme, 'Your logging streak'),
                const SizedBox(height: 14),
                _Streak(stats: stats),
                const SizedBox(height: 30),
                _label(theme, 'All time'),
                const SizedBox(height: 14),
                _Kpis(stats: stats),
                const SizedBox(height: 30),
                _label(theme, 'Breakdown'),
                const SizedBox(height: 14),
                _Charts(stats: stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(AppTheme theme, String s) => Text(
    s.toUpperCase(),
    style: TextStyle(
      fontFamily: theme.bodyFont,
      fontSize: 11,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w700,
      color: theme.inkMuted,
    ),
  );
}

class _OnThisDay extends ConsumerWidget {
  const _OnThisDay({required this.entries});
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.event_repeat, color: theme.inkMuted, size: 28),
            const SizedBox(height: 10),
            Text(
              'Nothing from earlier years yet.',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                color: theme.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Keep logging and past days will resurface here.',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 12.5,
                color: theme.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final e in entries.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showEntryDetail(context, e.id!),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 96,
                          height: 70,
                          child: EntryPhoto(photoPath: e.photoPath),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: TextStyle(
                                fontFamily: theme.headingFont,
                                fontSize: 19,
                                color: theme.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CategoryTag(category: e.category),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${_ago(e.eatenAt)} · you rated it ${e.rating}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: theme.bodyFont,
                                      fontSize: 12.5,
                                      color: theme.inkMuted,
                                    ),
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
            ),
          ),
      ],
    );
  }

  String _ago(DateTime dt) {
    final months = (DateTime.now().difference(dt.toLocal()).inDays / 30)
        .round();
    if (months >= 12) {
      final y = (months / 12).round();
      return y == 1 ? 'a year ago' : '$y years ago';
    }
    return months <= 1 ? 'a month ago' : '$months months ago';
  }
}

class _Streak extends ConsumerWidget {
  const _Streak({required this.stats});
  final JournalStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final days = stats.loggedDays(window: 14);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${stats.currentStreak}',
                style: TextStyle(
                  fontFamily: theme.headingFont,
                  fontSize: 40,
                  height: 1,
                  color: theme.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stats.currentStreak == 1 ? 'day streak' : 'day streak',
                style: TextStyle(
                  fontFamily: theme.bodyFont,
                  fontSize: 14,
                  color: theme.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 5.0;
              final cell = (c.maxWidth - gap * (days.length - 1)) / days.length;
              return Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Container(
                      width: cell,
                      height: cell.clamp(10, 26),
                      decoration: BoxDecoration(
                        color: days[i] ? theme.primary : theme.tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Last 14 days · ${days.where((d) => d).length} logged',
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 12.5,
              color: theme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.stats});
  final JournalStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Kpi('${stats.total}', 'Entries'),
      _Kpi(stats.avgRating.toStringAsFixed(1), 'Avg rating'),
      _Kpi('${stats.homemadePercent}%', 'Homemade'),
      _Kpi(stats.topCategoryLabel ?? '—', 'Top category'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 520 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _Kpi extends ConsumerWidget {
  const _Kpi(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: theme.headingFont,
              fontSize: 26,
              height: 1,
              color: theme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 10.5,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 44, color: theme.primary),
            const SizedBox(height: 16),
            Text('No insights yet', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Log a few meals and your habits will show up here.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A monochrome ramp derived from the theme accent, for chart segments.
List<Color> _rampFrom(Color base, int n) {
  final hsl = HSLColor.fromColor(base);
  return [
    for (var i = 0; i < n; i++)
      hsl
          .withLightness((hsl.lightness - 0.12 + i * 0.12).clamp(0.28, 0.82))
          .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
          .toColor(),
  ];
}

/// Category pie + made/bought + rating distribution charts.
class _Charts extends ConsumerWidget {
  const _Charts({required this.stats});
  final JournalStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 560;
        final cat = _CategoryPie(stats: stats, theme: theme);
        final ratings = _RatingBars(stats: stats, theme: theme);
        if (wide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cat),
                  const SizedBox(width: 16),
                  Expanded(child: ratings),
                ],
              ),
            ],
          );
        }
        return Column(children: [cat, const SizedBox(height: 16), ratings]);
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.theme,
    required this.title,
    required this.child,
  });
  final AppTheme theme;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.stats, required this.theme});
  final JournalStats stats;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final data = stats.byCategory;
    final entries = data.entries.toList();
    final colors = _rampFrom(theme.primary, entries.length);
    return _ChartCard(
      theme: theme,
      title: 'By category',
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      color: colors[i],
                      title: '${entries[i].value}',
                      radius: 40,
                      titleStyle: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.onPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (var i = 0; i < entries.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entries[i].key.label,
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 12,
                        color: theme.ink,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBars extends StatelessWidget {
  const _RatingBars({required this.stats, required this.theme});
  final JournalStats stats;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final buckets = stats.ratingBuckets;
    final maxY = (buckets.fold<int>(0, (a, b) => b > a ? b : a)).toDouble();
    return _ChartCard(
      theme: theme,
      title: 'Ratings',
      child: SizedBox(
        height: 178,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY <= 0 ? 1 : maxY * 1.2,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${value.toInt() + 1}★',
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 11,
                        color: theme.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < 5; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: buckets[i].toDouble(),
                      color: theme.primary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
