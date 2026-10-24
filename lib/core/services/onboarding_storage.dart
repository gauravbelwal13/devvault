import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  OnboardingStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async {
    return await _preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> markCompleted() async {
    await _preferences.setBool(_onboardingCompletedKey, true);
  }
}
