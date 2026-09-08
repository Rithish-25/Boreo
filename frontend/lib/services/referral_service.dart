import 'dart:async';
import '../models/referral.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;

  final List<Referral> _referrals = [
    Referral(
      docId: "ref1",
      type: "self",
      referrerId: "m1",
      referrerName: "Rithish Kumar",
      referredUserId: "m2",
      referredUserName: "Karthik Raja",
      createdBy: "m1",
      createdByName: "Rithish Kumar",
      status: "active",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Referral(
      docId: "ref2",
      type: "connect",
      referrerId: "m2",
      referrerName: "Karthik Raja",
      connectorId: "m3",
      connectorName: "Senthil Nathan",
      referredUserId: "m1",
      referredUserName: "Rithish Kumar",
      createdBy: "m2",
      createdByName: "Karthik Raja",
      status: "active",
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final StreamController<List<Referral>> _controller =
      StreamController<List<Referral>>.broadcast();

  ReferralService._internal() {
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_referrals));
  }

  Future<void> create(Referral referral) async {
    final newDocId = "ref_${DateTime.now().millisecondsSinceEpoch}";
    final newRef = Referral(
      docId: newDocId,
      type: referral.type,
      referrerId: referral.referrerId,
      referrerName: referral.referrerName,
      connectorId: referral.connectorId,
      connectorName: referral.connectorName,
      referredUserId: referral.referredUserId,
      referredUserName: referral.referredUserName,
      createdBy: referral.createdBy,
      createdByName: referral.createdByName,
      status: "active",
      createdAt: DateTime.now(),
    );

    _referrals.add(newRef);
    _notify();
  }

  Stream<List<Referral>> streamForMember(String memberId) async* {
    yield _filterSent(memberId);
    yield* _controller.stream.map((_) => _filterSent(memberId));
  }

  Stream<List<Referral>> streamReceivedByMember(String memberId) async* {
    yield _filterReceived(memberId);
    yield* _controller.stream.map((_) => _filterReceived(memberId));
  }

  List<Referral> _filterSent(String memberId) {
    return _referrals.where((r) => r.referrerId == memberId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  List<Referral> _filterReceived(String memberId) {
    return _referrals.where((r) => r.referredUserId == memberId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<void> update(String docId, Map<String, dynamic> data) async {
    final index = _referrals.indexWhere((r) => r.docId == docId);
    if (index != -1) {
      final old = _referrals[index];
      _referrals[index] = Referral(
        docId: old.docId,
        type: data['type'] ?? old.type,
        referrerId: old.referrerId,
        referrerName: old.referrerName,
        connectorId: data.containsKey('connectorId') ? data['connectorId'] : old.connectorId,
        connectorName: data.containsKey('connectorName') ? data['connectorName'] : old.connectorName,
        referredUserId: data['referredUserId'] ?? old.referredUserId,
        referredUserName: data['referredUserName'] ?? old.referredUserName,
        createdBy: old.createdBy,
        createdByName: old.createdByName,
        status: data['status'] ?? old.status,
        createdAt: old.createdAt,
      );
      _notify();
    }
  }

  Future<void> updateAndReplaceIfNeeded(String docId, Referral referral) async {
    final index = _referrals.indexWhere((r) => r.docId == docId);
    if (index != -1) {
      _referrals[index] = referral;
      _notify();
    }
  }

  Future<void> delete(String docId) async {
    _referrals.removeWhere((r) => r.docId == docId);
    _notify();
  }
}
