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

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _meetingService = MeetingService();
  bool _isSubmitting = false;

  String _formatDate(String rawDate) {
    final parts = rawDate.split("-");
    if (parts.length == 3) {
      return "${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}";
    }
    return rawDate;
  }

  /// Leave may only be applied/cancelled up until 4:30 PM the day before the
  /// meeting — parses meetingDate ("YYYY-MM-DD") and returns that cutoff.
  DateTime? _leaveCutoff(String meetingDate) {
    final parts = meetingDate.split("-");
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day)
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 16, minutes: 30));
  }

  Future<void> _toggleLeave({
    required Meeting meeting,
    required bool isLeaveApplied,
    required String memberId,
    required String memberName,
    required String ridNo,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      if (isLeaveApplied) {
        await _meetingService.cancelLeave(meeting.docId, memberId);
      } else {
        await _meetingService.applyLeave(
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
            isLeaveApplied ? "Leave Cancelled!" : "Leave Applied!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: isLeaveApplied ? AppTheme.error : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
        title: Text(t("Apply Leave")),
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
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : StreamBuilder<Meeting?>(
              stream: _meetingService.streamNextUpcoming(),
              builder: (context, meetingSnapshot) {
                if (meetingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: AnimatedSkeleton(width: double.infinity, height: 180, borderRadius: 16),
                  );
                }
                if (meetingSnapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${meetingSnapshot.error}",
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
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
                          const Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.textSecondary),
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

                final cutoff = _leaveCutoff(meeting.meetingDate);
                final isPastCutoff = cutoff != null && DateTime.now().isAfter(cutoff);
                final memberId = member.uid;
                final memberName = member.fullName;
                final ridNo = member.ridNo;

                return StreamBuilder<AttendanceRecord?>(
                  stream: _meetingService.streamMyAttendance(meeting.docId, memberId),
                  builder: (context, attendanceSnapshot) {
                    final isLeaveApplied = attendanceSnapshot.data?.status == 'leave';
                    final canToggle = !isPastCutoff && !_isSubmitting;

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
                              )
                            ],
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.08),
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
                                    if (isLeaveApplied)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          t("Leave Applied"),
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
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
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
                                    const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
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
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
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

                                // Apply / Cancel Leave action button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: canToggle
                                      ? () => _toggleLeave(
                                            meeting: meeting,
                                            isLeaveApplied: isLeaveApplied,
                                            memberId: memberId,
                                            memberName: memberName,
                                            ridNo: ridNo,
                                          )
                                      : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLeaveApplied ? AppTheme.error : AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      disabledForegroundColor: Colors.grey.shade600,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(
                                            t(isLeaveApplied ? "Cancel Leave" : "Apply Leave"),
                                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                                if (isPastCutoff) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    t("Leave window closed — this can no longer be changed for this meeting."),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ] else if (cutoff != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    t("Leave can be applied or cancelled until 4:30 PM the day before the meeting."),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
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
