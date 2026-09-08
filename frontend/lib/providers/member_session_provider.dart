import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import '../services/member_service.dart';

class MemberSessionProvider extends ChangeNotifier {
  MemberSessionProvider({MemberService? memberService})
      : _memberService = memberService ?? MemberService();

  static const _memberIdKey = 'memberId';

  final MemberService _memberService;

  Member? _currentMember;
  bool _isLoading = true;

  Member? get currentMember => _currentMember;
  bool get isLoggedIn => _currentMember != null;
  bool get isLoading => _isLoading;

  Future<void> restoreSession() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString(_memberIdKey);
    if (memberId != null) {
      final member = await _memberService.getById(memberId);
      if (member != null && member.isActive) {
        _currentMember = member;
      } else {
        await prefs.remove(_memberIdKey);
        _currentMember = null;
      }
    } else {
      // Auto login as default member m1 if no session exists for immediate demo preview
      final defaultMember = await _memberService.getById("m1");
      if (defaultMember != null) {
        _currentMember = defaultMember;
        await prefs.setString(_memberIdKey, "m1");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String phone, String dateOfBirth) async {
    final member = await _memberService.getByPhoneAndDob(phone, dateOfBirth);
    if (member != null) {
      if (!member.isActive) {
        return "Your access has been revoked.";
      }
      return await _completeLogin(member.docId, member);
    }

    return "Invalid Credentials";
  }

  Future<String?> _completeLogin(String id, Member m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memberIdKey, id);
    _currentMember = m;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memberIdKey);
    _currentMember = null;
    notifyListeners();
  }

  Future<void> refreshCurrentMember() async {
    final member = _currentMember;
    if (member == null) return;
    final refreshed = await _memberService.getById(member.docId);
    if (refreshed != null) {
      _currentMember = refreshed;
      notifyListeners();
    }
  }
}
