import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/announcements_api_service.dart';
import '../../../core/network/connect_api_service.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.initials,
    required this.time,
    required this.text,
    this.badge,
  });

  final String author;
  final String initials;
  final String time;
  final String text;
  final String? badge;

  factory _ChatMessage.fromAnnouncement(AnnouncementItem item) {
    final body = (item.body != null && item.body!.trim().isNotEmpty)
        ? item.body!.trim()
        : item.title;
    return _ChatMessage(
      author: item.authorName,
      initials: _initialsFromName(item.authorName),
      time: _formatTime(item.publishedAt),
      text: body,
      badge: item.authorRoleLabel,
    );
  }
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'K';
  if (parts.length == 1) {
    return parts.first.length >= 2
        ? parts.first.substring(0, 2).toUpperCase()
        : parts.first[0].toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class DashboardConnectScreen extends StatefulWidget {
  const DashboardConnectScreen({super.key});

  @override
  State<DashboardConnectScreen> createState() => _DashboardConnectScreenState();
}

class _DashboardConnectScreenState extends State<DashboardConnectScreen> {
  final _api = ConnectApiService();
  final _messageController = TextEditingController();

  bool _communityTab = true;
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<_ChatMessage> _messages = [];
  List<ConnectOfficer> _officers = [];

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSessionChanged);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSessionChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    if (AuthSession.instance.isAuthenticated) {
      _load();
    }
  }

  Future<void> _load({int attempt = 0}) async {
    await AuthSession.instance.ensureReady();
    try {
      await AuthSession.instance.authService.fetchMe(allowRefresh: true);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _loading = attempt == 0;
      if (attempt == 0) _error = null;
    });

    try {
      List<AnnouncementItem> posts = [];
      List<ConnectOfficer> officers = [];
      Object? postsError;
      Object? officersError;

      try {
        posts = await _api.fetchGeneralGroupPosts();
      } catch (e) {
        postsError = e;
      }

      try {
        officers = await _api.fetchOfficers();
      } catch (e) {
        officersError = e;
      }

      if (postsError != null && officersError != null) {
        throw postsError;
      }

      if (!mounted) return;
      setState(() {
        _messages = posts
            .map(_ChatMessage.fromAnnouncement)
            .toList()
            .reversed
            .toList();
        _officers = officers;
        _loading = false;
        _error = postsError != null
            ? _formatError(postsError)
            : officersError != null
                ? 'Officer list unavailable. General Group posts still load below.'
                : null;
      });
    } catch (e) {
      if (attempt < 2) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        if (mounted) await _load(attempt: attempt + 1);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = _formatError(e);
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _posting) return;

    final role = AuthSession.instance.currentUser?.role;
    if (!canPostToGeneralGroup(role)) return;

    setState(() => _posting = true);
    try {
      await _api.postGeneralGroupMessage(text);
      _messageController.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Posted as ${generalGroupRoleLabel(role)}',
          ),
          backgroundColor: const Color(0xFF1F6B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final userRole = AuthSession.instance.currentUser?.role;
    final canPost = canPostToGeneralGroup(userRole);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isMobile ? 12 : 20,
        horizontalPadding,
        isMobile ? 24 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) ...[
                Text(
                  'Connect to Executive Committee',
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'View General Group announcements from KMC officers. Members can read updates here. Message Executive Committee members directly in the second tab.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 15,
                  color: AppColors.bodyText,
                  height: 1.45,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: _error!, onRetry: _load),
              ],
              if (!canPost && _communityTab) ...[
                const SizedBox(height: 10),
                _ReadOnlyNotice(role: userRole),
              ],
              SizedBox(height: isMobile ? 16 : 20),
              _ModeToggle(
                communitySelected: _communityTab,
                onCommunity: () => setState(() => _communityTab = true),
                onCommittee: () => setState(() => _communityTab = false),
                fullWidth: isMobile,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              if (_communityTab)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chatHeight = isMobile
                        ? (MediaQuery.sizeOf(context).height * 0.48)
                            .clamp(280.0, 480.0)
                        : 520.0;

                    return SizedBox(
                      height: chatHeight,
                      child: _CommunityChatPanel(
                        messages: _messages,
                        officers: _officers,
                        messageController: _messageController,
                        onSend: _sendMessage,
                        canPost: canPost,
                        posting: _posting,
                        compact: isMobile,
                      ),
                    );
                  },
                )
              else
                _CommitteePanel(officers: _officers, compact: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.communitySelected,
    required this.onCommunity,
    required this.onCommittee,
    this.fullWidth = false,
  });

  final bool communitySelected;
  final VoidCallback onCommunity;
  final VoidCallback onCommittee;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (fullWidth) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _ToggleChip(
              label: 'General Group',
              icon: Icons.campaign_outlined,
              selected: communitySelected,
              onTap: onCommunity,
              expanded: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _ToggleChip(
              label: 'Executive Committee',
              icon: Icons.shield_outlined,
              selected: !communitySelected,
              onTap: onCommittee,
              expanded: true,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      children: [
        _ToggleChip(
          label: 'General Group',
          icon: Icons.campaign_outlined,
          selected: communitySelected,
          onTap: onCommunity,
        ),
        _ToggleChip(
          label: 'Executive Committee',
          icon: Icons.shield_outlined,
          selected: !communitySelected,
          onTap: onCommittee,
        ),
      ],
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined, size: 18, color: AppColors.heading),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are signed in as ${generalGroupRoleLabel(role)}. '
              'Only President, Vice President, Secretary, and Treasurer can post announcements to General Group.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.bodyText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.expanded = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 18,
            vertical: expanded ? 12 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.heading,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.heading,
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

class _CommunityChatPanel extends StatelessWidget {
  const _CommunityChatPanel({
    required this.messages,
    required this.officers,
    required this.messageController,
    required this.onSend,
    required this.canPost,
    required this.posting,
    this.compact = false,
  });

  final List<_ChatMessage> messages;
  final List<ConnectOfficer> officers;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool canPost;
  final bool posting;
  final bool compact;

  static const _executiveRoles = {
    'president',
    'vice_president',
    'secretary',
    'treasurer',
  };

  @override
  Widget build(BuildContext context) {
    final executive = officers
        .where((o) => _executiveRoles.contains(o.role))
        .toList()
      ..sort((a, b) {
        const order = {
          'president': 0,
          'vice_president': 1,
          'secretary': 2,
          'treasurer': 3,
        };
        return (order[a.role] ?? 9).compareTo(order[b.role] ?? 9);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              compact ? 12 : 16,
              compact ? 14 : 20,
              compact ? 10 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'General Group',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 15 : 16,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '${messages.length} announcements',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Official announcements for all alumni',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                if (executive.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _OfficersBar(officers: executive, compact: compact),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No announcements yet. Officers can post the first update.',
                      style: GoogleFonts.inter(color: AppColors.mutedText),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      padding: EdgeInsets.all(compact ? 14 : 20),
                      children: [
                        for (final message in messages)
                          _MessageBubble(message: message),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          if (canPost)
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 16,
                compact ? 14 : 20,
                compact ? 10 : 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      enabled: !posting,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: 'Post announcement to General Group',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: compact ? 14 : 16,
                          vertical: compact ? 12 : 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (compact)
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: posting ? null : onSend,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: posting
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: posting ? null : onSend,
                      icon: posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(posting ? 'Posting...' : 'Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 16,
                compact ? 14 : 20,
                compact ? 12 : 16,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View only. President, Vice President, Secretary, and Treasurer can post here.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficersBar extends StatelessWidget {
  const _OfficersBar({required this.officers, this.compact = false});

  final List<ConnectOfficer> officers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final officer in officers)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  officer.roleLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  officer.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              message.initials,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.author,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    if (message.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.badge!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      message.time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: AppColors.bodyText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitteePanel extends StatelessWidget {
  const _CommitteePanel({
    required this.officers,
    this.compact = false,
  });

  final List<ConnectOfficer> officers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Text(
              'Message Executive Committee',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 16 : 20, 0, compact ? 16 : 20, 12),
            child: Text(
              'President, Vice President, Secretary, Treasurer, and Admin officers from your alumni database.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
          ),
          const Divider(height: 1),
          if (officers.isEmpty)
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Text(
                'No officers assigned yet. Admin can set roles in Staff Console → Members.',
                style: GoogleFonts.inter(color: AppColors.mutedText),
              ),
            )
          else
            for (final officer in officers)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    officer.initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  officer.displayName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  officer.roleLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                  ),
                ),
                trailing: Text(
                  officer.email,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
