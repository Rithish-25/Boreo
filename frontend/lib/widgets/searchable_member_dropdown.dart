import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/member.dart';
import '../theme.dart';

class SearchableMemberDropdown extends StatefulWidget {
  final String? value;
  final List<Member> members;
  final String hintText;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const SearchableMemberDropdown({
    Key? key,
    required this.value,
    required this.members,
    required this.hintText,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  State<SearchableMemberDropdown> createState() => _SearchableMemberDropdownState();
}

class _SearchableMemberDropdownState extends State<SearchableMemberDropdown> {
  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchSheet(
        members: widget.members,
        onSelected: (member) {
          widget.onChanged(member.docId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMembers = widget.members.where((m) => m.docId == widget.value).toList();
    final selectedMember = selectedMembers.isNotEmpty ? selectedMembers.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _openSearchSheet,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: widget.errorText != null ? Colors.red : AppTheme.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedMember?.fullName ?? widget.hintText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: selectedMember != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final List<Member> members;
  final ValueChanged<Member> onSelected;

  const _SearchSheet({
    Key? key,
    required this.members,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.members;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = widget.members;
      } else {
        _filteredMembers = widget.members.where((m) {
          return m.fullName.toLowerCase().contains(query) ||
              m.companyName.toLowerCase().contains(query) ||
              m.businessType.toLowerCase().contains(query) ||
              m.phone.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search name, phone, or company...",
                hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: _filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      "No members found",
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredMembers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelected(member);
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                              ? CachedNetworkImageProvider(member.profileImage!) as ImageProvider
                              : null,
                          child: member.profileImage == null || member.profileImage!.isEmpty
                              ? Text(
                                  member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          member.fullName,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        subtitle: member.companyName.isNotEmpty
                            ? Text(
                                member.companyName,
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
