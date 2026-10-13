import 'claude_cli_service.dart';

/// The connected Google account, as reported by a Google MCP tool via the
/// Claude CLI.
class GoogleAccount {
  const GoogleAccount({required this.email, this.via});
  final String email;

  /// Which Google service answered (e.g. "Google Calendar", "Gmail").
  final String? via;
}

class GoogleException implements Exception {
  GoogleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks the Google session by asking the Claude CLI to use whichever Google
/// connector is available to report the signed-in account. No token is stored
/// or handled here — it rides the CLI's existing Google MCP session.
class GoogleAuthService {
  const GoogleAuthService(this._cli);
  final ClaudeCliService _cli;

  static const _prompt =
      'Use the available Google tools to determine the currently connected '
      'Google account. For example, Google Calendar list_calendars returns the '
      'primary calendar whose id is the account email; Gmail tools also work. '
      'Respond with ONLY raw JSON — no markdown code fences, no commentary — in '
      'the shape {"connected": true, "email": "you@example.com", "via": "Google '
      'Calendar"}. If no Google account is connected or the tools are '
      'unavailable, respond with {"connected": false, "email": null, "via": null}.';

  Future<GoogleAccount> checkConnection() async {
    final data = await _cli.runJson(_prompt);
    if (data is! Map) {
      throw GoogleException('Unexpected response while checking Google.');
    }
    final email = data['email'] as String?;
    if (data['connected'] != true || email == null || email.isEmpty) {
      throw GoogleException('No Google account is connected in the Claude CLI.');
    }
    return GoogleAccount(email: email, via: data['via'] as String?);
  }
}
