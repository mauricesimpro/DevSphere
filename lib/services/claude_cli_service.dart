import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

class ClaudeCliException implements Exception {
  ClaudeCliException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin wrapper around the local `claude` CLI. DevSphere never holds Jira or
/// Google tokens — instead it shells out to the CLI, which performs the call
/// through whatever MCP connectors the user's Claude session already has, and
/// returns the result. This mirrors how the earlier dev-dashboard app worked
/// (fetch-tickets.sh / check-jira-connection.sh).
///
/// Desktop only: there is no local CLI or shell on the web build.
class ClaudeCliService {
  const ClaudeCliService({this.executable = 'claude'});

  final String executable;

  bool get isSupported => !kIsWeb;

  Future<String> _runRaw(String prompt) async {
    if (kIsWeb) {
      throw ClaudeCliException('The Claude CLI is only available on the desktop app.');
    }

    ProcessResult result;
    try {
      result = await Process.run(
        executable,
        [
          '--dangerously-skip-permissions',
          '-p',
          prompt,
          '--output-format',
          'json',
        ],
        runInShell: true,
      ).timeout(const Duration(seconds: 120));
    } on ProcessException {
      throw ClaudeCliException(
        'Could not run "$executable". Is Claude Code installed and on your PATH?',
      );
    }

    if (result.exitCode != 0) {
      final err = (result.stderr as String).trim();
      throw ClaudeCliException(
        err.isNotEmpty ? err : 'claude exited with code ${result.exitCode}.',
      );
    }

    // `--output-format json` wraps the assistant's answer in an envelope with a
    // `result` field (and an `is_error` flag).
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode((result.stdout as String).trim()) as Map<String, dynamic>;
    } catch (_) {
      throw ClaudeCliException('Unexpected (non-JSON) output from claude.');
    }

    final text = ((envelope['result'] as String?) ?? '').trim();
    if (envelope['is_error'] == true) {
      throw ClaudeCliException(text.isNotEmpty ? text : 'Claude reported an error.');
    }
    return text;
  }

  /// Runs [prompt] expecting a JSON object/array back, tolerating markdown code
  /// fences the model sometimes adds.
  Future<dynamic> runJson(String prompt) async {
    final text = _stripFences(await _runRaw(prompt));
    try {
      return jsonDecode(text);
    } catch (_) {
      throw ClaudeCliException('Claude did not return valid JSON:\n$text');
    }
  }

  static String _stripFences(String input) {
    var text = input.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
      text = text.trim();
    }
    return text;
  }
}
