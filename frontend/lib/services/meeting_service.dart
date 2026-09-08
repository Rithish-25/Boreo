import 'dart:async';
import '../models/attendance_record.dart';
import '../models/meeting.dart';

class MeetingService {
  static final MeetingService _instance = MeetingService._internal();
  factory MeetingService() => _instance;

  final List<Meeting> _meetings = [
    const Meeting(
      docId: "m_1",
      meetingName: "Boreo Weekly Business Conclave",
      meetingDate: "2026-09-12",
      meetingTime: "07:00 AM",
      place: "Grand Palace Hotel, Erode",
      qrToken: "BOREO_QR_0912",
      status: "upcoming",
    ),
    const Meeting(
      docId: "m_2",
      meetingName: "Boreo Executive Power Meet",
      meetingDate: "2026-09-05",
      meetingTime: "07:00 AM",
      place: "Boreo Hall, Erode",
      qrToken: "BOREO_QR_0905",
      status: "completed",
    ),
  ];

  final Map<String, Map<String, AttendanceRecord>> _attendance = {
    "m_2": {
      "m1": AttendanceRecord(
        docId: "m1",
        userUid: "m1",
        memberId: "m1",
        memberName: "Rithish Kumar",
        ridNo: "1001",
        meetingDate: "2026-09-05",
        scannedAt: DateTime.now().subtract(const Duration(days: 3)),
        status: "present",
      )
    }
  };

  final StreamController<List<Meeting>> _meetingsController =
      StreamController<List<Meeting>>.broadcast();

  final StreamController<void> _attendanceNotifier =
      StreamController<void>.broadcast();

  MeetingService._internal() {
    _notify();
  }

  void _notify() {
    _meetingsController.add(List.unmodifiable(_meetings));
  }

  Stream<List<Meeting>> streamMeetings() async* {
    yield _meetings;
    yield* _meetingsController.stream;
  }

  Future<void> forceSyncMeetings() async {
    _notify();
  }

  Future<Meeting?> getById(String meetingId) async {
    try {
      return _meetings.firstWhere((m) => m.docId == meetingId);
    } catch (_) {
      return null;
    }
  }

  Stream<Meeting?> streamNextUpcoming() async* {
    Meeting? findNext() {
      final upcoming = _meetings
          .where((m) => m.computedStatus == 'upcoming' || m.computedStatus == 'ongoing')
          .toList()
        ..sort((a, b) => a.meetingDate.compareTo(b.meetingDate));
      return upcoming.isEmpty ? null : upcoming.first;
    }

    yield findNext();
    yield* _meetingsController.stream.map((_) => findNext());
  }

  Stream<AttendanceRecord?> streamMyAttendance(String meetingId, String memberId) async* {
    AttendanceRecord? getRecord() {
      return _attendance[meetingId]?[memberId];
    }

    yield getRecord();
    yield* _attendanceNotifier.stream.map((_) => getRecord());
  }

  /// Stream of total attended meeting count for member (used by Home dashboard)
  Stream<int> streamMyAttendanceCount(String memberId) async* {
    int count() {
      int c = 0;
      for (var meetingMap in _attendance.values) {
        final rec = meetingMap[memberId];
        if (rec != null && (rec.status == 'present' || rec.status == 'late')) {
          c++;
        }
      }
      return c;
    }

    yield count();
    yield* _attendanceNotifier.stream.map((_) => count());
  }

  Future<String> markAttendance({
    required String meetingId,
    required String qrToken,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {
    final meetingMap = _attendance.putIfAbsent(meetingId, () => {});
    meetingMap[memberId] = AttendanceRecord(
      docId: memberId,
      userUid: memberId,
      memberId: memberId,
      memberName: memberName,
      ridNo: ridNo,
      meetingDate: DateTime.now().toIso8601String().split('T')[0],
      scannedAt: DateTime.now(),
      status: "present",
    );
    _attendanceNotifier.add(null);
    return "present";
  }

  Future<void> applyLeave({
    required String meetingId,
    required String meetingDate,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {
    final meetingMap = _attendance.putIfAbsent(meetingId, () => {});
    meetingMap[memberId] = AttendanceRecord(
      docId: memberId,
      userUid: memberId,
      memberId: memberId,
      memberName: memberName,
      ridNo: ridNo,
      meetingDate: meetingDate,
      scannedAt: null,
      status: "leave",
    );
    _attendanceNotifier.add(null);
  }

  Future<void> cancelLeave(String meetingId, String memberId) async {
    final meetingMap = _attendance[meetingId];
    if (meetingMap != null && meetingMap[memberId]?.status == 'leave') {
      meetingMap.remove(memberId);
      _attendanceNotifier.add(null);
    }
  }

  Future<void> applyPermission({
    required String meetingId,
    required String meetingDate,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {
    final meetingMap = _attendance.putIfAbsent(meetingId, () => {});
    meetingMap[memberId] = AttendanceRecord(
      docId: memberId,
      userUid: memberId,
      memberId: memberId,
      memberName: memberName,
      ridNo: ridNo,
      meetingDate: meetingDate,
      scannedAt: null,
      status: "permission",
    );
    _attendanceNotifier.add(null);
  }

  Future<void> cancelPermission(String meetingId, String memberId) async {
    final meetingMap = _attendance[meetingId];
    if (meetingMap != null && meetingMap[memberId]?.status == 'permission') {
      meetingMap.remove(memberId);
      _attendanceNotifier.add(null);
    }
  }
}
