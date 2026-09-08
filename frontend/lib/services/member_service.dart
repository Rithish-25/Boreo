import 'dart:async';
import 'dart:io';
import '../models/member.dart';

class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;

  final List<Member> _members = [
    const Member(
      docId: "m1",
      uid: "m1",
      ridNo: "1001",
      fullName: "Rithish Kumar",
      email: "rithish@boreo.app",
      phone: "9876543210",
      whatsappNumber: "9876543210",
      bloodGroup: "O+",
      fatherName: "Kumar",
      education: "B.Tech Computer Science",
      address: "123 Boreo Towers, Erode",
      companyName: "Boreo Tech Solutions",
      businessType: "Software & Technology",
      businessAddress: "45 Innovation Street, Erode",
      officeNo: "0424-2223344",
      websiteUrl: "https://boreo.app",
      status: "Active",
      powerTeam: "IT & Technology",
      position: "Founder & CEO",
      dateOfBirth: "1995-05-15",
      businessStartDate: "2018-01-10",
      wedding: "2021-11-20",
      wifeName: "Anitha Rithish",
    ),
    const Member(
      docId: "m2",
      uid: "m2",
      ridNo: "1002",
      fullName: "Karthik Raja",
      email: "karthik@boreo.app",
      phone: "9876543211",
      whatsappNumber: "9876543211",
      bloodGroup: "A+",
      fatherName: "Raja",
      education: "MBA Marketing",
      address: "56 Green Park Avenue, Erode",
      companyName: "Apex Logistics & Trade",
      businessType: "Logistics & Supply Chain",
      businessAddress: "88 Freight Depot Road, Erode",
      officeNo: "0424-2225566",
      websiteUrl: "https://apexlogistics.in",
      status: "Active",
      powerTeam: "Logistics & Real Estate",
      position: "Managing Director",
      dateOfBirth: "1992-08-22",
      businessStartDate: "2016-04-01",
      wedding: "2019-06-12",
      wifeName: "Priya Karthik",
    ),
    const Member(
      docId: "m3",
      uid: "m3",
      ridNo: "1003",
      fullName: "Senthil Nathan",
      email: "senthil@boreo.app",
      phone: "9876543212",
      whatsappNumber: "9876543212",
      bloodGroup: "B+",
      fatherName: "Nathan",
      education: "B.E Civil Engineering",
      address: "12 Heritage Enclave, Erode",
      companyName: "Nathan Builders & Infra",
      businessType: "Construction & Contracting",
      businessAddress: "102 Construction Plaza, Erode",
      officeNo: "0424-2227788",
      websiteUrl: "https://nathanbuilders.com",
      status: "Active",
      powerTeam: "Construction & Interior",
      position: "Chief Engineer",
      dateOfBirth: "1988-12-04",
      businessStartDate: "2012-09-15",
      wedding: "2015-02-18",
      wifeName: "Meena Senthil",
    ),
  ];

  final StreamController<List<Member>> _membersController =
      StreamController<List<Member>>.broadcast();

  MemberService._internal() {
    _notify();
  }

  void _notify() {
    _membersController.add(List.unmodifiable(_members));
  }

  static String normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '');

  Future<Member?> getByPhoneAndDob(String phone, String dateOfBirth) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return null;

    // Check if member already exists
    final existingIndex = _members.indexWhere((m) => normalizePhone(m.phone) == normalized);
    if (existingIndex != -1) {
      final existing = _members[existingIndex];
      if (dateOfBirth.isNotEmpty && existing.dateOfBirth != dateOfBirth) {
        final updated = existing.copyWith(dateOfBirth: dateOfBirth);
        _members[existingIndex] = updated;
        _notify();
        return updated;
      }
      return existing;
    }

    // Auto-register new member for instant login
    final newMemberId = "m_${DateTime.now().millisecondsSinceEpoch}";
    final newMember = Member(
      docId: newMemberId,
      uid: newMemberId,
      ridNo: "${1000 + _members.length + 1}",
      fullName: "Boreo Member",
      email: "member_$normalized@boreo.app",
      phone: normalized,
      whatsappNumber: normalized,
      bloodGroup: "O+",
      fatherName: "Father",
      education: "Graduate",
      address: "Erode, Tamil Nadu",
      companyName: "Boreo Enterprise",
      businessType: "General Business",
      businessAddress: "Erode, Tamil Nadu",
      officeNo: "0424-2200000",
      websiteUrl: "https://boreo.app",
      status: "Active",
      powerTeam: "Business Network",
      position: "Member",
      dateOfBirth: dateOfBirth.isNotEmpty ? dateOfBirth : "1995-01-01",
      businessStartDate: "2020-01-01",
      wedding: "2021-01-01",
      wifeName: "Spouse",
    );

    _members.add(newMember);
    _notify();
    return newMember;
  }

  Future<Member?> getById(String memberId) async {
    try {
      return _members.firstWhere((m) => m.docId == memberId);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Member>> streamActiveMembers() async* {
    yield _members.where((m) => m.status == 'Active').toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    yield* _membersController.stream.map((list) {
      final active = list.where((m) => m.status == 'Active').toList();
      active.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return active;
    });
  }

  Future<void> forceSyncActiveMembers() async {
    _notify();
  }

  Future<void> updateProfile(String memberId, Map<String, dynamic> fields) async {
    final index = _members.indexWhere((m) => m.docId == memberId);
    if (index != -1) {
      final current = _members[index];
      final updated = current.copyWith(
        phone: fields['phone'] as String? ?? current.phone,
        whatsappNumber: fields['whatsappNumber'] as String? ?? current.whatsappNumber,
        ridNo: fields['ridNo'] as String? ?? current.ridNo,
        dateOfBirth: fields['dateOfBirth'] as String? ?? current.dateOfBirth,
        wedding: fields['wedding'] as String? ?? current.wedding,
        bloodGroup: fields['bloodGroup'] as String? ?? current.bloodGroup,
        businessStartDate: fields['businessStartDate'] as String? ?? current.businessStartDate,
        businessAddress: fields['businessAddress'] as String? ?? current.businessAddress,
        profileImage: fields['profileImage'] as String? ?? current.profileImage,
      );
      _members[index] = updated;
      _notify();
    }
  }

  Future<String> uploadProfileImage(String memberId, File imageFile) async {
    final path = imageFile.path;
    await updateProfile(memberId, {'profileImage': path});
    return path;
  }

  Future<void> registerFcmToken(String memberId, String token) async {}
  Future<void> unregisterFcmToken(String memberId, String token) async {}
}
