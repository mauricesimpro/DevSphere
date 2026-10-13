import 'package:flutter/material.dart';

/// Returns labelled fields on success, or throws with a human-readable message.
typedef TileCheck = Future<List<MapEntry<String, String>>> Function();

/// A self-checking connection card. It runs [check] automatically when it
/// appears and shows a spinner → connected account, or a "not connected" state
/// with [howToConnect] instructions and a Re-check button.
class ConnectionTile extends StatefulWidget {
  const ConnectionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.check,
    required this.howToConnect,
  });

  final String title;
  final IconData icon;
  final TileCheck check;
  final List<String> howToConnect;

  @override
  State<ConnectionTile> createState() => _ConnectionTileState();
}

enum _Status { checking, connected, failed }

class _ConnectionTileState extends State<ConnectionTile> {
  _Status _status = _Status.checking;
  String? _error;
  List<MapEntry<String, String>> _fields = const [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _status = _Status.checking;
      _error = null;
    });
    try {
      final fields = await widget.check();
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _status = _Status.connected;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _status = _Status.failed;
      });
    }
  }

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
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(widget.icon, color: theme.colorScheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.title, style: theme.textTheme.titleMedium)),
                _statusIndicator(theme),
              ],
            ),
            const SizedBox(height: 12),
            _body(theme),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(ThemeData theme) {
    switch (_status) {
      case _Status.checking:
        return const SizedBox(
          height: 18, width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _Status.connected:
        return Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
            const SizedBox(width: 4),
            Text('Connected', style: TextStyle(color: Colors.green.shade700)),
          ],
        );
      case _Status.failed:
        return Row(
          children: [
            Icon(Icons.cancel, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text('Not connected', style: TextStyle(color: theme.colorScheme.error)),
          ],
        );
    }
  }

  Widget _body(ThemeData theme) {
    switch (_status) {
      case _Status.checking:
        return Text(
          'Checking via your Claude CLI…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      case _Status.connected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in _fields)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 72, child: Text(f.key, style: theme.textTheme.labelMedium)),
                    Expanded(child: SelectableText(f.value)),
                  ],
                ),
              ),
          ],
        );
      case _Status.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            Text('How to connect ${widget.title}', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            for (var i = 0; i < widget.howToConnect.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.  ', style: theme.textTheme.bodySmall),
                    Expanded(child: Text(widget.howToConnect[i], style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Re-check'),
              ),
            ),
          ],
        );
    }
  }
}
