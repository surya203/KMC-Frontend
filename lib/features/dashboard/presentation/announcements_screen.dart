import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/announcements_api_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _api = AnnouncementsApiService();

  List<AnnouncementItem> _items = [];
  String? _error;
  bool _loading = true;
  String? _loadingDetailId;
  String? _expandedId;
  AnnouncementDetail? _expandedDetail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.fetchAnnouncements();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _toggleDetail(AnnouncementItem item) async {
    if (_expandedId == item.id) {
      setState(() {
        _expandedId = null;
        _expandedDetail = null;
      });
      return;
    }

    setState(() => _loadingDetailId = item.id);

    try {
      final detail = await _api.fetchAnnouncementById(item.id);
      if (!mounted) return;
      setState(() {
        _expandedId = item.id;
        _expandedDetail = detail;
        _loadingDetailId = null;
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index >= 0 && !item.isRead) {
          _items[index] = AnnouncementItem(
            id: item.id,
            title: item.title,
            authorRole: item.authorRole,
            publishedAt: item.publishedAt,
            expiresAt: item.expiresAt,
            isRead: true,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetailId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcements',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Office bearer messages and important notices.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No announcements yet.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else
                for (final item in _items) ...[
                  _AnnouncementCard(
                    item: item,
                    expanded: _expandedId == item.id,
                    detail: _expandedId == item.id ? _expandedDetail : null,
                    loadingDetail: _loadingDetailId == item.id,
                    onTap: () => _toggleDetail(item),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.expanded,
    required this.onTap,
    this.detail,
    this.loadingDetail = false,
  });

  final AnnouncementItem item;
  final bool expanded;
  final bool loadingDetail;
  final AnnouncementDetail? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.secondary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.authorRole.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(item.publishedAt),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              if (loadingDetail) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ] else if (expanded && detail != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  detail!.body,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
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
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 14),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
