class ThankNote {
  final String docId;
  final String type;
  final String? connectorName;
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final String message;
  final double value;
  final String detailDate; // "YYYY-MM-DD"
  final String displayTime; // e.g. "10:30 AM"
  final DateTime? createdAt;
  final String status; // "open" | "close"

  const ThankNote({
    this.docId = "",
    this.type = "self",
    this.connectorName,
    required this.fromUserId,
    required this.fromName,
    this.toUserId = "",
    required this.toName,
    required this.message,
    required this.value,
    required this.detailDate,
    required this.displayTime,
    this.createdAt,
    this.status = "open",
  });

  factory ThankNote.fromMap(String docId, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime? parsedDate;
    if (createdAtRaw is DateTime) {
      parsedDate = createdAtRaw;
    } else if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw);
    }

    return ThankNote(
      docId: docId,
      type: map['type'] ?? "self",
      connectorName: map['connectorName'],
      fromUserId: map['fromUserId'] ?? "",
      fromName: map['fromName'] ?? "",
      toUserId: map['toUserId'] ?? "",
      toName: map['toName'] ?? "",
      message: map['message'] ?? "",
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : 0,
      detailDate: map['detailDate'] ?? "",
      displayTime: map['displayTime'] ?? "",
      createdAt: parsedDate ?? DateTime.now(),
      status: map['status'] ?? "open",
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'type': type,
      if (connectorName != null) 'connectorName': connectorName,
      'fromUserId': fromUserId,
      'fromName': fromName,
      'toUserId': toUserId,
      'toName': toName,
      'message': message,
      'value': value,
      'detailDate': detailDate,
      'displayTime': displayTime,
      'status': status,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
