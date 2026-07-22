import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connections_section.dart';
import 'personas_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SettingsScreen());

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _section = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _section,
            onDestinationSelected: (index) => setState(() => _section = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.cable),
                label: Text('Connections'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.theater_comedy),
                label: Text('Personas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.record_voice_over),
                label: Text('Voices'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: switch (_section) {
              0 => const ConnectionsSection(),
              1 => const PersonasSection(),
              _ => const Center(
                child: Text(
                  'Voices arrive with M5 — Piper and Kokoro, fully offline.',
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}
