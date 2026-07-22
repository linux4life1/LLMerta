import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connections_section.dart';
import 'personas_section.dart';
import 'updates_section.dart';
import 'voices_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.initialSection = 0, super.key});

  final int initialSection;

  static Route<void> route({int initialSection = 0}) => MaterialPageRoute(
    builder: (_) => SettingsScreen(initialSection: initialSection),
  );

  /// Rail index of the Updates section, for the home-screen chip.
  static const updatesSection = 3;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late var _section = widget.initialSection;

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
              NavigationRailDestination(
                icon: Icon(Icons.system_update_alt),
                label: Text('Updates'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: switch (_section) {
              0 => const ConnectionsSection(),
              1 => const PersonasSection(),
              2 => const VoicesSection(),
              _ => const UpdatesSection(),
            },
          ),
        ],
      ),
    );
  }
}
