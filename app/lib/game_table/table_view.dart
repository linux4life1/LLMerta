import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show renderEvent;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'game_session.dart';

part 'table_view.freezed.dart';
part 'table_view.g.dart';

/// Pure render-state fold. Consumes ONLY visibility-filtered events — the
/// session never hands the full log to the UI (CLAUDE.md rule 7).
@freezed
abstract class TableViewState with _$TableViewState {
  const TableViewState._();

  const factory TableViewState({
    @Default('The table is empty') String banner,
    @Default(false) bool night,
    @Default(0) int day,
    String? narratorLine,
    (int, String)? activeSpeech,
    @Default({}) Set<int> dead,
    @Default({}) Set<int> onTrial,
    @Default({}) Map<int, Role> revealedRoles,
    @Default({}) Map<int, int?> lastVotes,
    @Default({}) Set<int> mafiaTeam,
    Role? humanRole,
    int? bulletSpentNight,
    @Default(false) bool over,
    Faction? winner,
  }) = _TableViewState;

  bool isAlive(int seat) => !dead.contains(seat);

  bool get humanBulletSpent => bulletSpentNight != null;
}

TableViewState buildTableView(
  List<GameEvent> visibleEvents, {
  required int humanSeat,
  required List<String> names,
}) {
  var view = const TableViewState();
  for (final event in visibleEvents) {
    view = switch (event) {
      GameStarted() => view.copyWith(banner: 'The cards are dealt'),
      RoleReceived(:final seat, :final role) when seat == humanSeat =>
        view.copyWith(humanRole: role),
      MafiaTeamRevealed(:final team) => view.copyWith(mafiaTeam: team),
      NightBegan(:final day) => view.copyWith(
        night: true,
        day: day,
        banner: day == 0
            ? 'Night 0 — the mafia acquaints itself'
            : 'Night $day — the town sleeps',
        narratorLine: 'The town sleeps… someone is stirring.',
        activeSpeech: null,
        onTrial: const {},
        lastVotes: const {},
      ),
      DayBegan(:final day) => view.copyWith(
        night: false,
        day: day,
        banner: 'Day $day — discussion',
        activeSpeech: null,
      ),
      DawnAnnounced() => view.copyWith(
        dead: {...view.dead, ...event.deaths},
        revealedRoles: {...view.revealedRoles, ...event.revealedRoles},
        narratorLine: renderEvent(event, names),
      ),
      SpeechGiven(:final seat, :final text) => view.copyWith(
        activeSpeech: (seat, text),
      ),
      ArgumentOpened(:final by, :final text) when text.isNotEmpty =>
        view.copyWith(activeSpeech: (by, text)),
      ArgumentRebuttal(:final by, :final text) when text.isNotEmpty =>
        view.copyWith(activeSpeech: (by, text)),
      NominationCast(:final by, :final statement) when statement.isNotEmpty =>
        view.copyWith(activeSpeech: (by, statement)),
      TrialStarted(:final nominees) => view.copyWith(
        banner: 'Day ${view.day} — the trial',
        onTrial: {...nominees},
        activeSpeech: null,
      ),
      DefenseGiven(:final seat, :final text) => view.copyWith(
        activeSpeech: (seat, text),
      ),
      VotesRevealed(:final votes) => view.copyWith(
        banner: 'Day ${view.day} — the verdict',
        lastVotes: votes,
      ),
      Verdict(:final eliminated, :final revealedRole) => view.copyWith(
        dead: eliminated == null ? view.dead : {...view.dead, eliminated},
        revealedRoles: eliminated != null && revealedRole != null
            ? {...view.revealedRoles, eliminated: revealedRole}
            : view.revealedRoles,
        narratorLine: renderEvent(event, names),
        onTrial: const {},
      ),
      LastWordsGiven(:final seat, :final text) => view.copyWith(
        activeSpeech: (seat, text),
      ),
      // Private to the assassin; reaching this fold means the human is one.
      AssassinDecided(:final target) when target != null => view.copyWith(
        bulletSpentNight: view.day,
      ),
      GameEnded(:final winner) => view.copyWith(
        over: true,
        winner: winner,
        banner: switch (winner) {
          Faction.town => 'Game over — the town prevails',
          Faction.mafia => 'Game over — the mafia owns this town',
          null => 'Game over — a stalemate draws the curtain',
        },
        narratorLine: renderEvent(event, names),
        activeSpeech: null,
      ),
      _ => view,
    };
  }
  return view;
}

@riverpod
TableViewState tableView(Ref ref) {
  final session = ref.watch(gameSessionControllerProvider);
  return buildTableView(
    session.visibleEvents,
    humanSeat: session.humanSeat,
    names: session.names,
  );
}
