import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/attendance_record.dart';
import '../models/meeting.dart';
import '../providers/member_session_provider.dart';
import '../services/meeting_service.dart';
import '../theme.dart';
import '../language_service.dart';
import '../widgets/skeleton.dart';

class EarlyGoingScreen extends StatefulWidget {
  const EarlyGoingScreen({super.key});

  @override
  State<EarlyGoingScreen> createState() => _EarlyGoingScreenState();
}

class _EarlyGoingScreenState extends State<EarlyGoingScreen> {
  final _meetingService = MeetingService();
  bool _isSubmitting = false;

  String _formatDate(String rawDate) {
    final parts = rawDate.split("-");
    if (parts.length == 3) {
      return "${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}";
    }
    return rawDate;
  }

  bool _isMeetingToday(String meetingDate) {
    final parts = meetingDate.split("-");
    if (parts.length != 3) {
      return false;
    }
    
    int? year, month, day;
    
    if (parts[0].length == 4) {
      year = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      day = int.tryParse(parts[2]);
    } else if (parts[2].length == 4) {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      year = int.tryParse(parts[2]);
    } else {
      return false;
    }

    if (year == null || month == null || day == null) return false;

    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool _isWithinTimeWindow() {
    final now = DateTime.now();
    final timeInMinutes = now.hour * 60 + now.minute;
    final startMinutes = 6 * 60 + 45; // 6:45 AM
    final endMinutes = 9 * 60; // 9:00 AM
    return timeInMinutes >= startMinutes && timeInMinutes <= endMinutes;
  }

  Future<void> _togglePermission({
    required Meeting meeting,
    required bool isPermissionApplied,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      if (isPermissionApplied) {
        await _meetingService.cancelPermission(meeting.docId, memberId);
      } else {
        await _meetingService.applyPermission(
          meetingId: meeting.docId,
          meetingDate: meeting.meetingDate,
          memberId: memberId,
          memberName: memberName,
          ridNo: ridNo,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermissionApplied
                ? t("Permission Cancelled!")
                : t("Permission Applied!"),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: isPermissionApplied
              ? AppTheme.error
              : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          width: 180,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Something went wrong. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = context.watch<MemberSessionProvider>().currentMember;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        title: Text(t("Early Going")),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ),
      ),
      body: member == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : StreamBuilder<Meeting?>(
              stream: _meetingService.streamNextUpcoming(),
              builder: (context, meetingSnapshot) {
                if (meetingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: AnimatedSkeleton(
                      width: double.infinity,
                      height: 180,
                      borderRadius: 16,
                    ),
                  );
                }
                if (meetingSnapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${meetingSnapshot.error}",
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                final meeting = meetingSnapshot.data;
                if (meeting == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy_outlined,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t("No upcoming regular meetings"),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isMeetingToday = _isMeetingToday(meeting.meetingDate);
                final isWithinWindow = _isWithinTimeWindow();

                if (!isMeetingToday || !isWithinWindow) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              "Early going requests can only be made on the meeting day between 6:45 AM and 9:00 AM.",
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final memberId = member.uid;
                final memberName = member.fullName;
                final ridNo = member.ridNo;

                return StreamBuilder<AttendanceRecord?>(
                  stream: _meetingService.streamMyAttendance(meeting.docId, memberId),
                  builder: (context, attendanceSnapshot) {
                    final isPermissionApplied =
                        attendanceSnapshot.data?.status == 'permission';
                    final canToggle = !_isSubmitting && isWithinWindow;

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        t("Regular Meet"),
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isPermissionApplied)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          t("Permission Applied"),
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.success,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  meeting.meetingName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(meeting.meetingDate),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      meeting.meetingTime,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (meeting.place.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          meeting.place,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 20),
                                const Divider(height: 1),
                                const SizedBox(height: 16),

                                // Apply / Cancel Permission action button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: canToggle
                                        ? () => _togglePermission(
                                            meeting: meeting,
                                            isPermissionApplied:
                                                isPermissionApplied,
                                            memberId: memberId,
                                            memberName: memberName,
                                            ridNo: ridNo,
                                          )
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPermissionApplied
                                          ? AppTheme.error
                                          : AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      disabledForegroundColor:
                                          Colors.grey.shade600,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            t(
                                              isPermissionApplied
                                                  ? "Cancel Permission"
                                                  : "Apply Permission",
                                            ),
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  t(
                                    "Permission can be applied or cancelled between 6:45 AM and 9:00 AM today.",
                                  ),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
