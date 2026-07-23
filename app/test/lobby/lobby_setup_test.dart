import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:persistence/persistence.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  LobbySetupController controllerOf(ProviderContainer c) =>
      c.read(lobbySetupControllerProvider.notifier);

  test('defaults: 10 seats, pooled town name, night-one grudge-on setup', () {
    final c = container();
    final setup = c.read(lobbySetupControllerProvider);
    expect(setup.config.seats, 10);
    expect(setup.seats, hasLength(10));
    expect(townNamePool, contains(setup.townName));
    expect(setup.difficulty, Difficulty.standard);
    expect(setup.scene, const BuiltInScene(BuiltInSceneId.midnightStudy));
    expect(setup.grudgeMode, isTrue);
    expect(setup.humanSeat, 0);
    expect(setup.ready, isFalse);
  });

  test('seat count changes preserve existing casting', () {
    final c = container();
    final controller = controllerOf(c)
      ..castSeat(3, const SeatCasting(personaName: 'Edda'))
      ..setSeatCount(14);
    var setup = c.read(lobbySetupControllerProvider);
    expect(setup.seats, hasLength(14));
    expect(setup.config.seats, 14);
    expect(setup.seats[3].personaName, 'Edda');

    controller.setSeatCount(7);
    setup = c.read(lobbySetupControllerProvider);
    expect(setup.seats, hasLength(7));
    expect(setup.seats[3].personaName, 'Edda');
  });

  test('castAllSeats fills every AI seat and skips the human', () {
    final c = container();
    controllerOf(c).castAllSeats(connectionId: 'omlx', model: 'glm-5');
    final setup = c.read(lobbySetupControllerProvider);
    expect(setup.seats[setup.humanSeat].model, isNull);
    for (final s in setup.aiSeats) {
      expect(setup.seats[s].connectionId, 'omlx');
      expect(setup.seats[s].model, 'glm-5');
    }
  });

  test('shufflePersonas deals unique names and leaves the human alone', () {
    final c = container();
    final pool = [for (var i = 0; i < 20; i++) 'Persona $i'];
    controllerOf(c).shufflePersonas(pool, Random(42));
    final setup = c.read(lobbySetupControllerProvider);
    expect(setup.seats[setup.humanSeat].personaName, isNull);
    final dealt = [for (final s in setup.aiSeats) setup.seats[s].personaName];
    expect(dealt, everyElement(isNotNull));
    expect(dealt.toSet(), hasLength(dealt.length));
  });

  test('randomizeHumanSeat swaps castings and stays deal-ready', () {
    final c = container();
    final controller = controllerOf(c)
      ..castAllSeats(connectionId: 'omlx', model: 'glm-5')
      ..shufflePersonas([for (var i = 0; i < 20; i++) 'P$i'], Random(1))
      ..setHumanName('Sosuke');
    final before = c.read(lobbySetupControllerProvider);
    expect(before.ready, isTrue);

    controller.randomizeHumanSeat(Random(7));
    final after = c.read(lobbySetupControllerProvider);
    expect(after.ready, isTrue);
    // The vacated slot inherits the displaced AI casting; the human's
    // new slot is the empty one.
    expect(after.seats[after.humanSeat].model, isNull);
    for (final s in after.aiSeats) {
      expect(after.seats[s].model, 'glm-5');
      expect(after.seats[s].personaName, isNotNull);
    }
    // Over many draws every chair comes up.
    final seen = <int>{};
    final rng = Random(3);
    for (var i = 0; i < 200; i++) {
      controller.randomizeHumanSeat(rng);
      seen.add(c.read(lobbySetupControllerProvider).humanSeat);
    }
    expect(seen, hasLength(10));
    expect(c.read(lobbySetupControllerProvider).ready, isTrue);
  });

  test('ready requires a named human and fully cast AI seats', () {
    final c = container();
    final controller = controllerOf(c)
      ..castAllSeats(connectionId: 'omlx', model: 'glm-5')
      ..shufflePersonas([for (var i = 0; i < 20; i++) 'P$i'], Random(1));
    expect(c.read(lobbySetupControllerProvider).ready, isFalse);

    controller.setHumanName('Sosuke');
    expect(c.read(lobbySetupControllerProvider).ready, isTrue);

    final seat = c.read(lobbySetupControllerProvider).aiSeats.first;
    controller.castSeat(seat, const SeatCasting(personaName: 'P0'));
    expect(c.read(lobbySetupControllerProvider).ready, isFalse);
  });

  test('updateConfig resizes the casting list when seats change', () {
    final c = container();
    final config = c
        .read(lobbySetupControllerProvider)
        .config
        .copyWith(seats: 12, night0: false);
    controllerOf(c).updateConfig(config);
    final setup = c.read(lobbySetupControllerProvider);
    expect(setup.seats, hasLength(12));
    expect(setup.config.night0, isFalse);
  });

  test('rerolling the town never repeats the current name', () {
    final c = container();
    for (var i = 0; i < 10; i++) {
      final before = c.read(lobbySetupControllerProvider).townName;
      controllerOf(c).rerollTownName();
      expect(c.read(lobbySetupControllerProvider).townName, isNot(before));
    }
  });

  test('picking an FP persona prefills the name; clearing keeps it', () {
    final c = ProviderContainer(
      overrides: [
        fpaPersonasProvider.overrideWith(
          (_) => const [FpPersona(id: 'p1', name: 'Linus', title: 'Tech-Bro')],
        ),
      ],
    );
    addTearDown(c.dispose);
    final persona = c.read(fpaPersonasProvider).single;
    expect(persona.label, 'Linus — Tech-Bro');

    final controller = controllerOf(c)..setHumanPersona(persona);
    var setup = c.read(lobbySetupControllerProvider);
    expect(setup.humanPersona, persona);
    expect(setup.humanName, 'Linus');

    controller
      ..setHumanName('Sosuke')
      ..setHumanPersona(null);
    setup = c.read(lobbySetupControllerProvider);
    expect(setup.humanPersona, isNull);
    expect(setup.humanName, 'Sosuke');
  });

  test('casting pool still leads with customs and carries the house', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertPersona(
      CustomPersonasCompanion.insert(
        name: 'Vex',
        archetype: 'switchboard operator',
        style: 'clipped',
        quirk: 'listens in',
      ),
    );
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
    );
    addTearDown(c.dispose);
    // Keep the autodispose stream provider alive while priming it.
    final sub = c.listen(personaRowsProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(personaRowsProvider.future);
    final casting = c.read(castingPersonaNamesProvider);
    for (final house in personaLibrary) {
      expect(casting, contains(house.name));
    }
    expect(casting.first, 'Vex');
  });
}
