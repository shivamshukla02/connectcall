/// App-wide constants. Keeping these in one file means when the assignment
/// asks "why did you structure it this way" the answer is: single source of
/// truth, no magic strings scattered across widgets.
class AppConstants {
  AppConstants._();

  static const String appName = 'ConnectCall';
  static const String appTagline = 'Connect with anyone, anywhere.';

  // Firestore collection names (Phase 2+)
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';

  // Splash timing
  static const Duration splashMinDuration = Duration(milliseconds: 1200);
}

/// Call type — used across models, services and UI so we never compare
/// raw strings like 'audio' vs 'video' by accident.
enum CallType { audio, video }

/// Call status — mirrors the state machine from the assignment PDF:
/// calling -> ringing -> connected -> ended, plus rejected/missed/failed.
enum CallStatus { calling, ringing, connected, ended, rejected, missed, failed }

extension CallTypeX on CallType {
  String get value => name; // 'audio' | 'video'
}

extension CallStatusX on CallStatus {
  String get value => name;
}
