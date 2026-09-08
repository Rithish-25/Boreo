import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../models/thank_note.dart';
import '../models/referral.dart';
import '../services/member_service.dart';
import '../services/thank_note_service.dart';
import '../widgets/searchable_member_dropdown.dart';
import '../services/referral_service.dart';
import '../services/attendance_error.dart';
import '../providers/member_session_provider.dart';
import 'thanks_note_history_screen.dart';
import '../widgets/skeleton.dart';

class ThanksNoteScreen extends StatefulWidget {
  const ThanksNoteScreen({super.key});

  @override
  State<ThanksNoteScreen> createState() => _ThanksNoteScreenState();
}

class _ThanksNoteScreenState extends State<ThanksNoteScreen> {
  final MemberService _memberService = MemberService();
  final ThankNoteService _thankNoteService = ThankNoteService();
  final ReferralService _referralService = ReferralService();

  final _amountController = TextEditingController();

  StreamSubscription<List<Member>>? _membersSub;
  List<Member> _activeMembers = [];

  bool _isReferral = true;
  bool _isSubmitting = false;

  // Referral form state
  String _referralType = "self"; // "self" | "connect"
  String? _selectedReferredMemberId;
  final TextEditingController _connectorNameController =
      TextEditingController();

  // Thank You note form state
  String _thankNoteType = "direct";
  String? _selectedToMemberId;
  final TextEditingController _thankNoteConnectorController =
      TextEditingController();

  // Validation Error States
  String? _referredMemberError;
  String? _connectorNameError;
  String? _thankNoteConnectorError;
  String? _toMemberError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _membersSub = _memberService.streamActiveMembers().listen((members) {
      if (mounted) setState(() => _activeMembers = members);
    });
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _amountController.dispose();
    _connectorNameController.dispose();
    _thankNoteConnectorController.dispose();
    super.dispose();
  }

  Member? _memberById(String? id) {
    if (id == null) return null;
    for (final m in _activeMembers) {
      if (m.docId == id) return m;
    }
    return null;
  }

  List<Member> _selectableMembers(String currentMemberId) {
    return _activeMembers.where((m) => m.docId != currentMemberId).toList();
  }

  void _showSnack(
    ScaffoldMessengerState messenger,
    String message,
    Color color,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success
                  ? Icons.check_circle
                  : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  void _resetForm() {
    _amountController.clear();
    _connectorNameController.clear();
    _thankNoteConnectorController.clear();
    _referralType = "self";
    _thankNoteType = "direct";
    _selectedReferredMemberId = null;
    _selectedToMemberId = null;
    _clearErrors();
  }

  void _clearErrors() {
    setState(() {
      _referredMemberError = null;
      _connectorNameError = null;
      _thankNoteConnectorError = null;
      _toMemberError = null;
      _amountError = null;
    });
  }

  String _formatDetailDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayTime(DateTime dt) {
    final period = dt.hour >= 12 ? "PM" : "AM";
    var hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour12:$minute $period";
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final member = context.read<MemberSessionProvider>().currentMember;
    if (member == null) {
      _showSnack(messenger, "You must be logged in to submit.", AppTheme.error);
      return;
    }
    if (_isReferral) {
      await _submitReferral(member, messenger);
    } else {
      await _submitThankNote(member, messenger);
    }
  }

  Future<void> _submitReferral(
    Member member,
    ScaffoldMessengerState messenger,
  ) async {
    _clearErrors();
    bool hasError = false;

    final referredMember = _memberById(_selectedReferredMemberId);
    if (referredMember == null) {
      setState(() => _referredMemberError = "Please select a member!");
      hasError = true;
    }

    if (_referralType == "connect" &&
        _connectorNameController.text.trim().isEmpty) {
      setState(
        () =>
            _connectorNameError = "Please provide a Connection Name or Details",
      );
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isSubmitting = true);
    try {
      final referral = Referral(
        type: _referralType,
        referrerId: member.docId,
        referrerName: member.fullName,
        connectorId: null,
        connectorName: _referralType == "connect"
            ? _connectorNameController.text.trim()
            : null,
        referredUserId: referredMember!.docId,
        referredUserName: referredMember.fullName,
        createdBy: member.docId,
        createdByName: member.fullName,
      );
      await _referralService.create(referral);
      if (!mounted) return;
      setState(_resetForm);
      _showSnack(
        messenger,
        "Referral successfully submitted!",
        AppTheme.success,
      );
    } on ServiceError catch (e) {
      _showSnack(messenger, e.message, AppTheme.error);
    } catch (e) {
      _showSnack(
        messenger,
        "Failed to submit referral. Please try again.",
        AppTheme.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitThankNote(
    Member member,
    ScaffoldMessengerState messenger,
  ) async {
    _clearErrors();
    bool hasError = false;

    final toMember = _memberById(_selectedToMemberId);
    if (toMember == null) {
      setState(() => _toMemberError = "Please select a member!");
      hasError = true;
    }

    if (_thankNoteType == "connect" &&
        _thankNoteConnectorController.text.trim().isEmpty) {
      setState(
        () => _thankNoteConnectorError =
            "Please provide a Connection Name or Details",
      );
      hasError = true;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      setState(() => _amountError = "Please fill in the business amount!");
      hasError = true;
    } else {
      final amount = double.tryParse(amountStr.replaceAll(",", ""));
      if (amount == null || amount <= 0) {
        setState(
          () => _amountError = "Please enter a valid numeric business amount!",
        );
        hasError = true;
      }
    }

    if (hasError) return;

    final amount = double.tryParse(amountStr.replaceAll(",", ""))!;

    setState(() => _isSubmitting = true);
    try {
      final now = DateTime.now();
      final note = ThankNote(
        type: _thankNoteType,
        connectorName: _thankNoteType == "connect"
            ? _thankNoteConnectorController.text.trim()
            : null,
        fromUserId: member.docId,
        fromName: member.fullName,
        toUserId: toMember!.docId,
        toName: toMember.fullName,
        message: "",
        value: amount,
        detailDate: _formatDetailDate(now),
        displayTime: _formatDisplayTime(now),
      );
      await _thankNoteService.create(note);
      if (!mounted) return;
      setState(_resetForm);
      _showSnack(
        messenger,
        "Thanks Note successfully submitted!",
        AppTheme.success,
      );
    } catch (e) {
      _showSnack(
        messenger,
        "Failed to submit thanks note. Please try again.",
        AppTheme.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = context.watch<MemberSessionProvider>().currentMember;

    if (currentMember == null) {
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MemberSessionProvider>().refreshCurrentMember();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsHeader(currentMember.docId),
            const SizedBox(height: 20),
            _buildForm(currentMember),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThanksNoteHistoryScreen(
                            initialFilter: "Referal",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      t("View Referral"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEA580C),
                      side: const BorderSide(color: Color(0xFFEA580C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThanksNoteHistoryScreen(
                            initialFilter: "Thanks Note",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      t("View Thanksnote"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(String memberId) {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: StreamBuilder<List<ThankNote>>(
                stream: _thankNoteService.streamReceivedByMember(memberId),
                builder: (context, snapshot) {
                  final thisMonthNotes = (snapshot.data ?? const <ThankNote>[]).where((n) {
                    if (n.createdAt == null) return false;
                    return n.createdAt!.year == now.year && n.createdAt!.month == now.month;
                  });
                  final total = thisMonthNotes.fold<double>(0, (sum, n) => sum + n.value);
                  return _buildStatColumn(
                    icon: Icons.credit_card,
                    iconColor: AppTheme.success,
                    label: t("Month Given"),
                    value: "₹ ${_formatCurrency(total)}",
                  );
                },
              ),
            ),
            Container(height: 40, width: 1, color: AppTheme.border),
            Expanded(
              child: StreamBuilder<List<ThankNote>>(
                stream: _thankNoteService.streamForMember(memberId),
                builder: (context, snapshot) {
                  final thisMonthNotes = (snapshot.data ?? const <ThankNote>[]).where((n) {
                    if (n.createdAt == null) return false;
                    return n.createdAt!.year == now.year && n.createdAt!.month == now.month;
                  });
                  final total = thisMonthNotes.fold<double>(0, (sum, n) => sum + n.value);
                  return _buildStatColumn(
                    icon: Icons.receipt_long,
                    iconColor: AppTheme.primary,
                    label: t("Month Taken"),
                    value: "₹ ${_formatCurrency(total)}",
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(Member currentMember) {
    final selectable = _selectableMembers(currentMember.docId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t("Add Thanksnote"),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Segmented Slide Toggle Switch
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: _isReferral
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _isReferral ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isReferral = true);
                            _clearErrors();
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: _isReferral
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t("Referal"),
                                  style: TextStyle(
                                    color: _isReferral
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isReferral = false);
                            _clearErrors();
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: !_isReferral
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t("Thank You note"),
                                  style: TextStyle(
                                    color: !_isReferral
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isReferral)
              ..._buildReferralFields(selectable)
            else
              ..._buildThankNoteFields(selectable),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReferral ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t(_isReferral ? "Submit Referal" : "Submit Thanksnote"),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReferralFields(List<Member> selectable) {
    return [
      // Referral Type dropdown — restricted to Self / Connect only, matching
      // what firestore.rules accepts for the referrals collection.
      DropdownButtonFormField<String>(
        value: _referralType,
        items: [
          DropdownMenuItem(
            value: "self",
            child: Text(
              t("Self"),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          DropdownMenuItem(
            value: "connect",
            child: Text(
              t("Connect"),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
        onChanged: (val) {
          setState(() {
            _referralType = val ?? "self";
            if (_referralType != "connect") {
              _connectorNameController.clear();
            }
          });
        },
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
        decoration: InputDecoration(
          labelText: t("Referral Type"),
          labelStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Referred member dropdown
      _buildMemberDropdown(
        value: _selectedReferredMemberId,
        members: selectable,
        onChanged: (val) => setState(() {
          _selectedReferredMemberId = val;
          if (val != null) _referredMemberError = null;
        }),
        errorText: _referredMemberError,
      ),

      if (_referralType == "connect") ...[
        const SizedBox(height: 12),
        TextField(
          controller: _connectorNameController,
          onChanged: (val) {
            if (val.trim().isNotEmpty && _connectorNameError != null) {
              setState(() => _connectorNameError = null);
            }
          },
          decoration: InputDecoration(
            hintText: t("Connection Name / Details"),
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            errorText: _connectorNameError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildThankNoteFields(List<Member> selectable) {
    return [
      DropdownButtonFormField<String>(
        value: _thankNoteType,
        items: [
          DropdownMenuItem(
            value: "direct",
            child: Text(
              t("Direct"),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          DropdownMenuItem(
            value: "connect",
            child: Text(
              t("Connect"),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
        onChanged: (val) {
          setState(() {
            _thankNoteType = val ?? "direct";
            if (_thankNoteType != "connect") {
              _thankNoteConnectorController.clear();
            }
          });
        },
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
        decoration: InputDecoration(
          labelText: t("Thanks Note Type"),
          labelStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Recipient member dropdown
      _buildMemberDropdown(
        value: _selectedToMemberId,
        members: selectable,
        onChanged: (val) => setState(() {
          _selectedToMemberId = val;
          if (val != null) _toMemberError = null;
        }),
        errorText: _toMemberError,
      ),

      if (_thankNoteType == "connect") ...[
        const SizedBox(height: 12),
        TextField(
          controller: _thankNoteConnectorController,
          onChanged: (val) {
            if (val.trim().isNotEmpty && _thankNoteConnectorError != null) {
              setState(() => _thankNoteConnectorError = null);
            }
          },
          decoration: InputDecoration(
            hintText: t("Connection Name / Details"),
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            errorText: _thankNoteConnectorError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
      ],

      const SizedBox(height: 12),

      // Business amount
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          if (val.trim().isNotEmpty && _amountError != null) {
            setState(() => _amountError = null);
          }
        },
        decoration: InputDecoration(
          hintText: t("Business Amount (₹)"),
          hintStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.currency_rupee,
            color: AppTheme.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          errorText: _amountError,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
    ];
  }

  Widget _buildMemberDropdown({
    required String? value,
    required List<Member> members,
    required ValueChanged<String?> onChanged,
    String? hintText,
    String? errorText,
  }) {
    return SearchableMemberDropdown(
      value: value,
      members: members,
      hintText: hintText ?? t("Select Member"),
      onChanged: onChanged,
      errorText: errorText,
    );
  }

  String _formatCurrency(double value) {
    String valStr = value.toInt().toString();
    if (valStr.length <= 3) return valStr;
    String lastThree = valStr.substring(valStr.length - 3);
    String remaining = valStr.substring(0, valStr.length - 3);

    String formattedRemaining = "";
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      formattedRemaining = remaining[i] + formattedRemaining;
      count++;
      if (count == 2 && i > 0) {
        formattedRemaining = ",$formattedRemaining";
        count = 0;
      }
    }
    return "$formattedRemaining,$lastThree";
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: AnimatedSkeleton(width: double.infinity, height: 40),
                  ),
                  Container(height: 40, width: 1, color: AppTheme.border),
                  const Expanded(
                    child: AnimatedSkeleton(width: double.infinity, height: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: const [
                AnimatedSkeleton(width: 150, height: 20),
                SizedBox(height: 16),
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 12,
                ),
                SizedBox(height: 16),
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 12,
                ),
                SizedBox(height: 16),
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 12,
                ),
                SizedBox(height: 20),
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AnimatedSkeleton(
            width: double.infinity,
            height: 50,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}
