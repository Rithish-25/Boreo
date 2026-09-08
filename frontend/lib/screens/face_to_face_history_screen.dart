import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/face_to_face.dart';
import '../providers/member_session_provider.dart';
import '../services/face_to_face_service.dart';
import '../widgets/skeleton.dart';

/// Sent-only Face-to-Face history — shows Face-to-Face meetings the logged-in member initiated.
class FaceToFaceHistoryScreen extends StatelessWidget {
  const FaceToFaceHistoryScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "--";
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = context.watch<MemberSessionProvider>().currentMember;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: const Text("Face to Face History"),
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
          ? _buildMessageState(
              icon: Icons.person_off_outlined,
              message: "Please log in to view your Face to Face history",
            )
          : StreamBuilder<List<FaceToFace>>(
              stream: FaceToFaceService().streamSentByMember(currentMember.docId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList();
                }

                if (snapshot.hasError) {
                  return _buildMessageState(
                    icon: Icons.error_outline,
                    message: "Something went wrong while loading your history",
                  );
                }

                final histories = snapshot.data ?? const <FaceToFace>[];

                if (histories.isEmpty) {
                  return _buildMessageState(
                    icon: Icons.history_toggle_off_outlined,
                    message: "No Face to Face history found",
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  color: AppTheme.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final entry = histories[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Face to Face Entry #${histories.length - index}",
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(entry.createdAt),
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.person_outline,
                            label: "Your Name",
                            value: entry.fromMemberName,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.handshake_outlined,
                            label: "Whom are you doing Face to Face with?",
                            value: entry.toMemberName,
                          ),
                          if (entry.meetingAt.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.location_on_outlined,
                              label: "Meeting Location",
                              value: entry.meetingAt == "From Member Office"
                                  ? "${entry.fromMemberName}'s Office"
                                  : (entry.meetingAt == "To Member Office"
                                      ? "${entry.toMemberName}'s Office"
                                      : entry.meetingAt),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: "Your Face to Face Date",
                            value: _formatDate(entry.createdAt),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AnimatedSkeleton(width: 100, height: 20, borderRadius: 20),
                  AnimatedSkeleton(width: 80, height: 14),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  const AnimatedSkeleton(width: 32, height: 32, borderRadius: 8),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AnimatedSkeleton(width: 60, height: 10),
                      SizedBox(height: 4),
                      AnimatedSkeleton(width: 120, height: 14),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const AnimatedSkeleton(width: 32, height: 32, borderRadius: 8),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AnimatedSkeleton(width: 150, height: 10),
                      SizedBox(height: 4),
                      AnimatedSkeleton(width: 100, height: 14),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const AnimatedSkeleton(width: 32, height: 32, borderRadius: 8),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AnimatedSkeleton(width: 100, height: 10),
                      SizedBox(height: 4),
                      AnimatedSkeleton(width: 80, height: 14),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
