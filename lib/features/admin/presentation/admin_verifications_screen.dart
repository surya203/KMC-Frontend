import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_api_service.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  final _api = AdminApiService();

  List<VerificationQueueItem> _items = [];
  String? _error;
  bool _loading = true;
  String? _actingOnId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int attempt = 0}) async {
    await AuthSession.instance.ensureReady();

    if (!mounted) return;
    setState(() {
      _loading = attempt == 0;
      if (attempt == 0) _error = null;
    });

    try {
      final items = await _api.fetchPendingVerifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (attempt < 2 && _shouldRetry(e)) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        if (mounted) await _load(attempt: attempt + 1);
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

  Future<void> _review(VerificationQueueItem item, String action) async {
    String? notes;
    if (action == 'reject') {
      notes = await _promptNotes();
      if (notes == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Approve profile?'),
          content: Text('Approve ${item.fullName} (Batch ${item.batchYear})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _actingOnId = item.id);
    try {
      final message = await _api.reviewVerification(
        item.id,
        action: action,
        notes: notes,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.where((entry) => entry.id != item.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: action == 'approve'
              ? const Color(0xFF1F6B3A)
              : AppColors.heading,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatError(e)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  String _formatError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  Future<String?> _promptNotes() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional reason for the member',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        width < 375 ? 12 : 16,
        16,
        width < 375 ? 12 : 16,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification queue',
                style: GoogleFonts.fraunces(
                  fontSize: width < 375 ? 28 : 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review alumni profiles awaiting approval.',
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(
                  message: _formatError(_error!),
                  onRetry: _load,
                ),
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
                    'No pending verifications.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else
                for (final item in _items)
                  _VerificationCard(
                    item: item,
                    busy: _actingOnId == item.id,
                    onApprove: () => _review(item, 'approve'),
                    onReject: () => _review(item, 'reject'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationQueueItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stackActions = width < 600;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.fullName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Batch ${item.batchYear}'
            '${item.degree != null ? ' · ${item.degree}' : ''}'
            '${item.organization != null ? ' · ${item.organization}' : ''}',
            style: GoogleFonts.inter(color: AppColors.bodyText, fontSize: 14),
          ),
          if (item.email != null) ...[
            const SizedBox(height: 4),
            Text(
              item.email!,
              style: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          if (stackActions)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: 'Approve ${item.fullName}',
                  child: FilledButton(
                    onPressed: busy ? null : onApprove,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Reject ${item.fullName}',
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Approve ${item.fullName}',
                  child: FilledButton(
                    onPressed: busy ? null : onApprove,
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: 'Reject ${item.fullName}',
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
        ],
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
