import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/announcements_api_service.dart';
import '../../../core/network/connect_api_service.dart';
import '../widgets/dashboard_layout.dart';

enum _ConnectTab { generalGroup, alumniChat, financeCouncil, executiveCommittee }

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.initials,
    required this.time,
    required this.text,
    this.badge,
    this.audienceLabel,
    this.isAlert = false,
  });

  final String author;
  final String initials;
  final String time;
  final String text;
  final String? badge;
  final String? audienceLabel;
  final bool isAlert;

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

  factory _ChatMessage.fromCommunityMessage(CommunityMessageItem item) {
    return _ChatMessage(
      author: item.authorName,
      initials: item.authorInitials,
      time: _formatTime(item.createdAt),
      text: item.body,
      badge: item.authorRoleLabel ??
          (item.batchYear != null ? 'Batch ${item.batchYear}' : null),
      audienceLabel: item.audienceLabel,
      isAlert: item.isTargeted,
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

  bool _loading = true;
  bool _posting = false;
  String? _error;
  String? _financeCouncilError;
  _ConnectTab _activeTab = _ConnectTab.generalGroup;
  List<_ChatMessage> _messages = [];
  List<_ChatMessage> _alumniChatMessages = [];
  List<_ChatMessage> _financeCouncilMessages = [];
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
      if (attempt == 0) {
        _error = null;
        _financeCouncilError = null;
      }
    });

    try {
      List<AnnouncementItem> posts = [];
      List<CommunityMessageItem> communityMessages = [];
      List<CommunityMessageItem> financeCouncilMessages = [];
      List<ConnectOfficer> officers = [];
      Object? postsError;
      Object? communityError;
      Object? financeCouncilError;
      Object? officersError;
      final userRole = AuthSession.instance.currentUser?.role;
      final showFinanceCouncilTab = canViewFinanceCouncil(userRole);

      try {
        posts = await _api.fetchGeneralGroupPosts();
      } catch (e) {
        postsError = e;
      }

      try {
        communityMessages = await _api.fetchCommunityMessages();
      } catch (e) {
        communityError = e;
      }

      if (showFinanceCouncilTab) {
        try {
          financeCouncilMessages = await _api.fetchFinanceCouncilMessages();
        } catch (e) {
          financeCouncilError = e;
        }
      }

      try {
        officers = await _api.fetchOfficers();
      } catch (e) {
        officersError = e;
      }

      if (postsError != null && communityError != null && officersError != null) {
        throw postsError;
      }

      if (!mounted) return;
      setState(() {
        _messages = posts
            .map(_ChatMessage.fromAnnouncement)
            .toList()
            .reversed
            .toList();
        _alumniChatMessages =
            communityMessages.map(_ChatMessage.fromCommunityMessage).toList();
        _financeCouncilMessages = financeCouncilMessages
            .map(_ChatMessage.fromCommunityMessage)
            .toList();
        _officers = officers;
        _loading = false;
        _financeCouncilError = financeCouncilError != null && showFinanceCouncilTab
            ? _formatError(financeCouncilError)
            : null;
        _error = postsError != null
            ? _formatError(postsError)
            : communityError != null
                ? 'Alumni Chat unavailable. ${_formatError(communityError)}'
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

  Future<void> _sendAlumniChatMessage([AlumniChatTargets? targets]) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _posting) return;

    setState(() => _posting = true);
    try {
      await _api.postCommunityMessage(text, targets);
      _messageController.clear();
      await _load();
      if (!mounted) return;
      final targeted = targets?.hasAny ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targeted
                ? 'Alert sent only to matching alumni'
                : 'Message sent to Alumni Chat',
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

  Future<void> _sendFinanceCouncilMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _posting) return;

    setState(() => _posting = true);
    try {
      await _api.postFinanceCouncilMessage(text);
      _messageController.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to Finance Council'),
          backgroundColor: Color(0xFF1F6B3A),
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

  bool _isAlumniChatSetupError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('community_group_messages') ||
        lower.contains('migration-018') ||
        lower.contains('database setup');
  }

  bool _isFinanceCouncilSetupError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('finance_council_messages') ||
        lower.contains('migration-019') ||
        lower.contains('database setup');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = DashboardLayout.isCompact(context);
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final userRole = AuthSession.instance.currentUser?.role;
    final canPost = canPostToGeneralGroup(userRole);
    final canPostFinance = canPostToFinanceCouncil(userRole);
    final showFinanceCouncilTab = canViewFinanceCouncil(userRole);

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
                'General Group is for officer announcements. Alumni Chat is open to all members — use Set audience for group alerts. Finance Council is private (President, VP, Treasurer — Admin view-only). Executive Committee: officers start a private DM; members reply after.',
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
              if (_financeCouncilError != null &&
                  _activeTab == _ConnectTab.financeCouncil) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: _financeCouncilError!, onRetry: _load),
              ],
              if (!canPost && _activeTab == _ConnectTab.generalGroup) ...[
                const SizedBox(height: 10),
                _ReadOnlyNotice(role: userRole),
              ],
              if (!canPostFinance &&
                  _activeTab == _ConnectTab.financeCouncil &&
                  showFinanceCouncilTab) ...[
                const SizedBox(height: 10),
                _FinanceCouncilReadOnlyNotice(role: userRole),
              ],
              SizedBox(height: isMobile ? 16 : 20),
              _ModeToggle(
                activeTab: _activeTab,
                onGeneralGroup: () => setState(() => _activeTab = _ConnectTab.generalGroup),
                onAlumniChat: () => setState(() => _activeTab = _ConnectTab.alumniChat),
                onFinanceCouncil: showFinanceCouncilTab
                    ? () => setState(() => _activeTab = _ConnectTab.financeCouncil)
                    : null,
                onCommittee: () => setState(() => _activeTab = _ConnectTab.executiveCommittee),
                fullWidth: isMobile,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              if (_activeTab == _ConnectTab.generalGroup)
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
                              else if (_activeTab == _ConnectTab.alumniChat)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final chatHeight = isMobile
                                        ? (MediaQuery.sizeOf(context).height * 0.58)
                                            .clamp(340.0, 620.0)
                                        : 620.0;

                                    return SizedBox(
                                      height: chatHeight,
                                      child: _AlumniChatPanel(
                                        messages: _alumniChatMessages,
                                        messageController: _messageController,
                                        onSend: (targets) =>
                                            _sendAlumniChatMessage(targets),
                                        posting: _posting,
                                        setupError: _error != null &&
                                            _isAlumniChatSetupError(_error!),
                                        compact: isMobile,
                                        isAdminViewer: isStaffRole(
                                          AuthSession.instance.currentUser?.role,
                                        ),
                                      ),
                                    );
                                  },
                                )
              else if (_activeTab == _ConnectTab.financeCouncil)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chatHeight = isMobile
                        ? (MediaQuery.sizeOf(context).height * 0.48)
                            .clamp(280.0, 480.0)
                        : 520.0;

                    return SizedBox(
                      height: chatHeight,
                      child: _FinanceCouncilPanel(
                        messages: _financeCouncilMessages,
                        messageController: _messageController,
                        onSend: _sendFinanceCouncilMessage,
                        canPost: canPostFinance,
                        posting: _posting,
                        setupError: _financeCouncilError != null &&
                            _isFinanceCouncilSetupError(_financeCouncilError!),
                        compact: isMobile,
                      ),
                    );
                  },
                )
                else
                  _CommitteePanel(
                    officers: _officers,
                    compact: isMobile,
                  ),
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
    required this.activeTab,
    required this.onGeneralGroup,
    required this.onAlumniChat,
    required this.onCommittee,
    this.onFinanceCouncil,
    this.fullWidth = false,
  });

  final _ConnectTab activeTab;
  final VoidCallback onGeneralGroup;
  final VoidCallback onAlumniChat;
  final VoidCallback? onFinanceCouncil;
  final VoidCallback onCommittee;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tabs = <(_ConnectTab, String, IconData, VoidCallback)>[
      (
        _ConnectTab.generalGroup,
        'General Group',
        Icons.campaign_outlined,
        onGeneralGroup,
      ),
      (
        _ConnectTab.alumniChat,
        'Alumni Chat',
        Icons.forum_outlined,
        onAlumniChat,
      ),
      if (onFinanceCouncil != null)
        (
          _ConnectTab.financeCouncil,
          'Finance Council',
          Icons.account_balance_outlined,
          onFinanceCouncil!,
        ),
      (
        _ConnectTab.executiveCommittee,
        'Executive Committee',
        Icons.shield_outlined,
        onCommittee,
      ),
    ];

    if (fullWidth) {
      return Column(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _ToggleChip(
                label: tabs[i].$2,
                icon: tabs[i].$3,
                selected: activeTab == tabs[i].$1,
                onTap: tabs[i].$4,
                expanded: true,
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final tab in tabs)
          _ToggleChip(
            label: tab.$2,
            icon: tab.$3,
            selected: activeTab == tab.$1,
            onTap: tab.$4,
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

class _FinanceCouncilReadOnlyNotice extends StatelessWidget {
  const _FinanceCouncilReadOnlyNotice({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D9A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined, size: 18, color: AppColors.heading),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are signed in as ${financeCouncilRoleLabel(role)} with view-only access. '
              'Only President, Vice President, and Treasurer can post in Finance Council.',
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

typedef _AlumniChatSend = void Function(AlumniChatTargets targets);

class _AlumniChatPanel extends StatefulWidget {
  const _AlumniChatPanel({
    required this.messages,
    required this.messageController,
    required this.onSend,
    required this.posting,
    this.setupError = false,
    this.compact = false,
    this.isAdminViewer = false,
  });

  final List<_ChatMessage> messages;
  final TextEditingController messageController;
  final _AlumniChatSend onSend;
  final bool posting;
  final bool setupError;
  final bool compact;
  final bool isAdminViewer;

  @override
  State<_AlumniChatPanel> createState() => _AlumniChatPanelState();
}

class _AlumniChatPanelState extends State<_AlumniChatPanel> {
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _targetOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _locationController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  AlumniChatTargets _currentTargets() {
    final batchText = _batchController.text.trim();
    return AlumniChatTargets(
      name: _emptyToNull(_nameController.text),
      batchYear: batchText.isEmpty ? null : int.tryParse(batchText),
      location: _emptyToNull(_locationController.text),
      specialization: _emptyToNull(_specialtyController.text),
    );
  }

  void _handleSend() {
    widget.onSend(_currentTargets());
  }

  void _clearTargets() {
    setState(() {
      _nameController.clear();
      _batchController.clear();
      _locationController.clear();
      _specialtyController.clear();
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String get _audiencePreview {
    final t = _currentTargets();
    final parts = <String>[];
    if (t.name != null) parts.add(t.name!);
    if (t.batchYear != null) parts.add('Batch ${t.batchYear}');
    if (t.specialization != null) parts.add(t.specialization!);
    if (t.location != null) parts.add(t.location!);
    if (parts.isEmpty) return 'To: everyone';
    return 'To: ${parts.join(' · ')}';
  }

  bool get _hasActiveTargets => _currentTargets().hasAny;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final messages = widget.messages;
    final posting = widget.posting;
    final setupError = widget.setupError;

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
                        'Alumni Chat',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 15 : 16,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '${messages.length} messages',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isAdminViewer
                      ? 'Members chat here. Targeted alerts go only to matching alumni — Admin sees all alerts.'
                      : 'Open chat for everyone, or Target an alert so only matching alumni see it.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: setupError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage_outlined,
                            size: 40,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Alumni Chat needs a one-time database setup.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run migration-018 and migration-020 in Supabase SQL Editor, then tap Retry.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.bodyText,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No messages yet. Say hello — or Target an alert to one batch.',
                            style: GoogleFonts.inter(color: AppColors.mutedText),
                            textAlign: TextAlign.center,
                          ),
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              compact ? 8 : 10,
              compact ? 12 : 16,
              compact ? 10 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _hasActiveTargets
                            ? const Color(0xFFFFF4E5)
                            : const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _hasActiveTargets
                              ? const Color(0xFFE8C48A)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasActiveTargets
                                ? Icons.campaign_outlined
                                : Icons.public_outlined,
                            size: 14,
                            color: _hasActiveTargets
                                ? AppColors.heading
                                : AppColors.mutedText,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact ? 160 : 280,
                            ),
                            child: Text(
                              _hasActiveTargets
                                  ? _audiencePreview.replaceFirst('To: ', '')
                                  : 'Everyone',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: posting
                          ? null
                          : () => setState(() => _targetOpen = !_targetOpen),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _targetOpen ? 'Done' : 'Set audience',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_hasActiveTargets) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: posting ? null : _clearTargets,
                        tooltip: 'Clear audience',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ],
                ),
                if (_targetOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2744).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A2744).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send to a group that matches these details. Empty fields are ignored.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.bodyText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChatTargetChipField(
                              controller: _nameController,
                              label: 'Name',
                              hint: 'Name',
                              icon: Icons.person_outline,
                              enabled: !posting,
                              onChanged: (_) => setState(() {}),
                            ),
                            _ChatTargetChipField(
                              controller: _batchController,
                              label: 'Batch',
                              hint: 'Batch',
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              enabled: !posting,
                              width: 96,
                              onChanged: (_) => setState(() {}),
                            ),
                            _ChatTargetChipField(
                              controller: _specialtyController,
                              label: 'Specialty',
                              hint: 'Specialty',
                              icon: Icons.medical_services_outlined,
                              enabled: !posting,
                              width: 130,
                              onChanged: (_) => setState(() {}),
                            ),
                            _ChatTargetChipField(
                              controller: _locationController,
                              label: 'Location',
                              hint: 'Location',
                              icon: Icons.place_outlined,
                              enabled: !posting,
                              width: 120,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasActiveTargets
                          ? const Color(0xFFE8C48A)
                          : AppColors.border,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.messageController,
                          enabled: !posting,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _handleSend(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.heading,
                          ),
                          decoration: InputDecoration(
                            hintText: _hasActiveTargets
                                ? 'Write an alert for this audience…'
                                : 'Message Alumni Chat…',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.mutedText,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F8F5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: posting ? null : _handleSend,
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: compact ? 44 : (_hasActiveTargets ? 108 : 88),
                            height: 44,
                            child: posting
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _hasActiveTargets
                                            ? Icons.campaign_rounded
                                            : Icons.send_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      if (!compact) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _hasActiveTargets ? 'Alert' : 'Send',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
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

class _ChatTargetChipField extends StatelessWidget {
  const _ChatTargetChipField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.onChanged,
    this.keyboardType,
    this.width = 118,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final double width;

  bool get _active => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.heading,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            size: 15,
            color: _active ? AppColors.primary : AppColors.mutedText,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 32),
          filled: true,
          fillColor: _active ? const Color(0xFFEAF0FA) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedText),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: _active ? const Color(0xFFB7C5DB) : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _FinanceCouncilPanel extends StatelessWidget {
  const _FinanceCouncilPanel({
    required this.messages,
    required this.messageController,
    required this.onSend,
    required this.canPost,
    required this.posting,
    this.setupError = false,
    this.compact = false,
  });

  final List<_ChatMessage> messages;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool canPost;
  final bool posting;
  final bool setupError;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D9A8)),
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
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: Color(0xFF8B6914),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Finance Council',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 15 : 16,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '${messages.length} messages',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Budgets, building repairs & financial approvals — President, VP & Treasurer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: setupError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage_outlined,
                            size: 40,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Finance Council needs a one-time database setup.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run migration-019-finance-council-chat.sql in Supabase SQL Editor, then tap Retry above.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.bodyText,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No messages yet. Discuss building repairs, budgets, and financial approvals here.',
                        style: GoogleFonts.inter(color: AppColors.mutedText),
                        textAlign: TextAlign.center,
                      ),
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
          if (canPost) ...[
            const Divider(height: 1),
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
                        hintText: 'Type a financial update or approval request',
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
                      color: const Color(0xFF8B6914),
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
                      label: Text(posting ? 'Sending...' : 'Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
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
    final narrow = DashboardLayout.isNarrow(context);

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
                if (narrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.author,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (message.badge != null)
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
                          Text(
                            message.time,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                if (message.isAlert && message.audienceLabel != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8C48A)),
                    ),
                    child: Text(
                      'Alert · ${message.audienceLabel}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                  ),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.isAlert
                        ? const Color(0xFFFFFBF5)
                        : AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                    border: message.isAlert
                        ? Border.all(color: const Color(0xFFE8C48A))
                        : null,
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

class _CommitteePanel extends StatefulWidget {
  const _CommitteePanel({
    required this.officers,
    this.compact = false,
  });

  final List<ConnectOfficer> officers;
  final bool compact;

  @override
  State<_CommitteePanel> createState() => _CommitteePanelState();
}

class _CommitteePanelState extends State<_CommitteePanel> {
  final _api = ConnectApiService();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  bool _loadingThreads = true;
  bool _loadingChat = false;
  bool _loadingMembers = false;
  bool _sending = false;
  String? _error;
  List<DmThreadItem> _threads = [];
  List<DmMemberCandidate> _memberResults = [];
  ConnectOfficer? _selectedPeer;
  String? _threadId;
  DmThreadItem? _activeThread;
  List<DmMessageItem> _messages = [];

  bool get _canStart => canStartExecutiveDmUser;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    if (_canStart) {
      _searchMembers('');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loadingThreads = true;
      _error = null;
    });
    try {
      final threads = await _api.fetchDmThreads();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loadingThreads = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingThreads = false;
      });
    }
  }

  Future<void> _searchMembers(String query) async {
    if (!_canStart) return;
    setState(() => _loadingMembers = true);
    try {
      final members = await _api.searchDmMembers(query: query);
      if (!mounted) return;
      setState(() {
        _memberResults = members;
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openMember(DmMemberCandidate member) async {
    if (!_canStart) return;
    final existing = _threads.where((t) => t.peerUserId == member.userId);
    if (existing.isNotEmpty) {
      await _openThread(existing.first);
      return;
    }
    setState(() {
      _selectedPeer = ConnectOfficer(
        userId: member.userId,
        email: '',
        role: 'member',
        roleLabel: member.batchYear != null
            ? 'Member · Batch ${member.batchYear}'
            : 'Member',
        initials: member.initials,
        fullName: member.fullName,
      );
      _loadingChat = false;
      _messages = [];
      _threadId = null;
      _activeThread = null;
      _error = null;
    });
  }

  Future<void> _openThread(DmThreadItem thread) async {
    ConnectOfficer? peer;
    for (final o in widget.officers) {
      if (o.userId == thread.peerUserId) {
        peer = o;
        break;
      }
    }
    peer ??= ConnectOfficer(
      userId: thread.peerUserId,
      email: '',
      role: 'member',
      roleLabel: thread.peerRoleLabel ?? 'Member',
      initials: thread.peerInitials,
      fullName: thread.peerName,
    );

    setState(() {
      _selectedPeer = peer;
      _loadingChat = true;
      _messages = [];
      _threadId = thread.id;
      _activeThread = thread;
      _error = null;
    });

    try {
      final conversation = await _api.fetchDmMessages(thread.id);
      if (!mounted) return;
      setState(() {
        _threadId = conversation.thread.id;
        _activeThread = conversation.thread;
        _messages = conversation.messages;
        _loadingChat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingChat = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    final peer = _selectedPeer;
    if (text.isEmpty || peer == null || _sending) return;
    if (_activeThread != null && !_activeThread!.canMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messaging is blocked for this conversation'),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }

    // Members cannot create a new thread — only reply on an existing one.
    if (_threadId == null && !_canStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An officer must message you first before you can reply.',
          ),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      if (_threadId == null) {
        final conversation = await _api.startDm(
          memberUserId: peer.userId,
          body: text,
        );
        _messageController.clear();
        await _loadThreads();
        if (!mounted) return;
        setState(() {
          _threadId = conversation.thread.id;
          _activeThread = conversation.thread;
          _messages = conversation.messages;
        });
      } else {
        await _api.sendDmReply(threadId: _threadId!, body: text);
        _messageController.clear();
        final conversation = await _api.fetchDmMessages(_threadId!);
        await _loadThreads();
        if (!mounted) return;
        setState(() {
          _activeThread = conversation.thread;
          _messages = conversation.messages;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleBlock() async {
    final peer = _selectedPeer;
    final thread = _activeThread;
    if (peer == null) return;
    try {
      if (thread?.iBlockedPeer == true) {
        await _api.unblockDmUser(peer.userId);
      } else {
        await _api.blockDmUser(peer.userId);
      }
      if (_threadId != null) {
        final conversation = await _api.fetchDmMessages(_threadId!);
        await _loadThreads();
        if (!mounted) return;
        setState(() {
          _activeThread = conversation.thread;
          _messages = conversation.messages;
        });
      } else {
        await _loadThreads();
        if (!mounted) return;
        setState(() {
          _activeThread = (_activeThread == null)
              ? null
              : DmThreadItem(
                  id: _activeThread!.id,
                  peerUserId: _activeThread!.peerUserId,
                  peerName: _activeThread!.peerName,
                  peerInitials: _activeThread!.peerInitials,
                  peerRoleLabel: _activeThread!.peerRoleLabel,
                  lastMessage: _activeThread!.lastMessage,
                  updatedAt: _activeThread!.updatedAt,
                  iBlockedPeer: !(thread?.iBlockedPeer ?? false),
                  peerBlockedMe: thread?.peerBlockedMe ?? false,
                  canMessage: thread?.iBlockedPeer == true,
                );
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (thread?.iBlockedPeer == true) ? 'User unblocked' : 'User blocked',
          ),
          backgroundColor: const Color(0xFF1F6B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _backToList() {
    setState(() {
      _selectedPeer = null;
      _threadId = null;
      _activeThread = null;
      _messages = [];
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    if (_selectedPeer != null) {
      return SizedBox(
        height: compact ? 420 : 480,
        child: _buildChat(compact),
      );
    }
    return _buildInbox(compact);
  }

  Widget _buildInbox(bool compact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 18,
              compact ? 12 : 14,
              compact ? 14 : 18,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Executive Committee DMs',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _canStart
                      ? 'Search a member and send the first message. Members reply after you start.'
                      : 'An officer will message you first. Conversations you can reply to show below.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingThreads)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null && _threads.isEmpty && !_canStart)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
            )
          else ...[
            if (_canStart) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 18,
                  10,
                  compact ? 14 : 18,
                  6,
                ),
                child: Text(
                  'Start a DM with a member',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedText,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 18,
                  0,
                  compact ? 14 : 18,
                  8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _searchMembers(value),
                  decoration: InputDecoration(
                    hintText: 'Search member by name…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9F8F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (_loadingMembers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: compact ? 160 : 200,
                  ),
                  child: _memberResults.isEmpty
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 14 : 18,
                            4,
                            compact ? 14 : 18,
                            12,
                          ),
                          child: Text(
                            'No members found.',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _memberResults.length,
                          itemBuilder: (context, index) {
                            final member = _memberResults[index];
                            return _DmMemberTile(
                              member: member,
                              onTap: () => _openMember(member),
                            );
                          },
                        ),
                ),
              const Divider(height: 1),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 18,
                10,
                compact ? 14 : 18,
                4,
              ),
              child: Text(
                _canStart ? 'Your conversations' : 'Your messages',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (_threads.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 18,
                  6,
                  compact ? 14 : 18,
                  16,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 20,
                        color: AppColors.mutedText.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _canStart
                              ? 'No conversations yet. Search a member above to start.'
                              : 'No messages yet. An officer must contact you first — then you can reply here.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.mutedText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: compact ? 220 : 280,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _threads.length,
                  itemBuilder: (context, index) {
                    final thread = _threads[index];
                    return _DmThreadTile(
                      thread: thread,
                      onTap: () => _openThread(thread),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChat(bool compact) {
    final peer = _selectedPeer!;
    final canCompose = _threadId != null || _canStart;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 12,
              compact ? 10 : 12,
              compact ? 12 : 16,
              compact ? 10 : 12,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _backToList,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    peer.initials,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                      Text(
                        _activeThread?.iBlockedPeer == true
                            ? 'Blocked · unblock to message again'
                            : _activeThread?.peerBlockedMe == true
                                ? 'You are blocked by this user'
                                : 'DM · ${peer.roleLabel}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') _toggleBlock();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Text(
                        _activeThread?.iBlockedPeer == true
                            ? 'Unblock'
                            : 'Block',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingChat
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            canCompose
                                ? 'Send the first message to start this private DM.'
                                : 'Waiting for an officer to start this conversation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(compact ? 14 : 18),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _DmBubble(message: message);
                        },
                      ),
          ),
          const Divider(height: 1),
          if (_activeThread != null && !_activeThread!.canMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                _activeThread!.iBlockedPeer
                    ? 'You blocked this user. Use Unblock to continue chatting.'
                    : 'You cannot send messages because this user blocked you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            )
          else if (!canCompose)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                'An officer must start this DM before you can reply.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 16,
                10,
                compact ? 12 : 16,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _threadId == null
                            ? 'Write your first DM…'
                            : 'Reply…',
                        filled: true,
                        fillColor: const Color(0xFFF9F8F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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

class _DmMemberTile extends StatelessWidget {
  const _DmMemberTile({required this.member, required this.onTap});

  final DmMemberCandidate member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          member.initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        member.fullName,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.heading,
        ),
      ),
      subtitle: Text(
        member.batchYear != null ? 'Batch ${member.batchYear}' : 'Member',
        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.mutedText),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Message',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DmThreadTile extends StatelessWidget {
  const _DmThreadTile({required this.thread, required this.onTap});

  final DmThreadItem thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          thread.peerInitials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        thread.peerName,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.heading,
        ),
      ),
      subtitle: Text(
        thread.lastMessage ?? (thread.peerRoleLabel ?? 'Direct message'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.mutedText),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
    );
  }
}

class _DmBubble extends StatelessWidget {
  const _DmBubble({required this.message});

  final DmMessageItem message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : const Color(0xFFF3F6FB),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
            Text(
              message.body,
              style: GoogleFonts.inter(
                color: mine ? Colors.white : AppColors.bodyText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: mine ? Colors.white70 : AppColors.mutedText,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _WhatsAppTicks(status: message.status, onDark: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppTicks extends StatelessWidget {
  const _WhatsAppTicks({required this.status, this.onDark = false});

  final String status;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // Yellow = sent/delivered, green = read (WhatsApp-style).
    final isRead = status == 'read';
    final isDelivered = status == 'delivered' || isRead;
    final color = isRead
        ? const Color(0xFF4ADE80)
        : (onDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706));

    return Icon(
      isDelivered ? Icons.done_all : Icons.done,
      size: 14,
      color: color,
    );
  }
}
