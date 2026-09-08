class Event {
  final String docId;
  final String name;
  final String description;
  final String eventDate; // "YYYY-MM-DD"
  final String eventTime;
  final String location;
  final String? imageUrl;
  final String status;

  const Event({
    required this.docId,
    required this.name,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    this.imageUrl,
    required this.status,
  });

  factory Event.fromMap(String docId, Map<String, dynamic> map) {
    String extractedDate = "";
    if (map['Date'] is DateTime) {
      final DateTime dt = map['Date'] as DateTime;
      extractedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } else if (map['Date'] is String) {
      extractedDate = map['Date'];
    } else if (map['eventDate'] != null) {
      extractedDate = map['eventDate'].toString();
    }

    return Event(
      docId: docId,
      name: map['Event Name'] ?? map['name'] ?? "",
      description: map['Description'] ?? map['description'] ?? "",
      eventDate: extractedDate,
      eventTime: map['time'] ?? map['eventTime'] ?? "",
      location: map['Location'] ?? map['location'] ?? "",
      imageUrl: (map['eventImage'] as String?) ?? (map['imageUrl'] as String?),
      status: map['status'] ?? "Active",
    );
  }
}
