import 'package:flutter/material.dart';

import '../services/jira_service.dart';

/// Jira "connect login": site URL + email + API token, verified against Jira
/// and persisted. Shows the connected account with an option to disconnect.
class JiraConnectScreen extends StatefulWidget {
  const JiraConnectScreen({super.key, required this.service});

  final JiraService service;

  @override
  State<JiraConnectScreen> createState() => _JiraConnectScreenState();
}

class _JiraConnectScreenState extends State<JiraConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _siteController;
  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();

  bool _busy = false;
  String? _error;
  JiraUser? _connectedUser;

  @override
  void initState() {
    super.initState();
    _siteController = TextEditingController(text: widget.service.baseUrl ?? '');
    _emailController = TextEditingController(text: widget.service.email ?? '');
    if (widget.service.isConnected) {
      _connectedUser = JiraUser(
        displayName: widget.service.savedDisplayName ?? widget.service.email ?? 'Connected',
        emailAddress: widget.service.email ?? '',
      );
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.service.connect(
        siteUrl: _siteController.text,
        email: _emailController.text,
        apiToken: _tokenController.text,
      );
      if (!mounted) return;
      setState(() => _connectedUser = user);
    } on JiraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    await widget.service.disconnect();
    if (!mounted) return;
    setState(() {
      _connectedUser = null;
      _tokenController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jira connection')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _connectedUser != null ? _connectedView() : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _connectedView() {
    final theme = Theme.of(context);
    final user = _connectedUser!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 56, color: Colors.green.shade600),
        const SizedBox(height: 16),
        Text('Connected to Jira', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.displayName),
            subtitle: Text(user.emailAddress),
          ),
        ),
        if (widget.service.baseUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              widget.service.baseUrl!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _disconnect,
          icon: const Icon(Icons.link_off),
          label: const Text('Disconnect'),
        ),
      ],
    );
  }

  Widget _formView() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect to Jira', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Use an Atlassian API token (id.atlassian.com → Security → '
            'Create and manage API tokens).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _siteController,
            decoration: const InputDecoration(
              labelText: 'Jira site URL',
              hintText: 'your-co.atlassian.net',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@company.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API token',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            onFieldSubmitted: (_) => _connect(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _connect,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
