import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The Jira account DevSphere is connected as, returned by `/myself`.
class JiraUser {
  const JiraUser({
    required this.displayName,
    required this.emailAddress,
    this.accountId,
    this.avatarUrl,
  });

  final String displayName;
  final String emailAddress;
  final String? accountId;
  final String? avatarUrl;
}

class JiraException implements Exception {
  JiraException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A real Jira Cloud "connect login": the user supplies a site URL, their email,
/// and an API token; we verify them against `GET /rest/api/3/myself` using HTTP
/// basic auth. On success the credentials are persisted so DevSphere reconnects
/// on the next launch. `disconnect()` clears them.
class JiraService {
  JiraService(this._prefs);

  static const _baseUrlKey = 'jira.baseUrl';
  static const _emailKey = 'jira.email';
  static const _tokenKey = 'jira.token';
  static const _displayNameKey = 'jira.displayName';

  final SharedPreferences _prefs;

  static Future<JiraService> load() async {
    return JiraService(await SharedPreferences.getInstance());
  }

  bool get isConnected => _prefs.getString(_tokenKey) != null;

  String? get baseUrl => _prefs.getString(_baseUrlKey);
  String? get email => _prefs.getString(_emailKey);

  /// The display name captured at connect time (shown without a round-trip).
  String? get savedDisplayName => _prefs.getString(_displayNameKey);

  /// Normalises "your-co.atlassian.net" or a full URL into a clean base URI.
  static Uri _normaliseBase(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      throw JiraException('Enter your Jira site URL.');
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    final uri = Uri.parse(value);
    if (uri.host.isEmpty) {
      throw JiraException('That doesn\'t look like a valid site URL.');
    }
    return Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null);
  }

  /// Verifies credentials against Jira and, on success, persists them.
  Future<JiraUser> connect({
    required String siteUrl,
    required String email,
    required String apiToken,
  }) async {
    final base = _normaliseBase(siteUrl);
    final trimmedEmail = email.trim();
    final trimmedToken = apiToken.trim();

    if (trimmedEmail.isEmpty) throw JiraException('Enter your Jira email.');
    if (trimmedToken.isEmpty) throw JiraException('Enter your API token.');

    final auth = base64Encode(utf8.encode('$trimmedEmail:$trimmedToken'));
    final url = base.replace(path: '/rest/api/3/myself');

    http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $auth',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw JiraException('Could not reach $url.\n$e');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw JiraException(
        'Jira rejected those credentials (${response.statusCode}). '
        'Check the email and API token.',
      );
    }
    if (response.statusCode != 200) {
      throw JiraException(
        'Unexpected response from Jira (${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw JiraException('Jira returned an unreadable response.');
    }

    final user = JiraUser(
      displayName: (body['displayName'] as String?) ?? trimmedEmail,
      emailAddress: (body['emailAddress'] as String?) ?? trimmedEmail,
      accountId: body['accountId'] as String?,
      avatarUrl: (body['avatarUrls'] as Map<String, dynamic>?)?['48x48'] as String?,
    );

    await _prefs.setString(_baseUrlKey, base.toString());
    await _prefs.setString(_emailKey, trimmedEmail);
    await _prefs.setString(_tokenKey, trimmedToken);
    await _prefs.setString(_displayNameKey, user.displayName);

    return user;
  }

  Future<void> disconnect() async {
    await _prefs.remove(_baseUrlKey);
    await _prefs.remove(_emailKey);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_displayNameKey);
  }
}
