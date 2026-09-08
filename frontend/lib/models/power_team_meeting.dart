import '../utils/meeting_status.dart';

class PowerTeamMeeting {
  final String docId;
  final String meetingName;
  final String powerTeamName;
  final String powerTeamId;
  final String meetingDate;
  final String meetingTime;
  final String place;
  final String qrToken;
  final List<String> eligibleMemberIds;
  final int eligibleMemberCount;
  final int attendanceCount;
  final String status;

  String get computedStatus => computeMeetingStatus(status, meetingDate);

  const PowerTeamMeeting({
    required this.docId,
    required this.meetingName,
    required this.powerTeamName,
    required this.powerTeamId,
    required this.meetingDate,
    required this.meetingTime,
    required this.place,
    required this.qrToken,
    required this.eligibleMemberIds,
    required this.eligibleMemberCount,
    required this.attendanceCount,
    required this.status,
  });

  factory PowerTeamMeeting.fromMap(String docId, Map<String, dynamic> map) {
    return PowerTeamMeeting(
      docId: docId,
      meetingName: (map['meetingName'] ?? map['title'] ?? map['name'] ?? map['meetingTitle'])?.toString() ?? "",
      powerTeamName: (map['powerTeamName'])?.toString() ?? "",
      powerTeamId: (map['powerTeamId'])?.toString() ?? "",
      meetingDate: _parseDateFallback(map['meetingDate'] ?? map['date'] ?? map['createdAt']) ?? "",
      meetingTime: (map['meetingTime'] ?? map['time'] ?? map['scannedTime'] ?? map['startTime'])?.toString() ?? "",
      place: (map['place'] ?? map['location'] ?? map['address'] ?? map['venue'])?.toString() ?? "",
      qrToken: (map['qrToken'] ?? map['qrCodeData'] ?? map['qrCode'])?.toString() ?? "",
      eligibleMemberIds: List<String>.from(map['eligibleMemberIds'] ?? const []),
      eligibleMemberCount: (map['eligibleMemberCount'] ?? 0) as int,
      attendanceCount: (map['attendanceCount'] ?? 0) as int,
      status: (map['status'])?.toString() ?? "upcoming",
    );
  }

  static String? _parseDateFallback(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) {
      return "${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}";
    }
    return val.toString();
  }
}
