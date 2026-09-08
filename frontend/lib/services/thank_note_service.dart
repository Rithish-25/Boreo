import 'dart:async';
import '../models/thank_note.dart';

class ThankNoteService {
  static final ThankNoteService _instance = ThankNoteService._internal();
  factory ThankNoteService() => _instance;

  final List<ThankNote> _notes = [
    ThankNote(
      docId: "tn1",
      type: "self",
      fromUserId: "m1",
      fromName: "Rithish Kumar",
      toUserId: "m2",
      toName: "Karthik Raja",
      message: "Thank you for the software deal reference!",
      value: 25000,
      detailDate: "2026-08-15",
      displayTime: "10:30 AM",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: "open",
    ),
    ThankNote(
      docId: "tn2",
      type: "self",
      fromUserId: "m2",
      fromName: "Karthik Raja",
      toUserId: "m1",
      toName: "Rithish Kumar",
      message: "Great work on the web app contract!",
      value: 50000,
      detailDate: "2026-08-20",
      displayTime: "02:15 PM",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: "open",
    ),
  ];

  final StreamController<List<ThankNote>> _controller =
      StreamController<List<ThankNote>>.broadcast();

  ThankNoteService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_notes));
  }

  Future<void> create(ThankNote note) async {
    final newId = "tn_${DateTime.now().millisecondsSinceEpoch}";
    final newNote = ThankNote(
      docId: newId,
      type: note.type,
      connectorName: note.connectorName,
      fromUserId: note.fromUserId,
      fromName: note.fromName,
      toUserId: note.toUserId,
      toName: note.toName,
      message: note.message,
      value: note.value,
      detailDate: note.detailDate,
      displayTime: note.displayTime,
      createdAt: DateTime.now(),
      status: "open",
    );

    _notes.add(newNote);
    _notify();
  }

  Stream<List<ThankNote>> streamForMember(String memberId) async* {
    yield _filterSent(memberId);
    yield* _controller.stream.map((_) => _filterSent(memberId));
  }

  Stream<List<ThankNote>> streamReceivedByMember(String memberId) async* {
    yield _filterReceived(memberId);
    yield* _controller.stream.map((_) => _filterReceived(memberId));
  }

  List<ThankNote> _filterSent(String memberId) {
    return _notes.where((n) => n.fromUserId == memberId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  List<ThankNote> _filterReceived(String memberId) {
    return _notes.where((n) => n.toUserId == memberId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<void> update(String docId, Map<String, dynamic> data) async {
    final index = _notes.indexWhere((n) => n.docId == docId);
    if (index != -1) {
      final old = _notes[index];
      _notes[index] = ThankNote(
        docId: old.docId,
        type: data['type'] ?? old.type,
        connectorName: data.containsKey('connectorName') ? data['connectorName'] : old.connectorName,
        fromUserId: old.fromUserId,
        fromName: old.fromName,
        toUserId: data['toUserId'] ?? old.toUserId,
        toName: data['toName'] ?? old.toName,
        message: data['message'] ?? old.message,
        value: data.containsKey('value') ? (data['value'] as num).toDouble() : old.value,
        detailDate: old.detailDate,
        displayTime: old.displayTime,
        createdAt: old.createdAt,
        status: old.status,
      );
      _notify();
    }
  }

  Future<void> delete(String docId) async {
    _notes.removeWhere((n) => n.docId == docId);
    _notify();
  }
}
