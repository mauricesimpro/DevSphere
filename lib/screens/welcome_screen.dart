import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/claude_cli_service.dart';
import '../services/jira_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/connection_tile.dart';

/// Home dashboard shown after setup. Greets the user and automatically checks
/// the Jira and Google connections on open — both piggyback on the local Claude
/// CLI, so no tokens are stored or entered. A tile that isn't connected shows
/// how to connect it. "Sign out" clears the saved config.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.config,
    required this.onSignOut,
    this.cli = const ClaudeCliService(),
  });

  final AppConfig config;
  final VoidCallback onSignOut;
  final ClaudeCliService cli;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Bumping this re-keys the tiles, forcing them to re-run their checks.
  int _generation = 0;

  static const _jiraHowTo = [
    'Install Claude Code (the `claude` CLI) and sign in.',
    'Run `claude` in a terminal, type `/mcp`, and authorise the Atlassian '
        'connector — or enable it at claude.ai → Settings → Connectors.',
    'Tap Re-check.',
  ];

  static const _googleHowTo = [
    'Install Claude Code (the `claude` CLI) and sign in.',
    'Run `claude`, type `/mcp`, and authorise the Google (Calendar/Gmail) '
        'connector — or enable it at claude.ai → Settings → Connectors.',
    'Tap Re-check.',
  ];

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'This clears your saved configuration. You\'ll be asked to set up '
          'DevSphere again next time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.config.reset();
      widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jira = JiraService(widget.cli);
    final google = GoogleAuthService(widget.cli);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevSphere'),
        actions: [
          IconButton(
            tooltip: 'Re-check all',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _generation++),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 8),
              Text('Hi ${widget.config.name}', style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(
                'Connections — checked live via your Claude CLI',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ConnectionTile(
                key: ValueKey('jira-$_generation'),
                title: 'Jira',
                icon: Icons.dashboard_outlined,
                howToConnect: _jiraHowTo,
                check: () async {
                  final account = await jira.checkConnection();
                  return [
                    MapEntry('Name', account.displayName),
                    if (account.email != null) MapEntry('Email', account.email!),
                    if (account.accountId != null) MapEntry('Account', account.accountId!),
                  ];
                },
              ),
              const SizedBox(height: 12),
              ConnectionTile(
                key: ValueKey('google-$_generation'),
                title: 'Google',
                icon: Icons.account_circle_outlined,
                howToConnect: _googleHowTo,
                check: () async {
                  final account = await google.checkConnection();
                  return [
                    MapEntry('Account', account.email),
                    if (account.via != null) MapEntry('Via', account.via!),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
