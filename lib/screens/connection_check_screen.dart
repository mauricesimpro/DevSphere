import 'package:flutter/material.dart';

/// A connection check returns labelled fields to display on success, or throws
/// with a human-readable message on failure.
typedef ConnectionCheck = Future<List<MapEntry<String, String>>> Function();

/// Generic screen that runs a [check] (which shells out to the Claude CLI),
/// shows a spinner while it runs, then the connected account details or an
/// error. Used for both the Jira and Google cards.
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.check,
  });

  final String title;
  final IconData icon;
  final String description;
  final ConnectionCheck check;

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  bool _busy = false;
  String? _error;
  List<MapEntry<String, String>>? _fields;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
      _fields = null;
    });
    try {
      final fields = await widget.check();
      if (!mounted) return;
      setState(() => _fields = fields);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.title, style: theme.textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Asking Claude…'),
                      ],
                    ),
                  )
                else if (_error != null)
                  _ErrorBox(message: _error!)
                else if (_fields != null)
                  _ConnectedCard(title: widget.title, fields: _fields!),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _run,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-check'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.title, required this.fields});
  final String title;
  final List<MapEntry<String, String>> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Text('Connected', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            for (final f in fields)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(f.key, style: theme.textTheme.labelMedium),
                    ),
                    Expanded(child: SelectableText(f.value)),
                  ],
                ),
              ),
          ],
        ),
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
      padding: const EdgeInsets.all(14),
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
