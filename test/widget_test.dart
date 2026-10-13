import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devsphere/services/app_config.dart';
import 'package:devsphere/services/claude_cli_service.dart';
import 'package:devsphere/main.dart';

/// Fake CLI so tests never shell out to the real `claude` binary. Returns a
/// "not connected" result instantly (no Process, no timers).
class _FakeCli extends ClaudeCliService {
  const _FakeCli();
  @override
  Future<dynamic> runJson(String prompt) async => {'connected': false};
}

void main() {
  const fakeCli = _FakeCli();

  testWidgets('shows setup form on first run', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config, cli: fakeCli));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to DevSphere'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('greets configured user on later runs', (tester) async {
    SharedPreferences.setMockInitialValues({'config.name': 'Maurice'});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config, cli: fakeCli));
    await tester.pumpAndSettle();

    expect(find.text('Hi Maurice'), findsOneWidget);
  });

  testWidgets('setup form saves name and shows greeting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config, cli: fakeCli));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Ada');
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ada'), findsOneWidget);
  });

  testWidgets('dashboard auto-checks and shows "not connected" with help',
      (tester) async {
    SharedPreferences.setMockInitialValues({'config.name': 'Maurice'});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config, cli: fakeCli));
    await tester.pumpAndSettle();

    // Both tiles ran their check automatically and report not connected.
    expect(find.text('Not connected'), findsNWidgets(2));
    expect(find.textContaining('How to connect'), findsNWidgets(2));
  });
}
