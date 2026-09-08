/// User-facing attendance failure, mirroring AdminPanel's AttendanceError
/// pattern (powerTeamMeetingService.js) so error messages stay consistent
/// between apps.
class AttendanceError implements Exception {
  final String message;
  const AttendanceError(this.message);

  @override
  String toString() => message;
}

/// Generic user-facing service failure (duplicate entry, validation, etc.)
/// for services outside the meeting-attendance flow — mirrors AdminPanel's
/// per-service *Error classes (ReferralError, MeetingLimitsError, ...).
class ServiceError implements Exception {
  final String message;
  const ServiceError(this.message);

  @override
  String toString() => message;
}
