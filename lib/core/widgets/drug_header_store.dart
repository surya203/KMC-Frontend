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
  bool _lastLoadFailed = false;

  DrugHeaderCard? get card => _card;
  bool get loading => _loading;
  String? get headerImageUrl => _card?.headerImageUrl;

  Future<void> ensureLoaded() async {
    if (_loading) return;
    // Retry only after a failed fetch; a successful empty response stays cached.
    if (_loadedOnce && !_lastLoadFailed) return;
    await refresh();
  }

  Future<void> refresh({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    notifyListeners();
    try {
      _card = await _api.fetchHeaderCard();
      _loadedOnce = true;
      _lastLoadFailed = false;
    } catch (_) {
      _loadedOnce = true;
      _lastLoadFailed = true;
      // Keep last known good card on transient failures.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
