import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../language_service.dart';
import 'calendar_screen.dart';
import 'news_events_screen.dart';
import 'thanks_note_history_screen.dart';
import '../providers/member_session_provider.dart';
import '../services/referral_service.dart';
import '../services/face_to_face_service.dart';
import '../services/thank_note_service.dart';
import '../services/meeting_service.dart';
import '../models/face_to_face.dart';
import '../models/thank_note.dart';
import '../models/referral.dart';
import '../models/member.dart';
import '../widgets/skeleton.dart';
import '../services/member_service.dart';
import '../widgets/special_events_popup.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToThanks;
  const HomeScreen({super.key, required this.onNavigateToThanks});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static bool _hasCheckedSpecialEvents = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    final member = context.read<MemberSessionProvider>().currentMember;
    final isVisitor = member?.status == 'visitor';

    if (member != null && !isVisitor) {
      _checkSpecialEvents();
    }
  }

  void _checkSpecialEvents() async {
    if (_hasCheckedSpecialEvents) return;
    _hasCheckedSpecialEvents = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastShown = prefs.getString('last_special_events_date');

      if (lastShown == todayStr) return;

      final members = await MemberService().streamActiveMembers().first;
      
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentDay = now.day;

      List<Member> birthdays = [];
      List<Member> anniversaries = [];
      List<Member> companyDays = [];

      bool isToday(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return false;
        try {
          final parts = dateStr.split('-');
          if (parts.length >= 3) {
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            return month == currentMonth && day == currentDay;
          }
        } catch (_) {}
        return false;
      }

      for (var member in members) {
        if (isToday(member.dateOfBirth)) birthdays.add(member);
        if (isToday(member.wedding)) anniversaries.add(member);
        if (isToday(member.businessStartDate)) companyDays.add(member);
      }

      if (birthdays.isNotEmpty || anniversaries.isNotEmpty || companyDays.isNotEmpty) {
        if (!mounted) return;
        await SpecialEventsPopup.show(
          context,
          birthdays: birthdays,
          anniversaries: anniversaries,
          companyDays: companyDays,
        );
        await prefs.setString('last_special_events_date', todayStr);
      }
    } catch (e) {
      debugPrint('Error checking special events: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _isInCurrentTerm(DateTime? date) {
    if (date == null) return false;
    final isTerm1Now = DateTime.now().month <= 6;
    final isTerm1Date = date.month <= 6;
    return isTerm1Now == isTerm1Date;
  }


  @override
  Widget build(BuildContext context) {
    final session = context.watch<MemberSessionProvider>();
    final member = session.currentMember;

    if (member == null || session.isLoading) {
      return _buildSkeleton();
    }

    final bool isVisitor = member.docId.startsWith('v_');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: StreamBuilder<List<ThankNote>>(
        stream: ThankNoteService().streamForMember(member.docId),
        builder: (context, sentSnapshot) {
          final sentNotes = sentSnapshot.data ?? const <ThankNote>[];
          final totalTaken = sentNotes.fold<double>(0, (sum, note) => sum + note.value);
          final termTaken = sentNotes
              .where((note) => _isInCurrentTerm(note.createdAt))
              .fold<double>(0, (sum, note) => sum + note.value);

          return StreamBuilder<List<ThankNote>>(
            stream: ThankNoteService().streamReceivedByMember(member.docId),
            builder: (context, receivedSnapshot) {
              final receivedNotes = receivedSnapshot.data ?? const <ThankNote>[];
              final totalGiven = receivedNotes.fold<double>(0, (sum, note) => sum + note.value);
              final termGiven = receivedNotes
                  .where((note) => _isInCurrentTerm(note.createdAt))
                  .fold<double>(0, (sum, note) => sum + note.value);

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<MemberSessionProvider>().restoreSession();
                },
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Profile Header (Boreo Deep Navy Blue)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                MemberAvatar(
                                  name: member.fullName,
                                  radius: 40,
                                  profileImage: member.profileImage,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (member.powerTeam.isNotEmpty) ...[
                                        Text(
                                          member.powerTeam.toUpperCase(),
                                          style: TextStyle(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        member.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.business, color: Colors.white70, size: 14),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              member.companyName,
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Quick Info Bar
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickInfoItem(Icons.phone, member.phone, color: AppTheme.secondary),
                                  if (!isVisitor) ...[
                                    Container(width: 1, height: 20, color: Colors.white24),
                                    _buildQuickInfoItem(Icons.bloodtype, member.bloodGroup, color: Colors.redAccent),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!isVisitor) ...[
                        // Quick Services Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t("Quick Services"),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildQuickActionBtn(
                                    imagePath: "assets/calendar.png",
                                    label: "Calendar",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                                      );
                                    },
                                  ),
                                  _buildQuickActionBtn(
                                    imagePath: "assets/event.png",
                                    label: "News & Events",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const NewsEventsScreen()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Required Dashboard Count Cards Section (Navy Blue & Orange Styled)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t("Dashboard Overview"),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Referrals Given Count Card
                                  Expanded(
                                    child: StreamBuilder<List<Referral>>(
                                      stream: ReferralService().streamForMember(member.docId),
                                      builder: (context, refSnapshot) {
                                        final count = refSnapshot.data?.length ?? 0;
                                        return _buildDashboardCountCard(
                                          title: "Referrals Given",
                                          count: "$count",
                                          icon: Icons.send_rounded,
                                          accentColor: AppTheme.secondary,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Referrals Taken Count Card
                                  Expanded(
                                    child: StreamBuilder<List<Referral>>(
                                      stream: ReferralService().streamReceivedByMember(member.docId),
                                      builder: (context, refSnapshot) {
                                        final count = refSnapshot.data?.length ?? 0;
                                        return _buildDashboardCountCard(
                                          title: "Referrals Taken",
                                          count: "$count",
                                          icon: Icons.call_received_rounded,
                                          accentColor: AppTheme.primary,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Meeting Attendance Count Card
                              StreamBuilder<int>(
                                stream: MeetingService().streamMyAttendanceCount(member.docId),
                                builder: (context, attSnapshot) {
                                  final count = attSnapshot.data ?? 0;
                                  return _buildDashboardCountCard(
                                    title: "Meeting Attendance",
                                    count: "$count",
                                    icon: Icons.how_to_reg_rounded,
                                    accentColor: AppTheme.success,
                                    isFullWidth: true,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
                        const SizedBox(height: 20),

                        // Thanks Score Summary Card
                        // Thank You Note Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.black.withOpacity(0.08)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.handshake_outlined,
                                          color: AppTheme.secondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          t("THANK SCORE SUMMARY"),
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t("TOTAL GIVEN"),
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "₹ ${_formatCurrency(totalGiven)}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        width: 1,
                                        color: AppTheme.border,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t("TOTAL TAKEN"),
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "₹ ${_formatCurrency(totalTaken)}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // This Term Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.black.withOpacity(0.08)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_outlined,
                                          color: AppTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          t("THIS TERM"),
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t("TOTAL GIVEN"),
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "₹ ${_formatCurrency(termGiven)}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        width: 1,
                                        color: AppTheme.border,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t("TOTAL TAKEN"),
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "₹ ${_formatCurrency(termTaken)}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Face to Face Card
                        StreamBuilder<List<FaceToFace>>(
                          stream: FaceToFaceService().streamSentByMember(member.docId),
                          builder: (context, faceToFaceSnapshot) {
                            final faceToFaceRecords = faceToFaceSnapshot.data ?? const <FaceToFace>[];
                            final totalFaceToFaceCount = faceToFaceRecords.length;
                            final termFaceToFaceCount = faceToFaceRecords
                                .where((entry) => _isInCurrentTerm(entry.createdAt))
                                .length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.people_outline,
                                              color: AppTheme.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              t("FACE TO FACE"),
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t("TOTAL COUNT"),
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "$totalFaceToFaceCount",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 40,
                                            width: 1,
                                            color: AppTheme.border,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t("THIS TERM"),
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "$termFaceToFaceCount",
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboardCountCard({
    required String title,
    required String count,
    required IconData icon,
    required Color accentColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t(title),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String text, {Color color = Colors.white, Color? textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t(label),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AnimatedSkeleton(width: 80, height: 80, borderRadius: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AnimatedSkeleton(width: 100, height: 12),
                          SizedBox(height: 8),
                          AnimatedSkeleton(width: 150, height: 24),
                          SizedBox(height: 8),
                          AnimatedSkeleton(width: 120, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
}