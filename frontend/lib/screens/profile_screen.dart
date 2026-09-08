import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../providers/member_session_provider.dart';
import '../services/member_service.dart';
import '../widgets/custom_numeric_date_picker.dart';
import '../widgets/skeleton.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MemberService _memberService = MemberService();
  bool _isUploadingPhoto = false;

  Future<void> _pickProfileImage(Member member) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);
      await _memberService.uploadProfileImage(member.docId, File(image.path));
      if (!mounted) return;
      await context.read<MemberSessionProvider>().refreshCurrentMember();
      _showSnack("Profile photo updated successfully!", AppTheme.success);
    } catch (e) {
      _showSnack("Failed to update photo: $e", AppTheme.error);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        width: 280,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveField(String memberId, String label, String fieldKey, String value) async {
    try {
      await _memberService.updateProfile(memberId, {fieldKey: value});
      if (!mounted) return;
      await context.read<MemberSessionProvider>().refreshCurrentMember();
      _showSnack("$label updated successfully!", AppTheme.success);
    } catch (e) {
      _showSnack("Failed to update $label: $e", AppTheme.error);
    }
  }

  Future<void> _editTextField({
    required String memberId,
    required String label,
    required String fieldKey,
    required String currentValue,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit $label",
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
            maxLength: label == "Rotary ID"
                ? 8
                : ((label == "Mobile Number" || label == "WhatsApp Number") ? 10 : null),
            autofocus: true,
            minLines: maxLines,
            maxLines: maxLines,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Enter $label",
              counterText: "",
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              errorMaxLines: 2,
            ),
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      await _saveField(memberId, label, fieldKey, result);
    }
  }

  Future<void> _editDateField({
    required String memberId,
    required String label,
    required String fieldKey,
    required String currentValue,
  }) async {
    DateTime? initialDate;
    try {
      if (currentValue.isNotEmpty) {
        final parts = currentValue.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          final partsSlash = currentValue.split('/');
          if (partsSlash.length == 3) {
            initialDate = DateTime(int.parse(partsSlash[2]), int.parse(partsSlash[1]), int.parse(partsSlash[0]));
          }
        }
      }
    } catch (_) {}

    final now = DateTime.now();
    DateTime selectedDate = initialDate ?? DateTime(now.year - 30, now.month, now.day);
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
              // Subtle Drag Handle
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select $label",
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
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.border),
              // Custom Numeric Picker
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
      final formatted =
          "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      if (formatted != currentValue) {
        await _saveField(memberId, label, fieldKey, formatted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MemberSessionProvider>().currentMember;

    if (user == null) {
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MemberSessionProvider>().refreshCurrentMember();
      },
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profile Avatar with edit upload functionality
          GestureDetector(
            onTap: _isUploadingPhoto ? null : () => _pickProfileImage(user),
            child: Stack(
              children: [
                MemberAvatar(
                  name: user.fullName,
                  radius: 55,
                  profileImage: user.profileImage,
                ),
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Power Team
          if (user.powerTeam.isNotEmpty) ...[
            Text(
              user.powerTeam.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Name and Tagline
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.companyName,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Position
          if (user.position.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.position,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primary.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Profile Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.phone_iphone_outlined,
                      "Mobile Number",
                      user.phone,
                      onEdit: () => _editTextField(
                        memberId: user.docId,
                        label: "Mobile Number",
                        fieldKey: "phone",
                        currentValue: user.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Mobile number cannot be empty";
                          }
                          if (!RegExp(r'^[1-9]\d{9}$').hasMatch(value.trim())) {
                            return "10 digits only, cannot start with 0";
                          }
                          return null;
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.chat_outlined,
                      "WhatsApp Number",
                      user.whatsappNumber,
                      iconColor: Colors.green,
                      onEdit: () => _editTextField(
                        memberId: user.docId,
                        label: "WhatsApp Number",
                        fieldKey: "whatsappNumber",
                        currentValue: user.whatsappNumber,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[1-9]\d{9}$').hasMatch(value.trim())) {
                              return "10 digits only, cannot start with 0";
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.card_membership_outlined,
                      "Rotary ID",
                      user.ridNo,
                      iconColor: Colors.blueAccent,
                      onEdit: () => _editTextField(
                        memberId: user.docId,
                        label: "Rotary ID",
                        fieldKey: "ridNo",
                        currentValue: user.ridNo,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Rotary ID cannot be empty";
                          }
                          if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) {
                            return "8 digits only";
                          }
                          return null;
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.cake_outlined,
                      "Date of Birth",
                      user.dateOfBirth,
                      onEdit: () => _editDateField(
                        memberId: user.docId,
                        label: "Date of Birth",
                        fieldKey: "dateOfBirth",
                        currentValue: user.dateOfBirth,
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.favorite_border_outlined,
                      "Wedding Date",
                      user.wedding,
                      iconColor: Colors.pinkAccent,
                      onEdit: () => _editDateField(
                        memberId: user.docId,
                        label: "Wedding Date",
                        fieldKey: "wedding",
                        currentValue: user.wedding,
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.bloodtype_outlined,
                      "Blood Group",
                      user.bloodGroup,
                      iconColor: Colors.redAccent,
                      onEdit: () => _editTextField(
                        memberId: user.docId,
                        label: "Blood Group",
                        fieldKey: "bloodGroup",
                        currentValue: user.bloodGroup,
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.storefront_outlined,
                      "Company Open Day",
                      user.businessStartDate,
                      onEdit: () => _editDateField(
                        memberId: user.docId,
                        label: "Company Open Day",
                        fieldKey: "businessStartDate",
                        currentValue: user.businessStartDate,
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      "Office Address",
                      user.businessAddress,
                      onEdit: () => _editTextField(
                        memberId: user.docId,
                        label: "Office Address",
                        fieldKey: "businessAddress",
                        currentValue: user.businessAddress,
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    t("Logout"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  );
}

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const AnimatedSkeleton(width: 110, height: 110, borderRadius: 55),
          const SizedBox(height: 16),
          const AnimatedSkeleton(width: 120, height: 12),
          const SizedBox(height: 4),
          const AnimatedSkeleton(width: 200, height: 24),
          const SizedBox(height: 4),
          const AnimatedSkeleton(width: 150, height: 14),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.12)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(5, (index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const AnimatedSkeleton(width: 36, height: 36, borderRadius: 8),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  AnimatedSkeleton(width: 100, height: 12),
                                  SizedBox(height: 4),
                                  AnimatedSkeleton(width: 150, height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < 4) const Divider(height: 1, thickness: 0.8, color: AppTheme.border),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedSkeleton(width: double.infinity, height: 50, borderRadius: 12),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color iconColor = AppTheme.textSecondary,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(label),
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? "Not set" : value,
                  style: GoogleFonts.outfit(
                    color: value.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
              onPressed: onEdit,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
