import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devsphere/services/app_config.dart';
import 'package:devsphere/main.dart';

void main() {
  testWidgets('shows setup form on first run', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to DevSphere'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('greets configured user on later runs', (tester) async {
    SharedPreferences.setMockInitialValues({'config.name': 'Maurice'});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Hi Maurice'), findsOneWidget);
  });

  testWidgets('setup form saves name and shows greeting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await AppConfig.load();

    await tester.pumpWidget(DevSphereApp(config: config));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Ada');
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ada'), findsOneWidget);
  });
}
