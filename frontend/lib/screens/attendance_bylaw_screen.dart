import 'package:flutter/material.dart';
import '../theme.dart';
import '../language_service.dart';

class AttendanceByLawScreen extends StatelessWidget {
  const AttendanceByLawScreen({super.key});

  static const List<Map<String, String>> _rules = [
    {"rule": "Meeting Time", "detail": "7:15 AM"},
    {"rule": "Before 7:15 AM", "detail": "Present"},
    {"rule": "7:15 AM to 7:45 AM", "detail": "Late"},
    {"rule": "3 Permissions", "detail": "1 Day Leave"},
    {"rule": "After 7:45 AM", "detail": "Absent"},
    {"rule": "Continuous 3 Leaves", "detail": "₹10,000 Fine"},
    {"rule": "More than 6 Leaves per Term", "detail": "₹10,000 Fine"},
    {"rule": "3 Continuous Fine Payments", "detail": "1 Year Membership Blockage"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Text(t("Attendance By-Law")),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t("Attendance By-Law Rules"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const _RuleRow(
                      rule: "Rule",
                      detail: "Details",
                      isHeader: true,
                    ),
                    for (int i = 0; i < _rules.length; i++)
                      _RuleRow(
                        rule: _rules[i]["rule"]!,
                        detail: _rules[i]["detail"]!,
                        note: _rules[i]["note"],
                        showBottomBorder: i != _rules.length - 1,
                        detailColor: _rules[i]["detail"]!.contains("Fine") ||
                                _rules[i]["detail"]!.contains("Blockage") ||
                                _rules[i]["detail"] == "Absent"
                            ? AppTheme.error
                            : AppTheme.textPrimary,
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

class _RuleRow extends StatelessWidget {
  final String rule;
  final String detail;
  final String? note;
  final bool isHeader;
  final bool showBottomBorder;
  final Color detailColor;

  const _RuleRow({
    required this.rule,
    required this.detail,
    this.note,
    this.isHeader = false,
    this.showBottomBorder = true,
    this.detailColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: AppTheme.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    t(rule),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.border),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    t(detail),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                      color: isHeader ? AppTheme.textPrimary : detailColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (note != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                t(note!),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
