import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';

class FeedbackItem {
  final String authorName;
  final String content;
  final DateTime date;
  final int rating;

  FeedbackItem({
    required this.authorName,
    required this.content,
    required this.date,
    required this.rating,
  });
}

class MemberDetailsScreen extends StatefulWidget {
  final Member member;
  const MemberDetailsScreen({super.key, required this.member});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  int _userRating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  final List<FeedbackItem> _feedbackList = [];
  bool _isPersonal = true;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t("Please enter feedback before submitting"),
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _feedbackList.insert(
        0,
        FeedbackItem(
          authorName: "You",
          content: text,
          date: DateTime.now(),
          rating: _userRating,
        ),
      );
      _feedbackController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t("Feedback submitted successfully!"),
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Text(t("Member Details")),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    MemberAvatar(
                      name: m.fullName,
                      radius: 45,
                      profileImage: m.profileImage,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      m.fullName.isEmpty ? "N/A" : m.fullName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.companyName.isEmpty ? "N/A" : m.companyName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (m.powerTeam.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.powerTeam.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (m.phone.isNotEmpty) {
                              final url = Uri.parse('tel:${m.phone}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            }
                          },
                          icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                          label: const Text("Call"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final waNumber = m.whatsappNumber.isNotEmpty ? m.whatsappNumber : m.phone;
                            if (waNumber.isNotEmpty) {
                              String formattedPhone = waNumber;
                              if (formattedPhone.length == 10) {
                                formattedPhone = "+91$formattedPhone";
                              }
                              final url = Uri.parse('https://wa.me/${formattedPhone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                          label: const Text("WhatsApp"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Selector
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPersonal = true),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _isPersonal ? AppTheme.primaryGradient : null,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          t("Personal"),
                          style: TextStyle(
                            color: _isPersonal ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPersonal = false),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: !_isPersonal ? AppTheme.primaryGradient : null,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          t("Business"),
                          style: TextStyle(
                            color: !_isPersonal ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isPersonal ? _buildPersonalInfo(m) : _buildBusinessInfo(m),
              ),
            ),
            const SizedBox(height: 20),

            // Rating Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t("Rating"),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = starValue <= _userRating;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? AppTheme.secondary : const Color(0xFFE5E7EB),
                          ),
                          onPressed: () {
                            setState(() {
                              _userRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    Center(
                      child: Text(
                        "$_userRating / 5 Stars",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feedback Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t("Previous Feedback"),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_feedbackList.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: Text(
                          t("No feedback yet"),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _feedbackList.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final item = _feedbackList[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.authorName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      item.rating,
                                      (r) => const Icon(Icons.star, size: 14, color: AppTheme.secondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.content,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 16),
                    Text(
                      t("Write Feedback"),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: t("Write your experience or feedback for this member..."),
                        hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.background,
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          t("Submit Feedback"),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(Member m) {
    return Column(
      children: [
        _buildRow(Icons.email_outlined, "Email", m.email),
        _buildRow(Icons.phone_outlined, "Phone", m.phone),
        _buildRow(Icons.bloodtype_outlined, "Blood Group", m.bloodGroup, iconColor: Colors.redAccent),
        _buildRow(Icons.person_outline, "Father Name", m.fatherName),
        _buildRow(Icons.favorite_border, "Spouse Name", m.wifeName),
        _buildRow(Icons.school_outlined, "Education", m.education),
        _buildRow(Icons.home_outlined, "Address", m.address),
      ],
    );
  }

  Widget _buildBusinessInfo(Member m) {
    return Column(
      children: [
        _buildRow(Icons.business_outlined, "Company Name", m.companyName),
        _buildRow(Icons.work_outline, "Business Type", m.businessType),
        _buildRow(Icons.location_on_outlined, "Business Address", m.businessAddress),
        _buildRow(Icons.call_outlined, "Office No", m.officeNo),
        _buildRow(Icons.language_outlined, "Website", m.websiteUrl),
        _buildRow(Icons.groups_outlined, "Power Team", m.powerTeam),
        _buildRow(Icons.badge_outlined, "Position", m.position),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {Color iconColor = AppTheme.textSecondary}) {
    final displayValue = value.trim().isEmpty ? "N/A" : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            t(label),
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: displayValue == "N/A" ? AppTheme.textSecondary : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
