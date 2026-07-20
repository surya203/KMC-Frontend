import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
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
  final _roles = assignableUserRoles;

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

  Future<void> _load({int page = 1, int attempt = 0}) async {
    await AuthSession.instance.ensureReady();

    final showSpinner = _members.isEmpty;
    setState(() {
      // Keep the list visible while refreshing — never blank the page.
      _loading = showSpinner && attempt == 0;
      if (attempt == 0) _error = null;
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
        _error = null;
      });
    } catch (e) {
      if (attempt < 2 && _shouldRetry(e)) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        if (mounted) await _load(page: page, attempt: attempt + 1);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _shouldRetry(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('admin request failed') ||
        message.contains('could not reach') ||
        message.contains('connection') ||
        message.contains('timeout');
  }

  Future<void> _changeRole(AdminMemberItem member, String role) async {
    if (role == member.role) return;

    final previous = member;
    // Instant UI update — no full-page reload / spinner.
    setState(() {
      _savingUserId = member.userId;
      _members = [
        for (final m in _members)
          if (m.userId == member.userId)
            m.copyWith(
              role: role,
              isEcMember: role == ecMemberRole ||
                  role == 'executive' ||
                  officerRoles.contains(role) ||
                  m.isEcMember,
            )
          else
            m,
      ];
    });

    try {
      await _api.updateUserRole(member.userId, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Role updated to ${userRoleLabel(role)} for ${member.email}',
          ),
          backgroundColor: const Color(0xFF1F6B3A),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Roll back if the API failed.
      setState(() {
        _members = [
          for (final m in _members)
            if (m.userId == previous.userId) previous else m,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatError(e)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingUserId = null);
    }
  }

  String _formatError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
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
                'Search members, review verification status and assign roles.',
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
                                [
                                  m.email,
                                  userRoleLabel(m.role),
                                  if (m.isEcMember) 'EC',
                                  m.planName ?? 'No plan',
                                  m.verificationStatus ?? 'unknown',
                                ].join(' · '),
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
                          items: [
                            for (final r in {
                              ..._roles,
                              // Keep current value selectable if legacy/orphan
                              // (e.g. old verifier / executive) so the dropdown
                              // does not assert.
                              if (!_roles.contains(m.role)) m.role,
                            })
                              DropdownMenuItem(
                                value: r,
                                child: Text(userRoleLabel(r)),
                              ),
                          ],
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
