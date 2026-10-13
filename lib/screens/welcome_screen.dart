import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/claude_cli_service.dart';
import '../services/jira_service.dart';
import '../services/google_auth_service.dart';
import 'connection_check_screen.dart';

/// Home dashboard shown after setup. Greets the user and offers connection
/// checks for Jira and Google that piggyback on the local Claude CLI — no
/// tokens are stored or entered anywhere. "Sign out" clears the saved config.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.config,
    required this.onSignOut,
    this.cli = const ClaudeCliService(),
  });

  final AppConfig config;
  final VoidCallback onSignOut;
  final ClaudeCliService cli;

  Future<void> _confirmSignOut(BuildContext context) async {
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
      await config.reset();
      onSignOut();
    }
  }

  void _openJira(BuildContext context) {
    final jira = JiraService(cli);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConnectionCheckScreen(
        title: 'Jira',
        icon: Icons.dashboard_outlined,
        description:
            'Checks your Atlassian connection through the Claude CLI '
            '(atlassianUserInfo) — no token needed.',
        check: () async {
          final account = await jira.checkConnection();
          return [
            MapEntry('Name', account.displayName),
            if (account.email != null) MapEntry('Email', account.email!),
            if (account.accountId != null) MapEntry('Account', account.accountId!),
          ];
        },
      ),
    ));
  }

  void _openGoogle(BuildContext context) {
    final google = GoogleAuthService(cli);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConnectionCheckScreen(
        title: 'Google',
        icon: Icons.account_circle_outlined,
        description:
            'Checks your Google session through the Claude CLI '
            '(Calendar/Gmail connectors) — no token needed.',
        check: () async {
          final account = await google.checkConnection();
          return [
            MapEntry('Account', account.email),
            if (account.via != null) MapEntry('Via', account.via!),
          ];
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevSphere'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
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
              Text('Hi ${config.name}', style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(
                'Connections — checked live via your Claude CLI',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _ConnectionCard(
                icon: Icons.dashboard_outlined,
                title: 'Jira',
                subtitle: 'Tap to check your Atlassian connection',
                onTap: () => _openJira(context),
              ),
              const SizedBox(height: 12),
              _ConnectionCard(
                icon: Icons.account_circle_outlined,
                title: 'Google',
                subtitle: 'Tap to check your Google session',
                onTap: () => _openGoogle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
