import 'claude_cli_service.dart';

/// The connected Atlassian account, as reported by the `atlassianUserInfo` MCP
/// tool via the Claude CLI.
class JiraAccount {
  const JiraAccount({required this.displayName, this.email, this.accountId});
  final String displayName;
  final String? email;
  final String? accountId;
}

class JiraException implements Exception {
  JiraException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks the Jira connection by asking the Claude CLI to call the Atlassian
/// `atlassianUserInfo` tool. No token is stored or handled here — the call rides
/// the CLI's existing Atlassian MCP session.
class JiraService {
  const JiraService(this._cli);
  final ClaudeCliService _cli;

  static const _prompt =
      'Call the Atlassian atlassianUserInfo tool and respond with ONLY that '
      "tool's raw JSON result — no markdown code fences, no commentary. "
      'If the Atlassian tools are unavailable or no account is connected, '
      'respond with exactly {"connected": false}.';

  Future<JiraAccount> checkConnection() async {
    final data = await _cli.runJson(_prompt);
    if (data is! Map) {
      throw JiraException('Unexpected response while checking Jira.');
    }
    if (data['connected'] == false) {
      throw JiraException('No Atlassian account is connected in the Claude CLI.');
    }

    final name = (data['name'] ?? data['displayName']) as String?;
    final email = (data['email'] ?? data['emailAddress']) as String?;
    final accountId = (data['account_id'] ?? data['accountId']) as String?;

    if (name == null && email == null && accountId == null) {
      throw JiraException('Atlassian did not report an account — not connected.');
    }

    return JiraAccount(
      displayName: name ?? email ?? accountId!,
      email: email,
      accountId: accountId,
    );
  }
}
