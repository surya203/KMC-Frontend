import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.initials,
    required this.time,
    required this.text,
  });

  final String author;
  final String initials;
  final String time;
  final String text;
}

class _ChatChannel {
  const _ChatChannel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.messages,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<_ChatMessage> messages;
}

class _CommitteeMember {
  const _CommitteeMember({
    required this.name,
    required this.role,
    required this.initials,
    required this.preview,
    required this.time,
  });

  final String name;
  final String role;
  final String initials;
  final String preview;
  final String time;
}

class DashboardConnectScreen extends StatefulWidget {
  const DashboardConnectScreen({super.key});

  @override
  State<DashboardConnectScreen> createState() => _DashboardConnectScreenState();
}

class _DashboardConnectScreenState extends State<DashboardConnectScreen> {
  final _messageController = TextEditingController();

  static const _channels = <_ChatChannel>[
    _ChatChannel(
      id: 'general',
      name: '# General',
      subtitle: 'Open chat for all alumni',
      messages: [
        _ChatMessage(
          author: 'Dr. Priya Sharma',
          initials: 'PS',
          time: '09:12',
          text: 'Welcome everyone to the new MY KMC community!',
        ),
        _ChatMessage(
          author: 'Dr. Arjun Kumar',
          initials: 'AK',
          time: '09:18',
          text: 'Excited to reconnect with all of you 👋',
        ),
        _ChatMessage(
          author: 'Dr. Ramesh Reddy',
          initials: 'RR',
          time: '09:30',
          text: 'Reminder: Reunite & Reignite 2026 registrations open.',
        ),
      ],
    ),
    _ChatChannel(
      id: 'batch-2000',
      name: '# Batch 2000',
      subtitle: 'Silver Jubilee circle',
      messages: [
        _ChatMessage(
          author: 'Dr. Kavitha Rao',
          initials: 'KR',
          time: 'Mon',
          text: 'Who is joining the Hyderabad reunion this June?',
        ),
      ],
    ),
    _ChatChannel(
      id: 'cardiology',
      name: '# Cardiology',
      subtitle: 'Specialty discussions',
      messages: [
        _ChatMessage(
          author: 'Dr. Ramesh Reddy',
          initials: 'RR',
          time: 'Mon',
          text: "Sharing notes from last week's CME — DM for the deck.",
        ),
      ],
    ),
    _ChatChannel(
      id: 'overseas',
      name: '# Overseas KMC',
      subtitle: 'Alumni abroad',
      messages: [
        _ChatMessage(
          author: 'Dr. Ananya Iyer',
          initials: 'AI',
          time: 'Sun',
          text: 'London chapter meet-up planned for autumn — details soon.',
        ),
      ],
    ),
  ];

  static const _committee = <_CommitteeMember>[
    _CommitteeMember(
      name: 'Dr. Priya Sharma',
      role: 'President',
      initials: 'PS',
      preview: 'Thank you for reaching out. How can we help?',
      time: 'Yesterday',
    ),
    _CommitteeMember(
      name: 'Dr. Ramesh Reddy',
      role: 'Secretary',
      initials: 'RR',
      preview: 'Reunion logistics update attached.',
      time: 'Tue',
    ),
    _CommitteeMember(
      name: 'Dr. Arjun Kumar',
      role: 'Treasurer',
      initials: 'AK',
      preview: 'Membership receipt confirmed.',
      time: 'Mon',
    ),
  ];

  bool _communityTab = true;
  String _selectedChannelId = 'general';
  final Map<String, List<_ChatMessage>> _extraMessages = {};

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  _ChatChannel get _selectedChannel =>
      _channels.firstWhere((c) => c.id == _selectedChannelId);

  List<_ChatMessage> get _visibleMessages => [
        ..._selectedChannel.messages,
        ...?_extraMessages[_selectedChannelId],
      ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = AuthSession.instance.currentUser;
    final email = user?.email ?? 'member@kmc.alumni';
    final name = email.split('@').first;
    final initials = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'K';

    setState(() {
      _extraMessages.putIfAbsent(_selectedChannelId, () => []).add(
            _ChatMessage(
              author: 'You',
              initials: initials,
              time: 'Now',
              text: text,
            ),
          );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect',
                  style: GoogleFonts.fraunces(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chat with the alumni community or message Executive Committee members directly.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.bodyText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _ModeToggle(
                  communitySelected: _communityTab,
                  onCommunity: () => setState(() => _communityTab = true),
                  onCommittee: () => setState(() => _communityTab = false),
                ),
                const SizedBox(height: 20),
                if (_communityTab)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 760;
                      final channels = _ChannelList(
                        channels: _channels,
                        selectedId: _selectedChannelId,
                        onSelect: (id) {
                          setState(() => _selectedChannelId = id);
                        },
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            SizedBox(height: 240, child: channels),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 480,
                              child: _CommunityChatPanel(
                                channel: _selectedChannel,
                                messages: _visibleMessages,
                                messageController: _messageController,
                                onSend: _sendMessage,
                                inset: false,
                              ),
                            ),
                          ],
                        );
                      }

                      return SizedBox(
                        height: 520,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 260, child: channels),
                            Expanded(
                              child: _CommunityChatPanel(
                                channel: _selectedChannel,
                                messages: _visibleMessages,
                                messageController: _messageController,
                                onSend: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  _CommitteePanel(members: _committee),
              ],
            ),
          ),
        ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.communitySelected,
    required this.onCommunity,
    required this.onCommittee,
  });

  final bool communitySelected;
  final VoidCallback onCommunity;
  final VoidCallback onCommittee;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        _ToggleChip(
          label: 'Community',
          icon: Icons.people_outline_rounded,
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

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.heading,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelList extends StatelessWidget {
  const _ChannelList({
    required this.channels,
    required this.selectedId,
    required this.onSelect,
  });

  final List<_ChatChannel> channels;
  final String selectedId;
  final void Function(String id) onSelect;

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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text(
              'CHANNELS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.mutedText,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              children: [
                for (final channel in channels)
                  _ChannelTile(
                    channel: channel,
                    selected: channel.id == selectedId,
                    onTap: () => onSelect(channel.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final _ChatChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  channel.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: selected ? Colors.white70 : AppColors.mutedText,
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

class _CommunityChatPanel extends StatelessWidget {
  const _CommunityChatPanel({
    required this.channel,
    required this.messages,
    required this.messageController,
    required this.onSend,
    this.inset = true,
  });

  final _ChatChannel channel;
  final List<_ChatMessage> messages;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final channelLabel = channel.name.replaceFirst('# ', '#');

    return Container(
      margin: inset ? const EdgeInsets.only(left: 16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  channel.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.heading,
                  ),
                ),
                const Spacer(),
                Text(
                  '${messages.length} messages',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in messages)
                  _MessageBubble(message: message),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Message $channelLabel',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send'),
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
                    Text(
                      message.author,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
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
  const _CommitteePanel({required this.members});

  final List<_CommitteeMember> members;

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
            padding: const EdgeInsets.all(20),
            child: Text(
              'Executive Committee',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
          ),
          const Divider(height: 1),
          for (final member in members)
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    member.initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  member.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${member.role} · ${member.preview}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                  ),
                ),
                trailing: Text(
                  member.time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                onTap: () {},
              ),
            ),
        ],
      ),
    );
  }
}
