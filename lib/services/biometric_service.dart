import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredCredentials {
  final String login;
  final String password;
  StoredCredentials(this.login, this.password);
}

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyLogin = 'bio_login';
  static const _keyPassword = 'bio_password';
  static const _keyEnrolled = 'bio_enrolled';

  /// Is fingerprint / face available AND enrolled on this device?
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Has the user already enabled fingerprint login on this device?
  static Future<bool> isEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyEnrolled) != true) return false;
    return await _storage.containsKey(key: _keyPassword);
  }

  /// Save credentials after a successful password login
  static Future<void> enable(String login, String password) async {
    await _storage.write(key: _keyLogin, value: login);
    await _storage.write(key: _keyPassword, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnrolled, true);
  }

  /// Show the system biometric prompt. Returns true if user passed.
  static Future<bool> authenticate({
    String reason = 'Log in to SchoolsMirror',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Only call this AFTER authenticate() returns true
  static Future<StoredCredentials?> retrieveCredentials() async {
    final login = await _storage.read(key: _keyLogin);
    final password = await _storage.read(key: _keyPassword);
    if (login == null || password == null) return null;
    return StoredCredentials(login, password);
  }

  /// Disable fingerprint login — wipe both storage and flag
  static Future<void> disable() async {
    await _storage.delete(key: _keyLogin);
    await _storage.delete(key: _keyPassword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnrolled, false);
  }
}
