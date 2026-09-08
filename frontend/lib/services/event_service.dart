import 'dart:async';
import '../models/event.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;

  final List<Event> _events = [
    const Event(
      docId: "e1",
      name: "Boreo Annual Business Summit 2026",
      description: "Networking, keynotes, and business expansion strategies.",
      eventDate: "2026-10-15",
      eventTime: "09:00 AM",
      location: "Boreo Convention Center, Erode",
      status: "Active",
    ),
    const Event(
      docId: "e2",
      name: "Boreo Power Team Expo",
      description: "Exhibition and cross-chapter collaboration.",
      eventDate: "2026-09-25",
      eventTime: "10:00 AM",
      location: "Trade Fair Hall, Erode",
      status: "Active",
    ),
  ];

  final StreamController<List<Event>> _controller =
      StreamController<List<Event>>.broadcast();

  EventService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_events));
  }

  Stream<List<Event>> streamAll() async* {
    yield _events;
    yield* _controller.stream;
  }

  Future<void> forceSyncAll() async {
    _notify();
  }
}
