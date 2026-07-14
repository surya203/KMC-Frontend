import 'package:flutter/foundation.dart';

import '../network/drugs_api_service.dart';

/// Shared featured drug header image for dashboard/admin chrome.
/// Refresh after admin creates/updates/deletes so sidebar + header stay in sync.
class DrugHeaderStore extends ChangeNotifier {
  DrugHeaderStore._();

  static final DrugHeaderStore instance = DrugHeaderStore._();

  final _api = DrugsApiService();

  DrugHeaderCard? _card;
  bool _loading = false;
  bool _loadedOnce = false;

  DrugHeaderCard? get card => _card;
  bool get loading => _loading;
  String? get headerImageUrl => _card?.headerImageUrl;

  Future<void> ensureLoaded() async {
    if (_loadedOnce || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _card = await _api.fetchHeaderCard();
      _loadedOnce = true;
    } catch (_) {
      // Keep last known card on transient failures.
      _loadedOnce = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
