import 'dart:async';
import '../models/visitor.dart';

class VisitorService {
  static final VisitorService _instance = VisitorService._internal();
  factory VisitorService() => _instance;

  final List<Visitor> _visitors = [];
  final StreamController<List<Visitor>> _controller =
      StreamController<List<Visitor>>.broadcast();

  VisitorService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_visitors));
  }

  Future<void> createVisitor(Visitor visitor) async {
    final newId = "v_${DateTime.now().millisecondsSinceEpoch}";
    final newVisitor = Visitor(
      docId: newId,
      visitorName: visitor.visitorName,
      phone: visitor.phone,
      productsOrServices: visitor.productsOrServices,
      companyName: visitor.companyName,
      inviteById: visitor.inviteById,
      inviteByName: visitor.inviteByName,
      inviteByRID: visitor.inviteByRID,
      dateOfBirth: visitor.dateOfBirth,
      visitDate: visitor.visitDate,
      createdAt: DateTime.now(),
      source: visitor.source,
    );

    _visitors.add(newVisitor);
    _notify();
  }

  Future<void> submitVisitor(Visitor visitor) => createVisitor(visitor);

  Stream<List<Visitor>> streamForMember(String memberId) async* {
    yield _filter(memberId);
    yield* _controller.stream.map((_) => _filter(memberId));
  }

  List<Visitor> _filter(String memberId) {
    return _visitors.where((v) => v.inviteById == memberId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }
}
