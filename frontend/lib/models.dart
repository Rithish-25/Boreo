class Booking {
  final String id;
  final String title;
  final String type;
  final String date;
  final String colorCode;
  final String description;
  final String time;
  final bool isRecurringYearly;

  Booking({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.colorCode,
    required this.description,
    required this.time,
    this.isRecurringYearly = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      colorCode: json['colorCode'] ?? json['color'] ?? '#1E3A8A',
      description: json['description'] ?? '',
      time: json['time'] ?? 'All Day',
      isRecurringYearly: json['isRecurringYearly'] ?? false,
    );
  }
}

class NewsEvent {
  final String id;
  final String title;
  final String date;
  final String imageUrl;
  final String description;
  final String location;

  NewsEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.description,
    required this.location,
  });

  factory NewsEvent.fromJson(Map<String, dynamic> json) {
    return NewsEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
    );
  }
}
