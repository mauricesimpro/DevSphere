import 'package:flutter/material.dart';

import 'services/app_config.dart';
import 'services/claude_cli_service.dart';
import 'screens/setup_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(DevSphereApp(config: config));
}

class DevSphereApp extends StatefulWidget {
  const DevSphereApp({
    super.key,
    required this.config,
    this.cli = const ClaudeCliService(),
  });

  final AppConfig config;

  /// Injectable so tests can supply a fake instead of shelling out to `claude`.
  final ClaudeCliService cli;

  @override
  State<DevSphereApp> createState() => _DevSphereAppState();
}

class _DevSphereAppState extends State<DevSphereApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: _rootScreen(),
    );
  }

  Widget _rootScreen() {
    // Rebuild between setup and welcome by toggling app state. On first run
    // (no saved name) show setup; otherwise greet the returning user.
    if (!widget.config.isConfigured) {
      return SetupScreen(
        config: widget.config,
        onComplete: () => setState(() {}),
      );
    }
    return WelcomeScreen(
      config: widget.config,
      cli: widget.cli,
      onSignOut: () => setState(() {}),
    );
  }
}
