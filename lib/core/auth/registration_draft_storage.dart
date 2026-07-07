import 'package:shared_preferences/shared_preferences.dart';

class RegistrationDraftStorage {
  RegistrationDraftStorage({this._prefs});

  SharedPreferences? _prefs;

  static const _draftIdKey = 'kmc_registration_draft_id';
  static const _wizardStepKey = 'kmc_registration_wizard_step';

  Future<SharedPreferences> get _store async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getDraftId() async {
    return (await _store).getString(_draftIdKey);
  }

  Future<int?> getWizardStep() async {
    return (await _store).getInt(_wizardStepKey);
  }

  Future<void> saveDraft({required String draftId, required int step}) async {
    final store = await _store;
    await store.setString(_draftIdKey, draftId);
    await store.setInt(_wizardStepKey, step);
  }

  Future<void> saveStep(int step) async {
    await (await _store).setInt(_wizardStepKey, step);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_draftIdKey);
    await store.remove(_wizardStepKey);
  }
}
