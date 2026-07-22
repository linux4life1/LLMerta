import 'dart:io';

import 'package:game_core/game_core.dart';

/// Terminal-backed human seat for the M2 debug CLI. No timeout — the game
/// waits for the human (GAME_DESIGN.md §5). IO is injectable for tests.
class StdinHumanController extends PlayerController {
  StdinHumanController({
    required this.names,
    String? Function()? readLine,
    void Function(String)? write,
  }) : _readLine = readLine ?? stdin.readLineSync,
       _write = write ?? stdout.writeln;

  final List<String> names;
  final String? Function() _readLine;
  final void Function(String) _write;

  String _freeText(DecisionContext ctx, String task) {
    _write('\n[YOU are ${names[ctx.seat]}, the ${ctx.role.name}] $task');
    _write('> (type your words, or press enter to stay silent)');
    return (_readLine() ?? '').trim();
  }

  int? _pickSeat(
    DecisionContext ctx,
    String task,
    List<int> options, {
    required bool allowNone,
  }) {
    _write('\n[YOU are ${names[ctx.seat]}, the ${ctx.role.name}] $task');
    for (final s in options) {
      _write('  $s: ${names[s]}');
    }
    _write(
      allowNone
          ? '> (enter a seat number, or press enter to pass)'
          : '> (enter a seat number)',
    );
    while (true) {
      final input = (_readLine() ?? '').trim();
      if (input.isEmpty && allowNone) return null;
      final seat = int.tryParse(input);
      if (seat != null && options.contains(seat)) return seat;
      _write(
        '> invalid — choose one of: ${options.join(', ')}'
        '${allowNone ? ' or press enter to pass' : ''}',
      );
    }
  }

  @override
  Future<String> speak(DecisionContext ctx) async =>
      _freeText(ctx, 'Give your day-${ctx.day} speech.');

  @override
  Future<String> defend(DecisionContext ctx) async =>
      _freeText(ctx, 'You are on trial — defend yourself.');

  @override
  Future<String> lastWords(DecisionContext ctx) async =>
      _freeText(ctx, 'You were eliminated — any last words?');

  @override
  Future<String> mafiaChat(DecisionContext ctx) async =>
      _freeText(ctx, 'Say something privately to your mafia team.');

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) async =>
      _pickSeat(
        ctx,
        'Nominate someone for elimination.',
        candidates,
        allowNone: true,
      );

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) async => _pickSeat(
    ctx,
    'Vote for the nominee you want ELIMINATED.',
    nominees,
    allowNone: true,
  );

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) async =>
      _pickSeat(
        ctx,
        'Vote for tonight\'s kill target.',
        targets,
        allowNone: true,
      );

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) async =>
      (_pickSeat(ctx, 'Choose who to protect.', targets, allowNone: false))!;

  @override
  Future<int> sheriffInvestigate(
    DecisionContext ctx,
    List<int> targets,
  ) async => (_pickSeat(
    ctx,
    'Choose who to investigate.',
    targets,
    allowNone: false,
  ))!;

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) async =>
      _pickSeat(
        ctx,
        'Fire your one bullet, or hold it.',
        targets,
        allowNone: true,
      );
}
