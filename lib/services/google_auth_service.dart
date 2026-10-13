import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The result of checking a Google OAuth access token against Google's
/// tokeninfo endpoint.
class GoogleSession {
  const GoogleSession({
    required this.active,
    this.email,
    this.scopes = const [],
    this.expiresInSeconds,
    this.error,
  });

  final bool active;
  final String? email;
  final List<String> scopes;
  final int? expiresInSeconds;

  /// Human-readable reason the session is not active (if [active] is false).
  final String? error;
}

/// Checks whether a Google OAuth access token is still a live session, using
/// the public tokeninfo endpoint. This is a *session checker* — it does not run
/// an OAuth sign-in flow, it validates a token the user already has and reports
/// the account, granted scopes, and time left. The last-checked token is saved
/// so the session can be re-verified on a later launch.
class GoogleAuthService {
  GoogleAuthService(this._prefs);

  static const _tokenKey = 'google.token';
  static final _tokenInfoUrl = Uri.parse('https://oauth2.googleapis.com/tokeninfo');

  final SharedPreferences _prefs;

  static Future<GoogleAuthService> load() async {
    return GoogleAuthService(await SharedPreferences.getInstance());
  }

  bool get hasSavedToken => _prefs.getString(_tokenKey) != null;
  String? get savedToken => _prefs.getString(_tokenKey);

  /// Validates [accessToken]; on an active session the token is remembered.
  Future<GoogleSession> check(String accessToken) async {
    final token = accessToken.trim();
    if (token.isEmpty) {
      return const GoogleSession(active: false, error: 'Paste an access token first.');
    }

    http.Response response;
    try {
      response = await http
          .get(_tokenInfoUrl.replace(queryParameters: {'access_token': token}))
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      return GoogleSession(active: false, error: 'Could not reach Google.\n$e');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return const GoogleSession(active: false, error: 'Unreadable response from Google.');
    }

    // A non-200 (usually 400) means the token is invalid or expired.
    if (response.statusCode != 200 || body.containsKey('error')) {
      await _prefs.remove(_tokenKey);
      final desc = (body['error_description'] ?? body['error']) as String?;
      return GoogleSession(
        active: false,
        error: desc != null ? 'Session not active: $desc' : 'Token is invalid or expired.',
      );
    }

    final scope = (body['scope'] as String?) ?? '';
    final expiresIn = int.tryParse('${body['expires_in'] ?? ''}');

    await _prefs.setString(_tokenKey, token);

    return GoogleSession(
      active: true,
      email: body['email'] as String?,
      scopes: scope.isEmpty ? const [] : scope.split(RegExp(r'\s+')),
      expiresInSeconds: expiresIn,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
  }
}
