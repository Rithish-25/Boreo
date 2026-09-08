class Visitor {
  final String docId;
  final String visitorName;
  final String phone;
  final String productsOrServices;
  final String companyName;
  final String inviteById;
  final String inviteByName;
  final String inviteByRID;
  final String? dateOfBirth;
  final DateTime? visitDate;
  final DateTime? createdAt;
  final String source;

  const Visitor({
    this.docId = "",
    required this.visitorName,
    required this.phone,
    required this.productsOrServices,
    required this.companyName,
    required this.inviteById,
    required this.inviteByName,
    required this.inviteByRID,
    this.dateOfBirth,
    this.visitDate,
    this.createdAt,
    required this.source,
  });

  factory Visitor.fromMap(String docId, Map<String, dynamic> map) {
    final visitDateRaw = map['visitDate'];
    final createdAtRaw = map['createdAt'];
    DateTime? parseDate(dynamic raw) {
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return Visitor(
      docId: docId,
      visitorName: map['visitorName'] ?? "",
      phone: map['phone'] ?? "",
      productsOrServices: map['productsOrServices'] ?? "",
      companyName: map['companyName'] ?? "",
      inviteById: map['inviteById'] ?? "",
      inviteByName: map['inviteByName'] ?? "",
      inviteByRID: map['inviteByRID'] ?? "",
      dateOfBirth: map['dateOfBirth'] as String?,
      visitDate: parseDate(visitDateRaw),
      createdAt: parseDate(createdAtRaw) ?? DateTime.now(),
      source: map['source'] ?? "visitor",
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'visitorName': visitorName,
      'phone': phone,
      'productsOrServices': productsOrServices,
      'companyName': companyName,
      'inviteById': inviteById,
      'inviteByName': inviteByName,
      'inviteByRID': inviteByRID,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      'visitDate': visitDate?.toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'source': source,
    };
  }
}
