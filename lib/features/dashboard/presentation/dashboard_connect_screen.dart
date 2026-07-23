import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/connect_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/download_file.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../widgets/dashboard_layout.dart';

/// KMC founded 1959 — batch years outside this range are not accepted.
const int _kMinBatchYear = 1959;

/// Audience pickers show only this many rows; the rest scroll inside the box.
const int _kCompactVisibleOptions = 3;
const double _kCompactOptionHeight = 44;
const double _kCompactListMaxHeight =
    _kCompactOptionHeight * _kCompactVisibleOptions;

List<int> _alumniBatchYears() {
  final now = DateTime.now().year;
  return [for (var year = now; year >= _kMinBatchYear; year--) year];
}

List<int> _parseValidBatchYears(Iterable<int> years) {
  final now = DateTime.now().year;
  final out = <int>{};
  for (final year in years) {
    if (year >= _kMinBatchYear && year <= now) out.add(year);
  }
  final sorted = out.toList()..sort((a, b) => b.compareTo(a));
  return sorted;
}

enum _ConnectTab { alumniChat, financeCouncil, executiveCommittee }

enum _ChatRoom { alumni, finance, executive }

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.authorId,
    required this.author,
    required this.initials,
    required this.time,
    required this.createdAt,
    required this.text,
    this.badge,
    this.audienceLabel,
    this.isAlert = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentSize,
    this.room = _ChatRoom.alumni,
  });

  final String id;
  final String authorId;
  final String author;
  final String initials;
  final String time;
  final DateTime createdAt;
  final String text;
  final String? badge;
  final String? audienceLabel;
  final bool isAlert;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMime;
  final int? attachmentSize;
  final _ChatRoom room;

  bool get hasAttachment =>
      id.isNotEmpty &&
      ((attachmentUrl != null && attachmentUrl!.trim().isNotEmpty) ||
          (attachmentName != null && attachmentName!.trim().isNotEmpty));

  bool get isMine {
    final me = AuthSession.instance.currentUser?.id;
    if (me == null || authorId.isEmpty) return false;
    return authorId == me;
  }

  factory _ChatMessage.fromCommunityMessage(
    CommunityMessageItem item, {
    _ChatRoom room = _ChatRoom.alumni,
  }) {
    return _ChatMessage(
      id: item.id,
      authorId: item.authorId,
      author: item.authorName,
      initials: item.authorInitials,
      time: _formatClockTime(item.createdAt),
      createdAt: item.createdAt,
      text: item.body,
      badge: item.authorRoleLabel ??
          (item.batchYear != null ? 'Batch ${item.batchYear}' : null),
      audienceLabel: item.audienceLabel,
      isAlert: item.isTargeted,
      attachmentUrl: item.attachmentUrl,
      attachmentName: item.attachmentName,
      attachmentMime: item.attachmentMime,
      attachmentSize: item.attachmentSize,
      room: room,
    );
  }
}

/// Alumni Chat keeps only the last 3 months from "now".
bool _isWithinAlumniRetention(DateTime createdAt) {
  final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 90));
  return createdAt.toUtc().isAfter(cutoff);
}

/// Indian Standard Time (UTC+05:30), independent of device timezone.
DateTime _toIst(DateTime value) {
  return value.toUtc().add(const Duration(hours: 5, minutes: 30));
}

const _istMonthNamesFull = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
DateTime _istDateOnly(DateTime value) {
  final ist = _toIst(value);
  return DateTime(ist.year, ist.month, ist.day);
}

/// Time only in IST, e.g. `18:24`.
String _formatClockTime(DateTime value) {
  final ist = _toIst(value);
  final hour = ist.hour.toString().padLeft(2, '0');
  final minute = ist.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// WhatsApp-style day label in IST: Today / Yesterday / 13 July 2026.
String _formatChatDayLabel(DateTime value) {
  final messageDay = _istDateOnly(value);
  final today = _istDateOnly(DateTime.now().toUtc());
  final yesterday = today.subtract(const Duration(days: 1));

  if (messageDay == today) return 'Today';
  if (messageDay == yesterday) return 'Yesterday';

  final day = messageDay.day.toString().padLeft(2, '0');
  final month = _istMonthNamesFull[messageDay.month - 1];
  return '$day $month ${messageDay.year}';
}

/// Build WhatsApp-style list for a reverse [ListView]: newest near bottom.
List<Widget> _buildWhatsAppChatChildren(List<_ChatMessage> newestFirst) {
  final chronological = newestFirst.reversed.toList();
  final chronologicalItems = <Widget>[];
  DateTime? lastDay;

  for (final message in chronological) {
    final day = _istDateOnly(message.createdAt);
    if (lastDay == null || day != lastDay) {
      chronologicalItems.add(
        _ChatDaySeparator(label: _formatChatDayLabel(message.createdAt)),
      );
      lastDay = day;
    }
    chronologicalItems.add(_MessageBubble(message: message));
  }

  // reverse:true ListView puts first child at the bottom.
  return chronologicalItems.reversed.toList();
}

/// Scrollable message area (parent must give a bounded height, e.g. [Expanded]).
Widget _buildChatMessageList({
  required BuildContext context,
  required List<_ChatMessage> messages,
  required bool compact,
}) {
  return ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
    child: ListView(
      reverse: true,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        8,
        compact ? 10 : 14,
        8,
      ),
      children: _buildWhatsAppChatChildren(messages),
    ),
  );
}

class _ChatDaySeparator extends StatelessWidget {
  const _ChatDaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFECE5DD),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF54656F),
            ),
          ),
        ),
      ),
    );
  }
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
  String? _executiveCommitteeError;
  _ConnectTab _activeTab = _ConnectTab.executiveCommittee;
  List<_ChatMessage> _alumniChatMessages = [];
  List<_ChatMessage> _financeCouncilMessages = [];
  List<_ChatMessage> _executiveCommitteeMessages = [];
  List<ConnectOfficer> _officers = [];
  String? _officersError;
  /// Keep EC group chat open across silent refreshes (after send), like WhatsApp.
  bool _ecGroupChatOpen = false;

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

  Future<void> _load({int attempt = 0, bool silent = false}) async {
    await AuthSession.instance.ensureReady();
    try {
      await AuthSession.instance.authService.fetchMe(allowRefresh: true);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      // Silent refresh keeps the current EC hub view (group chat / DM) mounted.
      if (!silent) {
        _loading = attempt == 0;
      }
      if (attempt == 0 && !silent) {
        _error = null;
        _financeCouncilError = null;
        _executiveCommitteeError = null;
        _officersError = null;
      }
    });

    try {
      List<CommunityMessageItem> communityMessages = [];
      List<CommunityMessageItem> financeCouncilMessages = [];
      List<CommunityMessageItem> executiveCommitteeMessages = [];
      List<ConnectOfficer> officers = [];
      Object? communityError;
      Object? financeCouncilError;
      Object? executiveCommitteeError;
      Object? officersError;
      final userRole = AuthSession.instance.currentUser?.role;
      final showFinanceCouncilTab = canViewFinanceCouncil(userRole);
      final showExecutiveCommitteeChat = canViewExecutiveCommittee(userRole);

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

      if (showExecutiveCommitteeChat) {
        try {
          executiveCommitteeMessages =
              await _api.fetchExecutiveCommitteeMessages();
        } catch (e) {
          executiveCommitteeError = e;
        }
      }

      try {
        officers = await _api.fetchOfficers();
      } catch (e) {
        officersError = e;
      }

      if (communityError != null &&
          !showFinanceCouncilTab &&
          !showExecutiveCommitteeChat &&
          officersError != null) {
        throw communityError;
      }

      if (!mounted) return;
      setState(() {
        _alumniChatMessages = communityMessages
            .where((m) => _isWithinAlumniRetention(m.createdAt))
            .map(
              (m) => _ChatMessage.fromCommunityMessage(
                m,
                room: _ChatRoom.alumni,
              ),
            )
            .toList();
        _financeCouncilMessages = financeCouncilMessages
            .map(
              (m) => _ChatMessage.fromCommunityMessage(
                m,
                room: _ChatRoom.finance,
              ),
            )
            .toList();
        _executiveCommitteeMessages = executiveCommitteeMessages
            .map(
              (m) => _ChatMessage.fromCommunityMessage(
                m,
                room: _ChatRoom.executive,
              ),
            )
            .toList();
        _officers = officers;
        _loading = false;
        _financeCouncilError = financeCouncilError != null && showFinanceCouncilTab
            ? _formatError(financeCouncilError)
            : null;
        _executiveCommitteeError =
            executiveCommitteeError != null && showExecutiveCommitteeChat
                ? _formatError(executiveCommitteeError)
                : null;
        _officersError =
            officersError != null ? _formatError(officersError) : null;
        _error = communityError != null
            ? 'Alumni Chat unavailable. ${_formatError(communityError)}'
            : null;
      });
    } catch (e) {
      if (attempt < 2) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        if (mounted) await _load(attempt: attempt + 1, silent: silent);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = _formatError(e);
        _loading = false;
      });
    }
  }

  Future<void> _sendAlumniChatMessage([
    AlumniChatTargets? targets,
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    final text = _messageController.text.trim();
    final hasFile = fileBytes != null && fileBytes.isNotEmpty && fileName != null;
    if ((text.isEmpty && !hasFile) || _posting) return;

    setState(() => _posting = true);
    try {
      await _api.postCommunityMessage(
        text,
        targets,
        fileBytes,
        fileName,
      );
      _messageController.clear();
      // Stay in Alumni Chat — WhatsApp-style, no full-page reload after send.
      await _load(silent: true);
      if (!mounted) return;
      final targeted = targets?.hasAny ?? false;
      if (targeted || hasFile) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targeted
                  ? 'Alert sent only to matching alumni'
                  : 'Document sent to Alumni Chat',
            ),
            backgroundColor: const Color(0xFF1F6B3A),
          ),
        );
      }
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

  Future<void> _sendFinanceCouncilMessage([
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    final text = _messageController.text.trim();
    final hasFile = fileBytes != null && fileBytes.isNotEmpty && fileName != null;
    if ((text.isEmpty && !hasFile) || _posting) return;

    setState(() => _posting = true);
    try {
      await _api.postFinanceCouncilMessage(text, fileBytes, fileName);
      _messageController.clear();
      // Stay in Financial Decisions — no full-page reload after send.
      await _load(silent: true);
      if (!mounted) return;
      if (hasFile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document sent to Financial Decisions'),
            backgroundColor: Color(0xFF1F6B3A),
          ),
        );
      }
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

  Future<void> _sendExecutiveCommitteeMessage([
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    final text = _messageController.text.trim();
    final hasFile = fileBytes != null && fileBytes.isNotEmpty && fileName != null;
    if ((text.isEmpty && !hasFile) || _posting) return;

    setState(() => _posting = true);
    try {
      await _api.postExecutiveCommitteeMessage(text, fileBytes, fileName);
      _messageController.clear();
      // Stay in EC group chat — never full-page reload after send.
      await _load(silent: true);
      if (!mounted) return;
      if (hasFile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document sent to Executive Committee Chat'),
            backgroundColor: Color(0xFF1F6B3A),
          ),
        );
      }
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
        lower.contains('migration-022') ||
        lower.contains('attachment') ||
        lower.contains('database setup');
  }

  bool _isFinanceCouncilSetupError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('finance_council_messages') ||
        lower.contains('migration-019') ||
        lower.contains('migration-025') ||
        lower.contains('database setup');
  }

  bool _isExecutiveCommitteeSetupError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('executive_committee_messages') ||
        lower.contains('migration-025') ||
        lower.contains('database setup');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = DashboardLayout.isCompact(context);
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final userRole = AuthSession.instance.currentUser?.role;
    final canPostFinance = canPostToFinanceCouncil(userRole);
    final showFinanceCouncilTab = canViewFinanceCouncil(userRole);
    final canAccessExecutiveCommittee =
        canViewExecutiveCommittee(userRole) || isEcMemberUser();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // WhatsApp-style: tabs stay fixed; only the chat body scrolls.
    // Avoid Center+Column+Expanded (shrinks width → vertical "Message" text).
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isMobile ? 12 : 20,
        horizontalPadding,
        isMobile ? 12 : 16,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              if (!isMobile) ...[
                Text(
                  'Connect',
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                _activeTab == _ConnectTab.alumniChat
                    ? 'Any member can start chat here and Executive Committee member can discuss further.'
                    : _activeTab == _ConnectTab.financeCouncil
                        ? 'Financial decisions between President, General Secretary, Finance Secretary and Treasurer.'
                        : canAccessExecutiveCommittee
                            ? 'View EC members and open EC Group Chat. Messages and documents are kept permanently.'
                            : 'View who is on the Executive Committee. Only EC members can open EC Group Chat.',
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
              if (_officersError != null &&
                  _activeTab == _ConnectTab.executiveCommittee) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: _officersError!, onRetry: _load),
              ],
              if (_financeCouncilError != null &&
                  _activeTab == _ConnectTab.financeCouncil) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: _financeCouncilError!, onRetry: _load),
              ],
              if (_executiveCommitteeError != null &&
                  _activeTab == _ConnectTab.executiveCommittee &&
                  canAccessExecutiveCommittee) ...[
                const SizedBox(height: 10),
                _ErrorBanner(
                  message: _executiveCommitteeError!,
                  onRetry: _load,
                ),
              ],
              SizedBox(height: isMobile ? 12 : 16),
              _ModeToggle(
                activeTab: _activeTab,
                onAlumniChat: () =>
                    setState(() => _activeTab = _ConnectTab.alumniChat),
                onFinanceCouncil: showFinanceCouncilTab
                    ? () => setState(
                          () => _activeTab = _ConnectTab.financeCouncil,
                        )
                    : null,
                onCommittee: () => setState(
                  () => _activeTab = _ConnectTab.executiveCommittee,
                ),
                fullWidth: isMobile,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Expanded(
                child: _activeTab == _ConnectTab.alumniChat
                    ? _AlumniChatPanel(
                        messages: _alumniChatMessages,
                        messageController: _messageController,
                        onSend: (targets, {fileBytes, fileName}) =>
                            _sendAlumniChatMessage(
                              targets,
                              fileBytes,
                              fileName,
                            ),
                        posting: _posting,
                        setupError: _error != null &&
                            _isAlumniChatSetupError(_error!),
                        compact: isMobile,
                        isAdminViewer: isStaffRole(
                          AuthSession.instance.currentUser?.role,
                        ),
                      )
                    : _activeTab == _ConnectTab.financeCouncil
                        ? _FinanceCouncilPanel(
                            messages: _financeCouncilMessages,
                            messageController: _messageController,
                            onSend: ({fileBytes, fileName}) =>
                                _sendFinanceCouncilMessage(
                                  fileBytes,
                                  fileName,
                                ),
                            canPost: canPostFinance,
                            posting: _posting,
                            setupError: _financeCouncilError != null &&
                                _isFinanceCouncilSetupError(
                                  _financeCouncilError!,
                                ),
                            compact: isMobile,
                          )
                        : _ExecutiveCommitteeHub(
                            officers: _officers,
                            isEcMember: canAccessExecutiveCommittee,
                            groupChatOpen: _ecGroupChatOpen,
                            onGroupChatOpenChanged: (open) {
                              setState(() => _ecGroupChatOpen = open);
                            },
                            groupMessages: _executiveCommitteeMessages,
                            groupMessageController: _messageController,
                            onSendGroup: ({fileBytes, fileName}) =>
                                _sendExecutiveCommitteeMessage(
                                  fileBytes,
                                  fileName,
                                ),
                            groupPosting: _posting,
                            groupSetupError:
                                _executiveCommitteeError != null &&
                                    _isExecutiveCommitteeSetupError(
                                      _executiveCommitteeError!,
                                    ),
                            onRefreshGroup: () => _load(silent: true),
                            compact: isMobile,
                          ),
              ),
            ],
          ),
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
    required this.onAlumniChat,
    required this.onCommittee,
    this.onFinanceCouncil,
    this.fullWidth = false,
  });

  final _ConnectTab activeTab;
  final VoidCallback onAlumniChat;
  final VoidCallback? onFinanceCouncil;
  final VoidCallback onCommittee;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tabs = <(_ConnectTab, String, IconData, VoidCallback)>[
      (
        _ConnectTab.alumniChat,
        'Alumni Chat',
        Icons.forum_outlined,
        onAlumniChat,
      ),
      if (onFinanceCouncil != null)
        (
          _ConnectTab.financeCouncil,
          'Financial Decisions',
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

typedef _AlumniChatSend = void Function(
  AlumniChatTargets targets, {
  List<int>? fileBytes,
  String? fileName,
});

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
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final Set<int> _selectedBatchYears = <int>{};
  bool _targetOpen = false;
  List<int>? _pendingFileBytes;
  String? _pendingFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  AlumniChatTargets _currentTargets() {
    final years = _parseValidBatchYears(_selectedBatchYears);
    return AlumniChatTargets(
      name: _emptyToNull(_nameController.text),
      batchYear: years.isEmpty ? null : years.first,
      batchYears: years.isEmpty ? null : years,
      location: _emptyToNull(_locationController.text),
      specialization: _emptyToNull(_specialtyController.text),
    );
  }

  void _handleSend() {
    final pendingBytes = _pendingFileBytes;
    final pendingName = _pendingFileName;
    final hasFile =
        pendingBytes != null &&
        pendingBytes.isNotEmpty &&
        (pendingName?.isNotEmpty ?? false);
    if (widget.messageController.text.trim().isEmpty && !hasFile) return;
    if (widget.posting) return;

    // Keep a copy so clearing UI state cannot drop the upload.
    final bytesCopy = hasFile ? List<int>.from(pendingBytes) : null;
    final nameCopy = hasFile ? pendingName : null;

    widget.onSend(
      _currentTargets(),
      fileBytes: bytesCopy,
      fileName: nameCopy,
    );
    setState(() {
      _pendingFileBytes = null;
      _pendingFileName = null;
    });
  }

  Future<void> _pickDocument() async {
    if (widget.posting) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try again.')),
      );
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File must be 10 MB or smaller.')),
      );
      return;
    }
    setState(() {
      _pendingFileBytes = bytes;
      _pendingFileName = file.name;
    });
  }

  void _clearPendingFile() {
    setState(() {
      _pendingFileBytes = null;
      _pendingFileName = null;
    });
  }

  void _clearTargets() {
    setState(() {
      _nameController.clear();
      _selectedBatchYears.clear();
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
    final years = t.resolvedBatchYears;
    if (years.length == 1) {
      parts.add('Batch ${years.first}');
    } else if (years.length > 1) {
      parts.add('Batch ${years.join(', ')}');
    }
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
                      ? 'Members chat here. Messages older than 3 months are removed. Targeted alerts go only to matching alumni — Admin sees all alerts.'
                      : 'Alumni chat will be deleted in 3 months',
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
                            'Run migration-018, migration-020 and migration-022 in Supabase SQL Editor, then tap Retry.',
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
                            'No messages yet. Say hello - or Target an alert to one batch.',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildChatMessageList(
                        context: context,
                        messages: messages,
                        compact: compact,
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
                            _ChatTargetNameAutocomplete(
                              controller: _nameController,
                              enabled: !posting,
                              onChanged: () => setState(() {}),
                            ),
                            _ChatTargetBatchYearField(
                              selectedYears: _selectedBatchYears,
                              enabled: !posting,
                              onChanged: (years) {
                                setState(() {
                                  _selectedBatchYears
                                    ..clear()
                                    ..addAll(years);
                                });
                              },
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
                if (_pendingFileName != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0E8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pendingFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: posting ? null : _clearPendingFile,
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove file',
                        ),
                      ],
                    ),
                  ),
                ],
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
                      IconButton(
                        onPressed: posting ? null : _pickDocument,
                        tooltip: 'Attach document',
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: AppColors.primary,
                        ),
                      ),
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
                                ? 'Write an alert…'
                                : (compact
                                    ? 'Message or attach a file'
                                    : 'Message optional — attach a file to send'),
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.mutedText,
                              fontSize: 14,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF9F8F5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
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

class _ChatTargetNameAutocomplete extends StatefulWidget {
  const _ChatTargetNameAutocomplete({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  State<_ChatTargetNameAutocomplete> createState() =>
      _ChatTargetNameAutocompleteState();
}

class _ChatTargetNameAutocompleteState
    extends State<_ChatTargetNameAutocomplete> {
  final _profilesApi = ProfilesApiService();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<DirectoryProfile> _results = const [];
  bool _loading = false;
  bool _pickedFromList = false;
  int _searchToken = 0;

  bool get _active => widget.controller.text.trim().isNotEmpty;
  bool get _showResults =>
      _focusNode.hasFocus &&
      widget.controller.text.trim().length >= 2 &&
      !_pickedFromList;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _pickedFromList = false;
        _scheduleSearch();
      }
      if (mounted) setState(() {});
    });
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _ChatTargetNameAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _pickedFromList = false;
    widget.onChanged();
    _scheduleSearch();
    if (mounted) setState(() {});
  }

  void _scheduleSearch() {
    final query = widget.controller.text.trim();
    final token = ++_searchToken;
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    Future<void>.delayed(const Duration(milliseconds: 220), () async {
      if (!mounted || token != _searchToken) return;
      try {
        final page = await _profilesApi.fetchDirectory(
          search: query,
          pageSize: 24,
        );
        if (!mounted || token != _searchToken) return;
        final seen = <String>{};
        final profiles = page.profiles.where((profile) {
          final name = profile.fullName.trim();
          if (name.isEmpty) return false;
          return seen.add(name.toLowerCase());
        }).toList(growable: false);
        setState(() {
          _results = profiles;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || token != _searchToken) return;
        setState(() {
          _results = const [];
          _loading = false;
        });
      }
    });
  }

  void _selectProfile(DirectoryProfile profile) {
    _pickedFromList = true;
    widget.controller.text = profile.fullName;
    widget.controller.selection = TextSelection.collapsed(
      offset: profile.fullName.length,
    );
    widget.onChanged();
    setState(() {
      _results = const [];
    });
    _focusNode.unfocus();
  }

  InputDecoration _decoration() {
    return InputDecoration(
      isDense: true,
      hintText: 'Name',
      prefixIcon: Icon(
        Icons.person_outline,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.heading,
            ),
            decoration: _decoration(),
          ),
          if (_showResults) ...[
            const SizedBox(height: 6),
            _CompactScrollPanel(
              scrollController: _scrollController,
              child: _loading
                  ? const SizedBox(
                      height: _kCompactOptionHeight,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _results.isEmpty
                      ? SizedBox(
                          height: _kCompactOptionHeight,
                          child: Center(
                            child: Text(
                              'No members found',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final profile = _results[index];
                            return SizedBox(
                              height: _kCompactOptionHeight,
                              child: InkWell(
                                onTap: () => _selectProfile(profile),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          profile.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Batch ${profile.batchYear}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatTargetBatchYearField extends StatefulWidget {
  const _ChatTargetBatchYearField({
    required this.selectedYears,
    required this.enabled,
    required this.onChanged,
  });

  final Set<int> selectedYears;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  @override
  State<_ChatTargetBatchYearField> createState() =>
      _ChatTargetBatchYearFieldState();
}

class _ChatTargetBatchYearFieldState extends State<_ChatTargetBatchYearField> {
  final _scrollController = ScrollController();
  bool _open = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _active => widget.selectedYears.isNotEmpty;

  String get _label {
    final years = _parseValidBatchYears(widget.selectedYears);
    if (years.isEmpty) return 'Batch';
    if (years.length == 1) return '${years.first}';
    return '${years.first} +${years.length - 1}';
  }

  void _toggleYear(int year) {
    final next = Set<int>.from(widget.selectedYears);
    if (!next.add(year)) {
      next.remove(year);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final years = _alumniBatchYears();

    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: _active ? const Color(0xFFEAF0FA) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.enabled
                  ? () => setState(() => _open = !_open)
                  : null,
              child: InputDecorator(
                isFocused: _open,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: _active ? AppColors.primary : AppColors.mutedText,
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 34, minHeight: 32),
                  suffixIcon: Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: _active ? AppColors.primary : AppColors.mutedText,
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 28, minHeight: 32),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.fromLTRB(0, 8, 4, 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color:
                          _active ? const Color(0xFFB7C5DB) : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _active ? AppColors.heading : AppColors.mutedText,
                  ),
                ),
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 6),
            _CompactScrollPanel(
              scrollController: _scrollController,
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: years.length + 1,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final anySelected = widget.selectedYears.isEmpty;
                    return SizedBox(
                      height: _kCompactOptionHeight,
                      child: InkWell(
                        onTap: () {
                          widget.onChanged(<int>{});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                anySelected
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 18,
                                color: anySelected
                                    ? AppColors.primary
                                    : AppColors.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Any',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final year = years[index - 1];
                  final selected = widget.selectedYears.contains(year);
                  return SizedBox(
                    height: _kCompactOptionHeight,
                    child: InkWell(
                      onTap: () => _toggleYear(year),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.mutedText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$year',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small fixed-height box (3 rows) with a visible scrollbar.
class _CompactScrollPanel extends StatelessWidget {
  const _CompactScrollPanel({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: _kCompactListMaxHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A2744).withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 5,
          radius: const Radius.circular(8),
          child: child,
        ),
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
    this.width = 118,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final double width;

  bool get _active => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
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

class _FinanceCouncilPanel extends StatefulWidget {
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
  final Future<void> Function({List<int>? fileBytes, String? fileName}) onSend;
  final bool canPost;
  final bool posting;
  final bool setupError;
  final bool compact;

  @override
  State<_FinanceCouncilPanel> createState() => _FinanceCouncilPanelState();
}

class _FinanceCouncilPanelState extends State<_FinanceCouncilPanel> {
  List<int>? _pendingFileBytes;
  String? _pendingFileName;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try again.')),
      );
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File must be 10 MB or smaller.')),
      );
      return;
    }
    setState(() {
      _pendingFileBytes = bytes;
      _pendingFileName = file.name;
    });
  }

  void _clearPendingFile() {
    setState(() {
      _pendingFileBytes = null;
      _pendingFileName = null;
    });
  }

  Future<void> _handleSend() async {
    final bytes = _pendingFileBytes;
    final name = _pendingFileName;
    await widget.onSend(fileBytes: bytes, fileName: name);
    if (!mounted) return;
    _clearPendingFile();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final messages = widget.messages;
    final posting = widget.posting;
    final canPost = widget.canPost;
    final setupError = widget.setupError;

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
                        'Financial Decisions',
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
                  'Budgets, Alumni building & financial approvals — share documents here',
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
                            'Financial Decisions needs a one-time database setup.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run migration-019 and migration-025 in Supabase SQL Editor, then tap Retry above.',
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
                            'No messages yet. Discuss Alumni building, budgets and financial approvals here.',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildChatMessageList(
                        context: context,
                        messages: messages,
                        compact: compact,
                      ),
          ),
          if (canPost) ...[
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
                  if (_pendingFileName != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 18,
                            color: Color(0xFF8B6914),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pendingFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: posting ? null : _clearPendingFile,
                            icon: const Icon(Icons.close, size: 18),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Remove file',
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: posting ? null : _pickDocument,
                          tooltip: 'Attach document',
                          icon: const Icon(
                            Icons.attach_file_rounded,
                            color: Color(0xFF8B6914),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: widget.messageController,
                            enabled: !posting,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _handleSend(),
                            decoration: InputDecoration(
                              hintText:
                                  'Message optional — attach a file to send',
                              filled: true,
                              fillColor: AppColors.background,
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
                          color: const Color(0xFF8B6914),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: posting ? null : _handleSend,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: compact ? 44 : 88,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        if (!compact) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            'Send',
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
        ],
      ),
    );
  }
}

class _ExecutiveCommitteeHub extends StatefulWidget {
  const _ExecutiveCommitteeHub({
    required this.officers,
    required this.isEcMember,
    required this.groupChatOpen,
    required this.onGroupChatOpenChanged,
    required this.groupMessages,
    required this.groupMessageController,
    required this.onSendGroup,
    required this.groupPosting,
    required this.groupSetupError,
    required this.onRefreshGroup,
    this.compact = false,
  });

  final List<ConnectOfficer> officers;
  final bool isEcMember;
  final bool groupChatOpen;
  final ValueChanged<bool> onGroupChatOpenChanged;
  final List<_ChatMessage> groupMessages;
  final TextEditingController groupMessageController;
  final Future<void> Function({List<int>? fileBytes, String? fileName})
      onSendGroup;
  final bool groupPosting;
  final bool groupSetupError;
  final Future<void> Function() onRefreshGroup;
  final bool compact;

  @override
  State<_ExecutiveCommitteeHub> createState() => _ExecutiveCommitteeHubState();
}

class _ExecutiveCommitteeHubState extends State<_ExecutiveCommitteeHub> {
  Future<void> _openGroupChat() async {
    widget.onGroupChatOpenChanged(true);
    try {
      await widget.onRefreshGroup();
    } catch (_) {
      // Stay in group chat even if refresh fails.
    }
  }

  void _backToDirectory() {
    widget.onGroupChatOpenChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;

    if (widget.groupChatOpen && widget.isEcMember) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _backToDirectory,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to members'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _ExecutiveCommitteeChatPanel(
              messages: widget.groupMessages,
              messageController: widget.groupMessageController,
              onSend: widget.onSendGroup,
              posting: widget.groupPosting,
              setupError: widget.groupSetupError,
              compact: compact,
            ),
          ),
        ],
      );
    }

    return _EcMemberDirectory(
      officers: widget.officers,
      isEcMember: widget.isEcMember,
      compact: compact,
      onOpenGroupChat: widget.isEcMember ? _openGroupChat : null,
    );
  }
}

class _EcMemberDirectory extends StatelessWidget {
  const _EcMemberDirectory({
    required this.officers,
    required this.isEcMember,
    required this.compact,
    this.onOpenGroupChat,
  });

  final List<ConnectOfficer> officers;
  final bool isEcMember;
  final bool compact;
  final VoidCallback? onOpenGroupChat;

  @override
  Widget build(BuildContext context) {
    final me = AuthSession.instance.currentUser?.id;
    // Non-EC must never see Committee Chat — re-check role here.
    final canOpenCommitteeChat =
        isEcMember &&
        onOpenGroupChat != null &&
        canViewExecutiveCommittee(AuthSession.instance.currentUser?.role);

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
                    const Icon(
                      Icons.groups_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Executive Committee Members',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 15 : 16,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    Text(
                      '${officers.length} member${officers.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  canOpenCommitteeChat
                      ? 'Browse all EC posts below (President → Executives), then open EC Group Chat.'
                      : 'Browse the full Executive Committee (all posts) listed below.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
                if (canOpenCommitteeChat) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: compact ? double.infinity : null,
                    child: FilledButton.icon(
                      onPressed: onOpenGroupChat,
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: const Text('EC Group Chat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          if (officers.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'No Executive Committee members are listed yet. Ask Admin to assign EC roles.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.mutedText),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 14,
                  4,
                  compact ? 10 : 14,
                  compact ? 8 : 10,
                ),
                itemCount: officers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final officer = officers[index];
                  final isMe = me != null && officer.userId == me;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          networkUrl: officer.photoUrl,
                          name: officer.displayName,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                officer.displayName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.heading,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F6FB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  officer.roleLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'You',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ExecutiveCommitteeChatPanel extends StatefulWidget {
  const _ExecutiveCommitteeChatPanel({
    required this.messages,
    required this.messageController,
    required this.onSend,
    required this.posting,
    this.setupError = false,
    this.compact = false,
  });

  final List<_ChatMessage> messages;
  final TextEditingController messageController;
  final Future<void> Function({List<int>? fileBytes, String? fileName}) onSend;
  final bool posting;
  final bool setupError;
  final bool compact;

  @override
  State<_ExecutiveCommitteeChatPanel> createState() =>
      _ExecutiveCommitteeChatPanelState();
}

class _ExecutiveCommitteeChatPanelState
    extends State<_ExecutiveCommitteeChatPanel> {
  List<int>? _pendingFileBytes;
  String? _pendingFileName;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try again.')),
      );
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File must be 10 MB or smaller.')),
      );
      return;
    }
    setState(() {
      _pendingFileBytes = bytes;
      _pendingFileName = file.name;
    });
  }

  void _clearPendingFile() {
    setState(() {
      _pendingFileBytes = null;
      _pendingFileName = null;
    });
  }

  Future<void> _handleSend() async {
    final bytes = _pendingFileBytes;
    final name = _pendingFileName;
    await widget.onSend(fileBytes: bytes, fileName: name);
    if (!mounted) return;
    _clearPendingFile();
  }

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
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EC Group Chat',
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
                  'Private chat for EC members — documents kept permanently.',
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
                            'Executive Committee Chat needs a one-time database setup.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run migration-025-ec-chat-finance-docs.sql in Supabase SQL Editor, then tap Retry.',
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
                            'No messages yet. Open this chat to message all EC members and share documents.',
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildChatMessageList(
                        context: context,
                        messages: messages,
                        compact: compact,
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
                if (_pendingFileName != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0E8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pendingFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: posting ? null : _clearPendingFile,
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove file',
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: posting ? null : _pickDocument,
                        tooltip: 'Attach document',
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.messageController,
                          enabled: !posting,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText:
                                'Message optional — attach a file to send',
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
                            width: compact ? 44 : 88,
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
                                      const Icon(
                                        Icons.send_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      if (!compact) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          'Send',
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final bubbleColor = mine
        ? const Color(0xFFDCF8C6)
        : (message.isAlert ? const Color(0xFFFFF4E5) : Colors.white);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine) ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (message.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (message.isAlert && message.audienceLabel != null) ...[
                Text(
                  'Alert · ${message.audienceLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (message.hasAttachment) ...[
                _ChatAttachmentCard(
                  messageId: message.id,
                  room: message.room,
                  url: message.attachmentUrl,
                  name: message.attachmentName ?? 'Document',
                  mime: message.attachmentMime,
                  size: message.attachmentSize,
                ),
                if (message.text.trim().isNotEmpty) const SizedBox(height: 8),
              ],
              if (message.text.trim().isNotEmpty)
                Text(
                  message.text,
                  style: GoogleFonts.inter(
                    color: AppColors.bodyText,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                message.time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAttachmentCard extends StatefulWidget {
  const _ChatAttachmentCard({
    required this.messageId,
    required this.name,
    required this.room,
    this.url,
    this.mime,
    this.size,
  });

  final String messageId;
  final String name;
  final _ChatRoom room;
  final String? url;
  final String? mime;
  final int? size;

  @override
  State<_ChatAttachmentCard> createState() => _ChatAttachmentCardState();
}

class _ChatAttachmentCardState extends State<_ChatAttachmentCard> {
  bool _downloading = false;
  final _api = ConnectApiService();

  String get _sizeLabel {
    final bytes = widget.size;
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    var ok = false;
    try {
      final result = switch (widget.room) {
        _ChatRoom.alumni =>
          await _api.downloadCommunityAttachment(widget.messageId),
        _ChatRoom.finance =>
          await _api.downloadFinanceCouncilAttachment(widget.messageId),
        _ChatRoom.executive =>
          await _api.downloadExecutiveCommitteeAttachment(widget.messageId),
      };
      await downloadBytes(
        result.bytes,
        result.fileName,
        mimeType: result.mimeType,
      );
      ok = true;
    } catch (_) {
      final url = widget.url;
      if (url != null && url.isNotEmpty) {
        ok = await downloadFromUrl(url, filename: widget.name);
      }
    }
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Download started' : 'Download failed'),
        backgroundColor: ok ? const Color(0xFF1F6B3A) : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F4EC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _downloading ? null : _download,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                    if (_sizeLabel.isNotEmpty)
                      Text(
                        _sizeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              if (_downloading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _download,
                  tooltip: 'Download',
                  icon: const Icon(Icons.download_rounded),
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
