class FaceToFace {
  final String docId;
  final String fromMemberUid;
  final String fromMemberName;
  final String toMemberUid;
  final String toMemberName;
  final String term;
  final String meetingAt;
  final DateTime? createdAt;

  const FaceToFace({
    this.docId = "",
    required this.fromMemberUid,
    required this.fromMemberName,
    required this.toMemberUid,
    required this.toMemberName,
    required this.term,
    this.meetingAt = "",
    this.createdAt,
  });

  factory FaceToFace.fromMap(String docId, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime? parsedDate;
    if (createdAtRaw is DateTime) {
      parsedDate = createdAtRaw;
    } else if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw);
    }

    return FaceToFace(
      docId: docId,
      fromMemberUid: map['fromMemberUid'] ?? map['fromUserId'] ?? "",
      fromMemberName: map['fromMemberName'] ?? "",
      toMemberUid: map['toMemberUid'] ?? map['toUserId'] ?? "",
      toMemberName: map['toMemberName'] ?? "",
      term: map['term'] ?? "",
      meetingAt: map['meetingAt'] ?? "",
      createdAt: parsedDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'fromMemberUid': fromMemberUid,
      'fromUserId': fromMemberUid,
      'fromMemberName': fromMemberName,
      'toMemberUid': toMemberUid,
      'toUserId': toMemberUid,
      'toMemberName': toMemberName,
      'term': term,
      'meetingAt': meetingAt,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
