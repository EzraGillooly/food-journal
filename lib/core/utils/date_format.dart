/// Shared date/time formatting for entries, so the feed card, detail, and form
/// all render times identically from one place.
library;

String _two(int n) => n.toString().padLeft(2, '0');

int _hour12(DateTime d) => d.hour % 12 == 0 ? 12 : d.hour % 12;

String _ampm(DateTime d) => d.hour < 12 ? 'AM' : 'PM';

/// "3:07 PM" in the local zone.
String formatEntryTime(DateTime d) {
  final local = d.toLocal();
  return '${_hour12(local)}:${_two(local.minute)} ${_ampm(local)}';
}

/// "2026-07-11" in the local zone (date only).
String formatEntryDate(DateTime d) {
  final local = d.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}

/// "2026-07-11  3:07 PM" in the local zone.
String formatEntryDateTime(DateTime d) {
  final local = d.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)}'
      '  ${formatEntryTime(local)}';
}
