import 'package:flutter/material.dart';

import '../services/app_config.dart';

/// Shown on every run after setup is complete. Greets the configured user and
/// offers a "Sign out" action that clears the saved config via [onSignOut].
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.config,
    required this.onSignOut,
  });

  final AppConfig config;
  final VoidCallback onSignOut;

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
        child: Text(
          'Hi ${config.name}',
          style: theme.textTheme.displaySmall,
        ),
      ),
    );
  }
}
