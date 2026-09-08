import 'package:flutter/material.dart';
import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../widgets/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/member_session_provider.dart';
import 'member_details_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _listController;
  final MemberService _memberService = MemberService();

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Member> _filterMembers(List<Member> members) {
    if (_searchQuery.trim().isEmpty) return members;
    final queryWords = _searchQuery.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return members.where((member) {
      final allText = [
        member.fullName,
        member.companyName,
        member.phone,
        member.businessAddress,
        member.address,
        member.bloodGroup,
        member.powerTeam,
        member.ridNo,
        member.email,
        member.fatherName,
        member.education,
        member.dateOfBirth,
        member.businessType,
        member.officeNo,
        member.websiteUrl,
        member.socialMedia,
        member.joiningDate,
        member.businessExpertise,
        member.whyBuyFromYou,
        member.aboutBusiness,
        member.position,
        member.memberQualification,
        member.wifeName,
        member.wifeDob,
        member.wifeBloodGroup,
        member.wifeQualification,
      ].join(" ").toLowerCase();

      return queryWords.every((word) => allText.contains(word));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header (Modern, clean, search-first)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: t("Search by Name, Business, Phone..."),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<Member>>(
            stream: _memberService.streamActiveMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonList();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }

              final members = snapshot.data ?? const <Member>[];
              final filteredMembers = _filterMembers(members);

              if (filteredMembers.isEmpty) {
                return _buildEmptyState(members.isEmpty);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _memberService.forceSyncActiveMembers();
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                color: AppTheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];

                  // Simple staggered fade/slide list transition
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _listController,
                      curve: Interval(
                        (index / filteredMembers.length).clamp(0.0, 1.0),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                  );

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: animation.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - animation.value) * 30),
                          child: child,
                        ),
                      );
                    },
                    child: _buildMemberCard(context, member),
                  );
                },
              ),
            );
          },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              t("Something went wrong"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "$error",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noMembersAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            t(noMembersAtAll ? "No members yet" : "No members found"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            t(noMembersAtAll ? "Check back later" : "Try adjusting your search filters"),
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemberDetailsScreen(member: member)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              MemberAvatar(
                name: member.fullName,
                radius: 30,
                profileImage: member.profileImage,
              ),
              const SizedBox(width: 16),
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t(member.fullName),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t(member.companyName),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildContactBtn(
                    icon: Icons.phone,
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue.shade700,
                    onTap: () async {
                      if (member.phone.isNotEmpty) {
                        final url = Uri.parse('tel:${member.phone}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildContactBtn(
                    iconWidget: const WhatsAppIconWidget(size: 18, color: Color(0xFF15803D)),
                    color: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                    onTap: () async {
                      final waNumber = member.whatsappNumber.isNotEmpty ? member.whatsappNumber : member.phone;
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactBtn({
    IconData? icon,
    Widget? iconWidget,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: iconWidget ?? Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const AnimatedSkeleton(width: 60, height: 60, borderRadius: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AnimatedSkeleton(width: 120, height: 16),
                      SizedBox(height: 8),
                      AnimatedSkeleton(width: 80, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const AnimatedSkeleton(width: 38, height: 38, borderRadius: 19),
                const SizedBox(width: 8),
                const AnimatedSkeleton(width: 38, height: 38, borderRadius: 19),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WhatsAppIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppIconWidget({
    Key? key,
    this.size = 24.0,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;

  _WhatsAppPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    final path = Path()
      ..moveTo(12.012, 2.0)
      ..cubicTo(6.506, 2.0, 2.024, 6.482, 2.024, 11.988)
      ..cubicTo(2.024, 13.749, 2.483, 15.467, 3.356, 16.994)
      ..lineTo(2.0, 22.0)
      ..lineTo(7.166, 20.646)
      ..cubicTo(8.638, 21.448, 10.291, 21.872, 12.012, 21.872)
      ..cubicTo(17.518, 21.872, 22.0, 17.39, 22.0, 11.988)
      ..cubicTo(22.0, 6.482, 17.518, 2.0, 12.012, 2.0)
      ..close()
      ..moveTo(18.071, 15.904)
      ..cubicTo(17.811, 16.636, 16.789, 17.232, 16.289, 17.312)
      ..cubicTo(15.814, 17.388, 15.306, 17.442, 13.239, 16.588)
      ..cubicTo(10.594, 15.496, 8.911, 12.806, 8.779, 12.631)
      ..cubicTo(8.647, 12.456, 7.702, 11.198, 7.702, 9.901)
      ..cubicTo(7.702, 8.603, 8.382, 7.964, 8.624, 7.704)
      ..cubicTo(8.866, 7.444, 9.152, 7.378, 9.328, 7.378)
      ..cubicTo(9.504, 7.378, 9.68, 7.38, 9.834, 7.388)
      ..cubicTo(9.998, 7.396, 10.218, 7.326, 10.436, 7.852)
      ..cubicTo(10.656, 8.38, 11.188, 9.684, 11.254, 9.816)
      ..cubicTo(11.32, 9.948, 11.364, 10.102, 11.276, 10.278)
      ..cubicTo(11.188, 10.454, 11.144, 10.564, 11.012, 10.718)
      ..cubicTo(10.88, 10.872, 10.735, 11.061, 10.616, 11.18)
      ..cubicTo(10.484, 11.312, 10.348, 11.455, 10.502, 11.719)
      ..cubicTo(10.656, 11.983, 11.185, 12.846, 11.966, 13.54)
      ..cubicTo(12.956, 14.422, 13.79, 14.697, 14.054, 14.829)
      ..cubicTo(14.318, 14.961, 14.472, 14.939, 14.626, 14.763)
      ..cubicTo(14.78, 14.587, 15.286, 13.993, 15.462, 13.729)
      ..cubicTo(15.638, 13.465, 15.814, 13.509, 16.056, 13.597)
      ..cubicTo(16.298, 13.685, 17.596, 14.323, 17.86, 14.455)
      ..cubicTo(18.124, 14.587, 18.3, 14.653, 18.366, 14.763)
      ..cubicTo(18.432, 14.873, 18.432, 15.401, 18.172, 16.136)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
