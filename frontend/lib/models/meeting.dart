import '../utils/meeting_status.dart';

class Meeting {
  final String docId;
  final String meetingName;
  final String meetingDate; // "YYYY-MM-DD"
  final String meetingTime; // "HH:MM"
  final String place;
  final String qrToken;
  final String status;

  const Meeting({
    required this.docId,
    required this.meetingName,
    required this.meetingDate,
    required this.meetingTime,
    required this.place,
    required this.qrToken,
    required this.status,
  });

  String get computedStatus => computeMeetingStatus(status, meetingDate);

  factory Meeting.fromMap(String docId, Map<String, dynamic> map) {
    return Meeting(
      docId: docId,
      meetingName: (map['meetingName'] ?? map['title'] ?? map['name'] ?? map['meetingTitle'])?.toString() ?? "",
      meetingDate: _parseDateFallback(map['meetingDate'] ?? map['date'] ?? map['createdAt']) ?? "",
      meetingTime: (map['meetingTime'] ?? map['time'] ?? map['scannedTime'] ?? map['startTime'])?.toString() ?? "",
      place: (map['place'] ?? map['location'] ?? map['address'] ?? map['venue'])?.toString() ?? "",
      qrToken: (map['qrToken'] ?? map['qrCodeData'] ?? map['qrCode'])?.toString() ?? "",
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
