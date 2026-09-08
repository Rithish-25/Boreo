import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../models/face_to_face.dart';
import '../providers/member_session_provider.dart';
import '../services/member_service.dart';
import '../widgets/searchable_member_dropdown.dart';
import '../services/face_to_face_service.dart';
import 'face_to_face_history_screen.dart';
import '../widgets/skeleton.dart';


class FaceToFaceFormScreen extends StatefulWidget {
  const FaceToFaceFormScreen({super.key});

  @override
  State<FaceToFaceFormScreen> createState() => _FaceToFaceFormScreenState();
}

class _FaceToFaceFormScreenState extends State<FaceToFaceFormScreen> {
  final MemberService _memberService = MemberService();
  final FaceToFaceService _faceToFaceService = FaceToFaceService();

  late final TextEditingController _nameController;
  late final TextEditingController _officeController;
  String? _selectedMemberId;
  String? _selectedMemberName;
  String? _memberError;
  String _meetingAt = "From Member Office";

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentMember = context.read<MemberSessionProvider>().currentMember;
    _nameController = TextEditingController(
      text: currentMember?.fullName ?? "",
    );
    _officeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  String _getCurrentTerm() {
    final month = DateTime.now().month;
    return month <= 6 ? "Term 1" : "Term 2";
  }

  Future<void> _submitForm() async {
    final currentMember = context.read<MemberSessionProvider>().currentMember;
    if (currentMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to determine your member profile. Please log in again.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_selectedMemberId == null || _selectedMemberName == null) {
      setState(
        () => _memberError = "Please select whom you are doing Face to Face with!",
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final entry = FaceToFace(
        fromMemberUid: currentMember.docId,
        fromMemberName: currentMember.fullName,
        toMemberUid: _selectedMemberId!,
        toMemberName: _selectedMemberName!,
        term: _getCurrentTerm(),
        meetingAt: _meetingAt,
      );
      await _faceToFaceService.create(entry);
      if (!mounted) return;
      setState(() {
        _selectedMemberId = null;
        _selectedMemberName = null;
        _officeController.clear();
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Face to Face Form submitted successfully!",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to submit Face to Face. Please try again.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = context.watch<MemberSessionProvider>().currentMember;

    if (currentMember == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
          title: Text(t("Face to Face Form")),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: Colors.white24, height: 1.0),
          ),
        ),
        body: _buildSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        title: Text(t("Face to Face Form")),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<MemberSessionProvider>().refreshCurrentMember();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your Name field
              Text(
                t("Your Name"),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                readOnly: true,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  fillColor: const Color(0xFFF3F4F6),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Whom are you doing Face to Face with
              Text(
                t("Whom are you doing Face to Face with?"),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Member>>(
                stream: _memberService.streamActiveMembers(),
                builder: (context, snapshot) {
                  final hasError = snapshot.hasError;
                  final isLoading = !hasError && !snapshot.hasData;
                  final members = (snapshot.data ?? const <Member>[])
                      .where((m) => m.docId != currentMember.docId)
                      .toList();

                  // Drop a previously selected partner if they're no longer
                  // in the (filtered) list, e.g. active-members stream update.
                  if (_selectedMemberId != null &&
                      !isLoading &&
                      !members.any((m) => m.docId == _selectedMemberId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedMemberId = null;
                          _selectedMemberName = null;
                          _officeController.clear();
                        });
                      }
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchableMemberDropdown(
                        value: _selectedMemberId,
                        hintText: hasError
                            ? t("Failed to load members")
                            : isLoading
                            ? t("Loading members...")
                            : t("Select member"),
                        members: members,
                        errorText: _memberError,
                        onChanged: (hasError || isLoading)
                            ? (val) {} // Do nothing if loading or error
                            : (val) {
                                if (val == null) return;
                                final member = members.firstWhere(
                                  (m) => m.docId == val,
                                );
                                setState(() {
                                  _selectedMemberId = val;
                                  _selectedMemberName = member.fullName;
                                  _officeController.text = member.companyName;
                                  _memberError = null;
                                });
                              },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t("Where did this meeting happen?"),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Text("${currentMember.fullName}'s Office", style: GoogleFonts.outfit(fontSize: 14)),
                              value: "From Member Office",
                              groupValue: _meetingAt,
                              activeColor: AppTheme.primary,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _meetingAt = value);
                                }
                              },
                            ),
                            const Divider(height: 1, color: AppTheme.border),
                            RadioListTile<String>(
                              title: Text(
                                _selectedMemberName != null ? "${_selectedMemberName}'s Office" : t("Partner's Office"),
                                style: GoogleFonts.outfit(fontSize: 14),
                              ),
                              value: "To Member Office",
                              groupValue: _meetingAt,
                              activeColor: AppTheme.primary,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _meetingAt = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          t("Submit Face to Face"),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceToFaceHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    t("View History"),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AnimatedSkeleton(width: 100, height: 16),
          SizedBox(height: 8),
          AnimatedSkeleton(
            width: double.infinity,
            height: 48,
            borderRadius: 10,
          ),
          SizedBox(height: 24),
          AnimatedSkeleton(width: 200, height: 16),
          SizedBox(height: 8),
          AnimatedSkeleton(
            width: double.infinity,
            height: 48,
            borderRadius: 10,
          ),
          SizedBox(height: 24),
          AnimatedSkeleton(width: 120, height: 16),
          SizedBox(height: 8),
          AnimatedSkeleton(
            width: double.infinity,
            height: 48,
            borderRadius: 10,
          ),
          SizedBox(height: 40),
          AnimatedSkeleton(
            width: double.infinity,
            height: 50,
            borderRadius: 10,
          ),
          SizedBox(height: 24),
          AnimatedSkeleton(
            width: double.infinity,
            height: 50,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}
