import 'dart:async';
import '../models/power_team_meeting.dart';

class PowerTeamMeetingService {
  static final PowerTeamMeetingService _instance = PowerTeamMeetingService._internal();
  factory PowerTeamMeetingService() => _instance;

  final List<PowerTeamMeeting> _meetings = [];
  final StreamController<List<PowerTeamMeeting>> _controller =
      StreamController<List<PowerTeamMeeting>>.broadcast();

  PowerTeamMeetingService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_meetings));
  }

  Stream<List<PowerTeamMeeting>> streamForPowerTeam(String powerTeamName) async* {
    yield _meetings.where((m) => m.powerTeamName == powerTeamName).toList();
    yield* _controller.stream.map((list) => list.where((m) => m.powerTeamName == powerTeamName).toList());
  }

  Future<void> forceSyncPowerTeamMeetings(String powerTeamName) async {
    _notify();
  }

  Future<PowerTeamMeeting?> getById(String meetingId) async {
    try {
      return _meetings.firstWhere((m) => m.docId == meetingId);
    } catch (_) {
      return null;
    }
  }

  Future<void> markAttendance({
    required String meetingId,
    required String qrToken,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {}
}
