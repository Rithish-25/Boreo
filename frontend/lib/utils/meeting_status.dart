/// Mirrors AdminPanel's utils/meetingStatus.js computeMeetingStatus() —
/// AdminPanel computes this live from meetingDate on every render rather
/// than trusting the stored `status` field, which is only ever written once
/// at creation (and on edit/cancel), so it goes stale the moment a
/// meeting's date arrives or passes. Do the same here for any logic that
/// needs to know whether a meeting is upcoming/ongoing/completed right now.
String computeMeetingStatus(String storedStatus, String meetingDate) {
  if (storedStatus == 'cancelled' || storedStatus == 'Cancelled') {
    return 'cancelled';
  }

  final meetingDay = _parseDateOnly(meetingDate);
  if (meetingDay == null) return storedStatus;

  final today = _todayDateOnly();
  if (meetingDay.isAtSameMomentAs(today)) return 'ongoing';
  if (meetingDay.isAfter(today)) return 'upcoming';
  return 'completed';
}

/// Whether [meetingDate] ("YYYY-MM-DD") is today's date (device-local).
bool isMeetingToday(String meetingDate) {
  final meetingDay = _parseDateOnly(meetingDate);
  if (meetingDay == null) return false;
  return meetingDay.isAtSameMomentAs(_todayDateOnly());
}

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime? _parseDateOnly(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  
  int? year, month, day;
  if (parts[0].length == 4) {
    year = int.tryParse(parts[0]);
    month = int.tryParse(parts[1]);
    day = int.tryParse(parts[2]);
  } else if (parts[2].length == 4) {
    day = int.tryParse(parts[0]);
    month = int.tryParse(parts[1]);
    year = int.tryParse(parts[2]);
  } else {
    return null;
  }

  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}
