class AttendanceRecord {
  final String docId;
  final String userUid;
  final String memberId;
  final String memberName;
  final String ridNo;
  final String meetingDate;
  final DateTime? scannedAt;
  final String status;

  const AttendanceRecord({
    required this.docId,
    required this.userUid,
    required this.memberId,
    required this.memberName,
    required this.ridNo,
    required this.meetingDate,
    required this.scannedAt,
    required this.status,
  });

  factory AttendanceRecord.fromMap(String docId, Map<String, dynamic> map) {
    final scannedAtRaw = map['scannedAt'];
    DateTime? parsedDate;
    if (scannedAtRaw is DateTime) {
      parsedDate = scannedAtRaw;
    } else if (scannedAtRaw is String) {
      parsedDate = DateTime.tryParse(scannedAtRaw);
    }

    return AttendanceRecord(
      docId: docId,
      userUid: map['userUid'] ?? "",
      memberId: map['memberId'] ?? "",
      memberName: map['memberName'] ?? "",
      ridNo: map['ridNo'] ?? "",
      meetingDate: map['meetingDate'] ?? "",
      scannedAt: parsedDate,
      status: map['status'] ?? "",
    );
  }
}
