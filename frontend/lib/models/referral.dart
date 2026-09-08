class Referral {
  final String docId;
  final String type; // "self" | "connect"
  final String referrerId;
  final String referrerName;
  final String? connectorId;
  final String? connectorName;
  final String referredUserId;
  final String referredUserName;
  final String createdBy;
  final String createdByName;
  final String status;
  final DateTime? createdAt;

  const Referral({
    this.docId = "",
    required this.type,
    required this.referrerId,
    required this.referrerName,
    this.connectorId,
    this.connectorName,
    required this.referredUserId,
    required this.referredUserName,
    required this.createdBy,
    required this.createdByName,
    this.status = "active",
    this.createdAt,
  });

  factory Referral.fromMap(String docId, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime? parsedDate;
    if (createdAtRaw is DateTime) {
      parsedDate = createdAtRaw;
    } else if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw);
    }

    return Referral(
      docId: docId,
      type: map['type'] ?? "self",
      referrerId: map['referrerId'] ?? "",
      referrerName: map['referrerName'] ?? "",
      connectorId: map['connectorId'] as String?,
      connectorName: map['connectorName'] as String?,
      referredUserId: map['referredUserId'] ?? "",
      referredUserName: map['referredUserName'] ?? "",
      createdBy: map['createdBy'] ?? "",
      createdByName: map['createdByName'] ?? "",
      status: map['status'] ?? "active",
      createdAt: parsedDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'type': type,
      'status': 'active',
      'createdBy': createdBy,
      'createdByName': createdByName,
      'referrerId': referrerId,
      'referrerName': referrerName,
      'referredUserId': referredUserId,
      'referredUserName': referredUserName,
      'connectorId': type == 'connect' ? connectorId : null,
      'connectorName': type == 'connect' ? connectorName : null,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
