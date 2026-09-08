import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../language_service.dart';
import '../models/visitor.dart';
import '../providers/member_session_provider.dart';
import '../services/visitor_service.dart';
import '../widgets/custom_numeric_date_picker.dart';

/// Visitor registration form where logged-in members can invite/register new visitors.
/// Styled to match the Become a Member registration form.
class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key});

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _memberNameController;
  final _visitorNameController = TextEditingController();
  final _visitorPhoneController = TextEditingController();
  final _productsServicesController = TextEditingController();
  final _visitorCompanyController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDob;
  bool _isSubmitting = false;

  String t(String key) => LanguageService.translate(key);

  @override
  void initState() {
    super.initState();
    final currentMember = context.read<MemberSessionProvider>().currentMember;
    _memberNameController = TextEditingController(text: currentMember?.fullName ?? "");
  }

  @override
  void dispose() {
    _memberNameController.dispose();
    _visitorNameController.dispose();
    _visitorPhoneController.dispose();
    _productsServicesController.dispose();
    _visitorCompanyController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final currentMember = context.read<MemberSessionProvider>().currentMember;
    if (currentMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please log in again.")),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please select a Date of Birth")),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final visitor = Visitor(
        visitorName: _visitorNameController.text.trim(),
        phone: _visitorPhoneController.text.trim(),
        productsOrServices: _productsServicesController.text.trim(),
        companyName: _visitorCompanyController.text.trim(),
        inviteById: currentMember.docId,
        inviteByName: currentMember.fullName,
        inviteByRID: currentMember.ridNo,
        dateOfBirth: _formatDate(_selectedDob!),
        visitDate: _selectedDate,
        source: 'visitor',
      );

      await VisitorService().submitVisitor(visitor);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Visitor submitted successfully!")),
          backgroundColor: AppTheme.success,
        ),
      );

      _visitorNameController.clear();
      _visitorPhoneController.clear();
      _productsServicesController.clear();
      _visitorCompanyController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedDob = null;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to submit visitor. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = context.watch<MemberSessionProvider>().currentMember;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        title: Text(
          t("Visitor Form"),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ),
      ),
      body: currentMember == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Card container holding the form
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
                          // Your Name (Logged in member - Readonly)
                          Text(
                            t("Your Name"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _memberNameController,
                            readOnly: true,
                            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 15),
                            decoration: InputDecoration(
                              fillColor: const Color(0xFFF3F4F6),
                              filled: true,
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1st: Visit Date
                          Text(
                            t("Visit Date"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDate,
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
                                    _formatDate(_selectedDate),
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // DOB
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
                                    _selectedDob == null ? t("Select Date of Birth") : _formatDate(_selectedDob!),
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

                          // 2nd: Visitor Name
                          Text(
                            t("Visitor Name"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _visitorNameController,
                            style: GoogleFonts.outfit(fontSize: 15),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              hintText: t("Enter visitor name"),
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
                                return t("Please enter visitor's name");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3rd: Company Name
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
                            controller: _visitorCompanyController,
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

                          // 4th: Contact No
                          Text(
                            t("Contact No"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _visitorPhoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.outfit(fontSize: 15),
                            maxLength: 10,
                            decoration: InputDecoration(
                              counterText: "",
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

                          // 5th: Products / Services
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
                            decoration: InputDecoration(
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
                          const SizedBox(height: 24),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
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
                                    t("Submit Visitor"),
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
