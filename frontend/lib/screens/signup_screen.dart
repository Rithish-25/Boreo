import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../models/visitor.dart';
import '../services/member_service.dart';
import '../services/visitor_service.dart';
import '../widgets/searchable_member_dropdown.dart';
import '../widgets/custom_numeric_date_picker.dart';

/// Membership application form for prospective Boreo members. Writes submitted
/// applications directly to standalone visitor service and prompts user to wait for management approval.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _productsServicesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _memberService = MemberService();

  DateTime? _selectedDate;
  DateTime? _selectedDob;
  String? _selectedInvitedById;
  String? _selectedInvitedByName;
  String? _selectedInvitedByRID;
  bool _isSubmitting = false;

  String t(String key) => LanguageService.translate(key);

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _productsServicesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectDob(BuildContext context) async {
    final now = DateTime.now();
    DateTime selectedDate = _selectedDob ?? DateTime(now.year - 30, now.month, now.day);
    bool isSaved = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return Container(
          height: 340,
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t("Select Date of Birth"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        isSaved = true;
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(t('Done'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.border),
              Expanded(
                child: CustomNumericDatePicker(
                  initialDate: selectedDate,
                  minYear: now.year - 100,
                  maxDate: now,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (isSaved) {
      setState(() {
        _selectedDob = selectedDate;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please select date")),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please select your Date of Birth")),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_selectedInvitedById == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please select who invited you")),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formattedDob =
          "${_selectedDob!.year.toString()}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}";

      final visitor = Visitor(
        visitorName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        productsOrServices: _productsServicesController.text.trim(),
        companyName: _companyController.text.trim(),
        inviteById: _selectedInvitedById!,
        inviteByName: _selectedInvitedByName!,
        inviteByRID: _selectedInvitedByRID!,
        dateOfBirth: formattedDob,
        visitDate: _selectedDate,
        source: 'signup',
      );

      await VisitorService().submitVisitor(visitor);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            t("Application Submitted"),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          // content: Text(
          //   t("Your membership application has been submitted successfully. Please wait for management approval."),
          //   style: GoogleFonts.outfit(),
          // ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                t("OK"),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to submit application. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Member>>(
          stream: _memberService.streamActiveMembers(),
          builder: (context, snapshot) {
            final members = snapshot.data ?? const [];
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t("Become a member"),
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t("Enter your business details to apply for Boreo membership"),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Main card container holding the form inputs
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          Text(
                            t("Full Name"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.outfit(fontSize: 15),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              hintText: t("Enter full name"),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return t("Please enter full name");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date
                          Text(
                            t("Date"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? t("Select Date")
                                        : "${_selectedDate!.year.toString()}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: _selectedDate == null ? Colors.grey.shade400 : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Date of Birth
                          Text(
                            t("Date of Birth"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDob(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cake_outlined, size: 20, color: AppTheme.textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDob == null
                                        ? t("Select Date of Birth")
                                        : "${_selectedDob!.year.toString()}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: _selectedDob == null ? Colors.grey.shade400 : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Company Name
                          Text(
                            t("Company Name"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _companyController,
                            style: GoogleFonts.outfit(fontSize: 15),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.corporate_fare_outlined, size: 20),
                              hintText: t("Enter company name (optional)"),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Products / Services
                          Text(
                            t("Products / Services"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _productsServicesController,
                            style: GoogleFonts.outfit(fontSize: 15),
                            maxLength: 10,
                            decoration: InputDecoration(
                              counterText: "",
                              prefixIcon: const Icon(Icons.business_outlined, size: 20),
                              hintText: t("Enter products or services"),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return t("Please enter products or services");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number
                          Text(
                            t("Mobile Number"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.outfit(fontSize: 15),
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                child: Text(
                                  "+91 |",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                ),
                              ),
                              hintText: t("Enter 10-digit number"),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return t("Please enter mobile number");
                              }
                              if (val.trim().length != 10) {
                                return t("Please enter a valid 10-digit mobile number");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Invited By Dropdown
                          Text(
                            t("Invited By"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SearchableMemberDropdown(
                            value: _selectedInvitedById,
                            members: members,
                            hintText: t("Select Member"),
                            onChanged: (id) {
                              setState(() {
                                _selectedInvitedById = id;
                                final selectedMember = members.firstWhere((m) => m.docId == id);
                                _selectedInvitedByName = selectedMember.fullName;
                                _selectedInvitedByRID = selectedMember.ridNo;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    t("Register & Verify"),
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
