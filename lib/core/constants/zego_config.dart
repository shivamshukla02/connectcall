import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads RTC credentials from the .env file loaded at startup. Throwing a
/// clear error here beats a cryptic ZEGOCLOUD SDK crash later if someone
/// forgets to create their .env from .env.example.
class ZegoConfig {
  ZegoConfig._();

  static int get appId {
    final raw = dotenv.env['ZEGO_APP_ID'];
    if (raw == null || raw.isEmpty) {
      throw StateError(
          'ZEGO_APP_ID missing. Copy .env.example to .env and fill in your ZEGOCLOUD AppID.');
    }
    return int.parse(raw);
  }

  static String get appSign {
    final raw = dotenv.env['ZEGO_APP_SIGN'];
    if (raw == null || raw.isEmpty) {
      throw StateError(
          'ZEGO_APP_SIGN missing. Copy .env.example to .env and fill in your ZEGOCLOUD AppSign.');
    }
    return raw;
  }
}
