import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_api_service.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _api = AdminApiService();
  final _search = TextEditingController();
  final _roles = const [
    'member',
    'staff',
    'executive',
    'verifier',
    'president',
    'vice_president',
    'secretary',
    'treasurer',
    'admin',
  ];

  List<AdminMemberItem> _members = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  String? _error;
  String? _savingUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchMembers(
        search: _search.text.trim(),
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _members = data.members;
        _page = data.page;
        _hasMore = data.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(AdminMemberItem member, String role) async {
    setState(() => _savingUserId = member.userId);
    try {
      await _api.updateUserRole(member.userId, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated for ${member.email}')),
      );
      await _load(page: _page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Members',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search members, review verification status, and assign roles.',
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _load(),
                      decoration: const InputDecoration(
                        hintText: 'Search by email...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _loading ? null : _load,
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'No members found.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                for (final m in _members)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.fullName ?? m.email,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.email} · ${m.planName ?? 'No plan'} · ${m.verificationStatus ?? 'unknown'}',
                                style: GoogleFonts.inter(
                                  color: AppColors.mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: m.role,
                          items: _roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                ),
                              )
                              .toList(),
                          onChanged: _savingUserId == m.userId
                              ? null
                              : (value) {
                                  if (value == null || value == m.role) return;
                                  _changeRole(m, value);
                                },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _hasMore ? () => _load(page: _page + 1) : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
