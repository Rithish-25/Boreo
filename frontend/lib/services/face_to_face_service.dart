import 'dart:async';
import '../models/face_to_face.dart';

class FaceToFaceService {
  static final FaceToFaceService _instance = FaceToFaceService._internal();
  factory FaceToFaceService() => _instance;

  final List<FaceToFace> _records = [
    FaceToFace(
      docId: "r1",
      fromMemberUid: "m1",
      fromMemberName: "Rithish Kumar",
      toMemberUid: "m2",
      toMemberName: "Karthik Raja",
      term: "Term 1",
      meetingAt: "2026-08-10",
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    FaceToFace(
      docId: "r2",
      fromMemberUid: "m1",
      fromMemberName: "Rithish Kumar",
      toMemberUid: "m3",
      toMemberName: "Senthil Nathan",
      term: "Term 1",
      meetingAt: "2026-08-18",
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  final StreamController<List<FaceToFace>> _controller =
      StreamController<List<FaceToFace>>.broadcast();

  FaceToFaceService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_records));
  }

  Future<void> create(FaceToFace entry) async {
    final newId = "r_${DateTime.now().millisecondsSinceEpoch}";
    final newEntry = FaceToFace(
      docId: newId,
      fromMemberUid: entry.fromMemberUid,
      fromMemberName: entry.fromMemberName,
      toMemberUid: entry.toMemberUid,
      toMemberName: entry.toMemberName,
      term: entry.term,
      meetingAt: entry.meetingAt,
      createdAt: DateTime.now(),
    );

    _records.add(newEntry);
    _notify();
  }

  Stream<List<FaceToFace>> streamSentByMember(String memberId) async* {
    yield _filter(memberId);
    yield* _controller.stream.map((_) => _filter(memberId));
  }

  List<FaceToFace> _filter(String memberId) {
    return _records
        .where((r) => r.fromMemberUid == memberId || r.toMemberUid == memberId)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }
}
