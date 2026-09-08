import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../language_service.dart';
import '../models/member.dart';
import '../models/thank_note.dart';
import '../models/referral.dart';
import '../services/member_service.dart';
import '../services/thank_note_service.dart';
import '../services/referral_service.dart';
import '../providers/member_session_provider.dart';
import '../widgets/searchable_member_dropdown.dart';
import '../widgets/skeleton.dart';

class ThanksNoteHistoryScreen extends StatefulWidget {
  final String initialFilter;
  const ThanksNoteHistoryScreen({super.key, this.initialFilter = "Thanks Note"});

  @override
  State<ThanksNoteHistoryScreen> createState() =>
      _ThanksNoteHistoryScreenState();
}

class _ThanksNoteHistoryScreenState extends State<ThanksNoteHistoryScreen> {
  final ThankNoteService _thankNoteService = ThankNoteService();
  final ReferralService _referralService = ReferralService();
  final MemberService _memberService = MemberService();

  late String _selectedFilter;
  // "Sent" = created by the logged-in member; "Received" = the member is
  // the recipient (toUserId for notes, referredUserId for referrals).
  String _selectedDirection = "Sent";
  DateTimeRange? _selectedDateRange;
  bool _isDefaultRange = true;
  String _selectedStatusFilter = "All";

  @override
  void initState() {
    super.initState();
    // Sending a thanks note means the recipient enabled business for YOU —
    // so notes you sent count as "Taken", notes sent to you count as
    // "Given" (matches home_screen.dart's Thanks Score Summary exactly).
    // "Taken" -> Thank Note tab, Sent direction (the notes making up your
    // Taken total are the ones you sent). "Given" -> Thank Note tab,
    // Received direction. Anything else (including the default "Referal")
    // falls through as-is, Sent direction — referrals aren't affected by
    // this Given/Taken convention.
    _selectedFilter = widget.initialFilter;
    if (widget.initialFilter == "Given") {
      _selectedFilter = "Thanks Note";
      _selectedDirection = "Received";
    } else if (widget.initialFilter == "Taken") {
      _selectedFilter = "Thanks Note";
      _selectedDirection = "Sent";
    } else {
      _selectedDirection = "Sent";
    }
    _setWedToTuesdayRange();
  }

  void _setWedToTuesdayRange() {
    final now = DateTime.now();
    // Calculate days since the most recent Tuesday
    // (if today is Tuesday, it will be 0)
    final daysSinceTuesday = (now.weekday - DateTime.tuesday + 7) % 7;
    final lastTuesday = now.subtract(Duration(days: daysSinceTuesday));
    // End is this Tuesday (the most recent one)
    final end = DateTime(lastTuesday.year, lastTuesday.month, lastTuesday.day);
    // Start is the previous Wednesday (6 days before the most recent Tuesday)
    final start = end.subtract(const Duration(days: 6));
    _selectedDateRange = DateTimeRange(start: start, end: end);
    _isDefaultRange = true;
  }

  bool _isWithinRange(DateTime? date) {
    if (date == null) return true;
    if (_selectedDateRange == null) return true;
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
    );
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
        (d.isAtSameMomentAs(end) || d.isBefore(end));
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _isDefaultRange = false;
      });
    }
  }

  String _formatDateToShow(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
  }


  /// Direction toggle (Sent / Received) — same "Sent"/"Received" wording
  /// regardless of type, so the terminology never shifts between tabs. The
  /// caption underneath (shown only for Thanks Note) is what explains the
  /// Given/Taken money-flow convention, so this toggle itself stays purely
  /// factual ("did I create it, or was it created about me").
  Widget _buildDirectionSegment(String direction, IconData icon, String label) {
    final isSelected = _selectedDirection == direction;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedDirection = direction;
          _selectedStatusFilter = "All";
        }),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                t(label),
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDetailDate(String rawDate) {
    try {
      final parts = rawDate.split("-");
      if (parts.length == 3) {
        return "${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}";
      }
    } catch (_) {}
    return rawDate;
  }

  DateTime? _parseDetailDate(String rawDate) {
    final parts = rawDate.split("-");
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  String _formatCurrency(double value) {
    String valStr = value.toInt().toString();
    if (valStr.length <= 3) return "₹$valStr";
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
    return "₹$formattedRemaining,$lastThree";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No history found",
        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          "Something went wrong: $error",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AnimatedSkeleton(width: 150, height: 18),
                  AnimatedSkeleton(width: 60, height: 16),
                ],
              ),
              const SizedBox(height: 8),
              const AnimatedSkeleton(width: 80, height: 14),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AnimatedSkeleton(width: 80, height: 12),
                  AnimatedSkeleton(width: 60, height: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralList(String memberId) {
    final isSent = _selectedDirection == "Sent";
    return StreamBuilder<List<Referral>>(
      stream: isSent
          ? _referralService.streamForMember(memberId)
          : _referralService.streamReceivedByMember(memberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }
        final referrals = (snapshot.data ?? const <Referral>[])
            .where((r) => _isWithinRange(r.createdAt))
            .where((r) {
              if (_selectedStatusFilter == "All") return true;
              final isOpen = r.status != "close";
              if (_selectedStatusFilter == "Open") return isOpen;
              if (_selectedStatusFilter == "Closed") return !isOpen;
              return true;
            })
            .toList();

        if (referrals.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primary,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              final referral = referrals[index];
              // Sent: show who you referred, with the self/connect detail.
              // Received: show who referred you (and, for a connect referral,
              // who connected you) — showing your own name back to you would
              // be useless here.
              final titleText = isSent
                  ? referral.referredUserName
                  : referral.referrerName;
              final subtitleText = referral.type == "connect"
                  ? "${t("Connect")}: ${referral.connectorName ?? ''}"
                  : t("Self");

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titleText,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            if (isSent) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => _EditReferralSheet(
                                      referralService: _referralService,
                                      memberService: _memberService,
                                      referral: referral,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          referral.createdAt != null
                              ? _formatDateToShow(referral.createdAt!)
                              : "",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        if (!isSent)
                          _buildReferralStatusButton(referral),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThankNoteList(String memberId) {
    final isSent = _selectedDirection == "Sent";
    return StreamBuilder<List<ThankNote>>(
      stream: isSent
          ? _thankNoteService.streamForMember(memberId)
          : _thankNoteService.streamReceivedByMember(memberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }
        final notes = (snapshot.data ?? const <ThankNote>[])
            .where((n) => _isWithinRange(_parseDetailDate(n.detailDate)))
            .toList();

        if (notes.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primary,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              // Sent: show who you thanked. Received: show who thanked you —
              // showing your own name back to you would be useless here.
              final titleText = isSent ? note.toName : note.fromName;
              final subtitleText = note.type == "connect"
                  ? "${t("Connect")}: ${note.connectorName ?? ''}"
                  : t("Direct");

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatCurrency(note.value),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                        if (isSent) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () =>
                                _showEditThankNoteSheet(memberId, note),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDetailDate(note.detailDate),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }



  Future<void> _updateReferralStatus(Referral referral, String newStatus) async {
    try {
      await _referralService.update(referral.docId, {'status': newStatus});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to update status. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showStatusConfirmDialog(Referral referral, String targetStatus) async {
    final title = targetStatus == "close" ? t("Close Referral") : t("Open Referral");
    final content = targetStatus == "close"
        ? t("Are you sure you want to close this referral?")
        : t("Are you sure you want to open this referral?");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              t("No"),
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: targetStatus == "close" ? AppTheme.error : AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t("Yes"),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateReferralStatus(referral, targetStatus);
    }
  }

  Widget _buildReferralStatusButton(Referral referral) {
    final isOpen = referral.status != "close";
    final displayText = isOpen ? "Open" : "Closed";
    final themeColor = isOpen ? const Color(0xFF10B981) : AppTheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showStatusConfirmDialog(
            referral,
            isOpen ? "close" : "active",
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            t(displayText),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String status) {
    final isSelected = _selectedStatusFilter == status;
    Color chipColor;
    if (status == "Open") {
      chipColor = const Color(0xFF10B981);
    } else if (status == "Closed") {
      chipColor = AppTheme.error;
    } else {
      chipColor = AppTheme.primary;
    }

    return ChoiceChip(
      label: Text(
        t(status),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = status;
          });
        }
      },
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? chipColor : AppTheme.border,
          width: 1,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showEditThankNoteSheet(String memberId, ThankNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditThankNoteSheet(
        thankNoteService: _thankNoteService,
        memberService: _memberService,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = context.watch<MemberSessionProvider>().currentMember;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        title: Text(
          _selectedFilter == "Referal"
              ? t("Referal's history")
              : t("Thanksnote History"),
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
      body: SafeArea(
        child: currentMember == null
            ? _buildLoading()
            : Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 20,
                  right: 20,
                  bottom: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // What: Referral vs Thanks Note (Removed per request)

                    // Which way: Sent vs Received — same wording for both
                    // types, so the toggle stays purely factual.
                    Container(
                      height: 38,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: _selectedDirection == "Sent"
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildDirectionSegment(
                                "Sent",
                                _selectedFilter == "Thanks Note"
                                    ? Icons.call_received
                                    : Icons.call_made,
                                _selectedFilter == "Thanks Note" ? "Taken" : "Sent",
                              ),
                              _buildDirectionSegment(
                                "Received",
                                _selectedFilter == "Thanks Note"
                                    ? Icons.call_made
                                    : Icons.call_received,
                                _selectedFilter == "Thanks Note" ? "Given" : "Received",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sending a thanks note means the recipient enabled
                    // business for YOU — so "Sent" counts toward your Taken
                    // total and "Received" counts toward your Given total
                    // (matches home_screen.dart's Thanks Score Summary).
                    // Only shown for Thanks Note since referrals have no
                    // such money-flow convention to explain.
                    if (_selectedFilter == "Thanks Note") ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedDirection == "Sent"
                            ? t("These notes count toward your TAKEN total")
                            : t("These notes count toward your GIVEN total"),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Tuesday to Tuesday date filter status card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isDefaultRange
                                  ? AppTheme.success.withOpacity(0.1)
                                  : AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isDefaultRange
                                  ? Icons.event_repeat
                                  : Icons.date_range,
                              size: 14,
                              color: _isDefaultRange
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isDefaultRange
                                      ? t("Previous Wed to This Tuesday")
                                      : t("Custom Date Range"),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _selectedDateRange != null
                                      ? "${_formatDateToShow(_selectedDateRange!.start)} - ${_formatDateToShow(_selectedDateRange!.end)}"
                                      : "All History",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isDefaultRange)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _setWedToTuesdayRange();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Reset",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: _pickDateRange,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Sort/Filter",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedFilter == "Referal" && _selectedDirection == "Received") ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "${t("Status")}:",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildStatusFilterChip("All"),
                                  const SizedBox(width: 8),
                                  _buildStatusFilterChip("Open"),
                                  const SizedBox(width: 8),
                                  _buildStatusFilterChip("Closed"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey(
                            _selectedFilter +
                                _selectedDirection +
                                (_selectedDateRange?.toString() ?? '') +
                                _selectedStatusFilter,
                          ),
                          child: _selectedFilter == "Referal"
                              ? _buildReferralList(currentMember.docId)
                              : _buildThankNoteList(currentMember.docId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Edit form for a Thank You Note the logged-in member sent — recipient,
/// message, and business amount are all editable (fromUserId never is; see
/// ThankNoteService.update and the firestore.rules immutability check).
class _EditThankNoteSheet extends StatefulWidget {
  final ThankNoteService thankNoteService;
  final MemberService memberService;
  final ThankNote note;

  const _EditThankNoteSheet({
    required this.thankNoteService,
    required this.memberService,
    required this.note,
  });

  @override
  State<_EditThankNoteSheet> createState() => _EditThankNoteSheetState();
}

class _EditThankNoteSheetState extends State<_EditThankNoteSheet> {
  late final TextEditingController _amountController;
  String? _selectedToMemberId;
  String? _selectedToMemberName;
  String _thankNoteType = "direct";
  late final TextEditingController _thankNoteConnectorController;
  bool _isSaving = false;
  String? _amountError;
  String? _recipientError;
  String? _thankNoteConnectorError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.note.value.toStringAsFixed(0),
    );
    _selectedToMemberId = widget.note.toUserId;
    _selectedToMemberName = widget.note.toName;
    _thankNoteType = widget.note.type.isNotEmpty ? widget.note.type : "direct";
    _thankNoteConnectorController = TextEditingController(
      text: widget.note.connectorName ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _thankNoteConnectorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _amountError = null;
      _recipientError = null;
      _thankNoteConnectorError = null;
    });

    if (_selectedToMemberId == null) {
      setState(() => _recipientError = "Please select a member!");
      return;
    }
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(",", ""),
    );
    if (amount == null || amount <= 0) {
      setState(
        () => _amountError = "Please enter a valid numeric business amount!",
      );
      return;
    }
    if (_thankNoteType == "connect" &&
        _thankNoteConnectorController.text.trim().isEmpty) {
      setState(
        () => _thankNoteConnectorError =
            "Please provide a Connection Name or Details",
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.thankNoteService.update(widget.note.docId, {
        'toUserId': _selectedToMemberId,
        'toName': _selectedToMemberName,
        'message': "",
        'value': amount,
        'type': _thankNoteType,
        'connectorName': _thankNoteType == "connect"
            ? _thankNoteConnectorController.text.trim()
            : null,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Thanks Note updated!")),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to update. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t("Delete Thanks Note")),
        content: Text(t("Are you sure you want to delete this thanks note?")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t("Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t("Delete"),
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await widget.thankNoteService.delete(widget.note.docId);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Thanks Note deleted!")),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to delete. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                t("Edit Thanks Note"),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t("Type"),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _thankNoteType,
                items: [
                  DropdownMenuItem(
                    value: "direct",
                    child: Text(
                      t("Direct"),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "connect",
                    child: Text(
                      t("Connect"),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _thankNoteType = val ?? "direct";
                    if (_thankNoteType != "connect") {
                      _thankNoteConnectorController.clear();
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t("Recipient"),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Member>>(
                stream: widget.memberService.streamActiveMembers(),
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <Member>[];
                  return SearchableMemberDropdown(
                    value: _selectedToMemberId,
                    hintText: t("Select member"),
                    members: members,
                    errorText: _recipientError,
                    onChanged: (val) {
                      if (val == null) return;
                      final member = members.firstWhere((m) => m.docId == val);
                      setState(() {
                        _selectedToMemberId = val;
                        _selectedToMemberName = member.fullName;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_thankNoteType == "connect") ...[
                Text(
                  t("Connection Name / Details"),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _thankNoteConnectorController,
                  decoration: InputDecoration(
                    hintText: t("Connection Name / Details"),
                    errorText: _thankNoteConnectorError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                t("Business Amount"),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  hintText: "0",
                  errorText: _amountError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t("Save Changes"),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    t("Delete Thanks Note"),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ));
  }
}

class _EditReferralSheet extends StatefulWidget {
  final ReferralService referralService;
  final MemberService memberService;
  final Referral referral;

  const _EditReferralSheet({
    required this.referralService,
    required this.memberService,
    required this.referral,
  });

  @override
  State<_EditReferralSheet> createState() => _EditReferralSheetState();
}

class _EditReferralSheetState extends State<_EditReferralSheet> {
  String? _selectedReferredMemberId;
  String? _selectedReferredMemberName;
  String _referralType = "self";
  late final TextEditingController _connectorNameController;
  bool _isSaving = false;
  String? _recipientError;
  String? _connectorNameError;

  @override
  void initState() {
    super.initState();
    _selectedReferredMemberId = widget.referral.referredUserId;
    _selectedReferredMemberName = widget.referral.referredUserName;
    _referralType = widget.referral.type.isNotEmpty
        ? widget.referral.type
        : "self";
    _connectorNameController = TextEditingController(
      text: widget.referral.connectorName ?? '',
    );
  }

  @override
  void dispose() {
    _connectorNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _recipientError = null;
      _connectorNameError = null;
    });

    if (_selectedReferredMemberId == null) {
      setState(() => _recipientError = "Please select a member!");
      return;
    }
    if (_referralType == "connect" &&
        _connectorNameController.text.trim().isEmpty) {
      setState(
        () =>
            _connectorNameError = "Please provide a Connection Name or Details",
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedReferral = Referral(
        docId: '', // id is derived in service
        type: _referralType,
        referrerId: widget.referral.referrerId,
        referrerName: widget.referral.referrerName,
        connectorId: null,
        connectorName: _referralType == "connect"
            ? _connectorNameController.text.trim()
            : null,
        referredUserId: _selectedReferredMemberId!,
        referredUserName: _selectedReferredMemberName!,
        createdBy: widget.referral.createdBy,
        createdByName: widget.referral.createdByName,
        createdAt: widget.referral.createdAt,
      );

      await widget.referralService.updateAndReplaceIfNeeded(
        widget.referral.docId,
        updatedReferral,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Referral updated!")),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to update. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t("Delete Referral")),
        content: Text(t("Are you sure you want to delete this referral?")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t("Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t("Delete"),
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await widget.referralService.delete(widget.referral.docId);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Referral deleted!")),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Failed to delete. Please try again.")),
          backgroundColor: AppTheme.error,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                t("Edit Referral"),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t("Type"),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _referralType,
                items: [
                  DropdownMenuItem(
                    value: "self",
                    child: Text(
                      t("Self"),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "connect",
                    child: Text(
                      t("Connect"),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _referralType = val ?? "self";
                    if (_referralType != "connect") {
                      _connectorNameController.clear();
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t("Referred Member"),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Member>>(
                stream: widget.memberService.streamActiveMembers(),
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <Member>[];
                  return SearchableMemberDropdown(
                    value: _selectedReferredMemberId,
                    hintText: t("Select member"),
                    members: members,
                    errorText: _recipientError,
                    onChanged: (val) {
                      if (val == null) return;
                      final member = members.firstWhere((m) => m.docId == val);
                      setState(() {
                        _selectedReferredMemberId = val;
                        _selectedReferredMemberName = member.fullName;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_referralType == "connect") ...[
                Text(
                  t("Connection Name / Details"),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _connectorNameController,
                  decoration: InputDecoration(
                    hintText: t("Connection Name / Details"),
                    errorText: _connectorNameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t("Save Changes"),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    t("Delete Referral"),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ));
  }
}
