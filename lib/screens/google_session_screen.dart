import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';

/// Google auth session checker: paste an OAuth access token, validate it against
/// Google's tokeninfo endpoint, and show whether the session is live along with
/// the account, scopes, and time remaining.
class GoogleSessionScreen extends StatefulWidget {
  const GoogleSessionScreen({super.key, required this.service});

  final GoogleAuthService service;

  @override
  State<GoogleSessionScreen> createState() => _GoogleSessionScreenState();
}

class _GoogleSessionScreenState extends State<GoogleSessionScreen> {
  late final TextEditingController _tokenController;
  bool _busy = false;
  GoogleSession? _session;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.service.savedToken ?? '');
    // Re-check a remembered token automatically on open.
    if (widget.service.hasSavedToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final session = await widget.service.check(_tokenController.text);
    if (!mounted) return;
    setState(() {
      _session = session;
      _busy = false;
    });
  }

  Future<void> _clear() async {
    await widget.service.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _tokenController.clear();
    });
  }

  String _formatExpiry(int seconds) {
    if (seconds <= 0) return 'expired';
    final m = seconds ~/ 60;
    if (m < 1) return 'expires in ${seconds}s';
    if (m < 60) return 'expires in $m min';
    final h = m ~/ 60;
    return 'expires in ${h}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google session')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Check a Google session', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Paste a Google OAuth access token to verify it\'s live. '
                  'Get one from the OAuth Playground or `gcloud auth print-access-token`.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Access token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _check,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _busy
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Check session'),
                  ),
                ),
                if (_session != null) ...[
                  const SizedBox(height: 24),
                  _result(_session!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _result(GoogleSession s) {
    final theme = Theme.of(context);
    if (!s.active) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cancel, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.error ?? 'Session is not active.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text('Active session', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            if (s.email != null) _row(Icons.person, 'Account', s.email!),
            if (s.expiresInSeconds != null)
              _row(Icons.schedule, 'Expiry', _formatExpiry(s.expiresInSeconds!)),
            if (s.scopes.isNotEmpty)
              _row(Icons.shield_outlined, 'Scopes', s.scopes.join('\n')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Forget token'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
