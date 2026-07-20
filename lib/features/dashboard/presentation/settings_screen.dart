import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
import '../widgets/dashboard_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profilesApi = ProfilesApiService();

  MyProfile? _profile;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _profilesApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleDirectory(bool value) async {
    setState(() => _saving = true);
    try {
      final updated = await _profilesApi.updateMyProfile({
        'is_directory_visible': value,
      });
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthSession.instance.clearSession();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _profile;
    final directoryVisible = profile?.isDirectoryVisible ?? true;
    final isCompact = DashboardLayout.isCompact(context);

    return SingleChildScrollView(
      padding: DashboardLayout.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account preferences and privacy.',
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 14 : 15,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: 'Account',
                children: [
                  if (profile != null) ...[
                    _InfoRow(label: 'Name', value: profile.fullName),
                    _InfoRow(
                      label: 'Email',
                      value: AuthSession.instance.currentUser?.email ?? '—',
                    ),
                    _InfoRow(
                      label: 'Batch',
                      value: profile.batchYear.toString(),
                    ),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Edit profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Update photo, phone and directory details',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/my-profile'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Privacy',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: directoryVisible,
                    onChanged: _saving ? null : _toggleDirectory,
                    title: Text(
                      'Show in alumni directory',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Allow other members to find your profile',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (isStaffRole(AuthSession.instance.currentUser?.role)) ...[
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'Staff',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Open staff console',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Analytics and profile verification queue',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                        staffConsoleRouteForRole(
                          AuthSession.instance.currentUser?.role,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Session',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Sign out',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    trailing: const Icon(Icons.logout, color: Colors.red),
                    onTap: _signOut,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DashboardLayout.cardPadding(context) - 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
