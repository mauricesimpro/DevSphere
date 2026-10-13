import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/jira_service.dart';
import '../services/google_auth_service.dart';
import 'jira_connect_screen.dart';
import 'google_session_screen.dart';

/// The home dashboard, shown on every run after setup. Greets the configured
/// user and surfaces the Jira connection and Google session checker. A
/// "Sign out" action clears the saved config via [onSignOut].
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.config,
    required this.onSignOut,
  });

  final AppConfig config;
  final VoidCallback onSignOut;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  JiraService? _jira;
  GoogleAuthService? _google;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final jira = await JiraService.load();
    final google = await GoogleAuthService.load();
    if (!mounted) return;
    setState(() {
      _jira = jira;
      _google = google;
    });
  }

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

  Future<void> _openJira() async {
    final jira = _jira;
    if (jira == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JiraConnectScreen(service: jira)),
    );
    if (mounted) setState(() {}); // refresh status on return
  }

  Future<void> _openGoogle() async {
    final google = _google;
    if (google == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoogleSessionScreen(service: google)),
    );
    if (mounted) setState(() {});
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
                'Connections',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _ConnectionCard(
                icon: Icons.dashboard_outlined,
                title: 'Jira',
                connected: _jira?.isConnected ?? false,
                statusText: (_jira?.isConnected ?? false)
                    ? 'Connected as ${_jira?.savedDisplayName ?? _jira?.email}'
                    : 'Not connected',
                onTap: _jira == null ? null : _openJira,
              ),
              const SizedBox(height: 12),
              _ConnectionCard(
                icon: Icons.account_circle_outlined,
                title: 'Google session',
                connected: _google?.hasSavedToken ?? false,
                statusText: (_google?.hasSavedToken ?? false)
                    ? 'Token saved — tap to re-check'
                    : 'No session checked yet',
                onTap: _google == null ? null : _openGoogle,
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
    required this.connected,
    required this.statusText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool connected;
  final String statusText;
  final VoidCallback? onTap;

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
        subtitle: Row(
          children: [
            Icon(
              connected ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: connected ? Colors.green.shade600 : theme.colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(statusText)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
