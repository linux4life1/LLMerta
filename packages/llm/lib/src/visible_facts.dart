import 'package:game_core/game_core.dart';

/// An agent's ground truth, folded ONLY from its visibility-filtered event
/// slice — never from GameState, which holds omniscient data
/// (LLM_INTEGRATION.md §3.2).
class VisibleFacts {
  VisibleFacts._();

  int seats = 0;
  int day = 0;
  final Set<int> alive = {};
  final Map<int, Role> revealedRoles = {};

  /// How each dead seat actually died — agents were conflating night
  /// kills with lynchings when only a bare dead-list reached them.
  final Map<int, String> fates = {};
  final Set<int> mafiaTeam = {};
  final Map<int, bool> investigations = {};
  bool bulletSpent = false;
  int? lastProtected;
  Role? ownRole;

  /// Most recent agreed mafia kill (mafia-visible only).
  int? lastMafiaKill;

  /// Private assassin shot outcomes (assassin-visible only).
  final List<({int target, bool killed, bool wasMafia})> shotResults = [];

  /// Investigation targets still alive who came back mafia.
  List<int> get liveMafiaHits => [
    for (final MapEntry(:key, :value) in investigations.entries)
      if (value && alive.contains(key)) key,
  ]..sort();

  static VisibleFacts fold(Iterable<GameEvent> visible) {
    final f = VisibleFacts._();
    for (final event in visible) {
      switch (event) {
        case GameStarted(:final seats):
          f.seats = seats;
          f.alive.addAll([for (var s = 0; s < seats; s++) s]);
        case RoleReceived(:final role):
          f.ownRole = role;
        case MafiaTeamRevealed(:final team):
          f.mafiaTeam.addAll(team);
        case DayBegan(:final day):
          f.day = day;
        case DawnAnnounced(:final deaths, :final revealedRoles):
          f.alive.removeAll(deaths);
          f.revealedRoles.addAll(revealedRoles);
          for (final s in deaths) {
            f.fates[s] = 'killed in the night before day ${f.day}';
          }
        case Verdict(:final eliminated, :final revealedRole):
          if (eliminated != null) {
            f.alive.remove(eliminated);
            f.fates[eliminated] = 'voted out by the town on day ${f.day}';
            if (revealedRole != null) {
              f.revealedRoles[eliminated] = revealedRole;
            }
          }
        case SheriffInvestigated(:final target, :final foundMafia):
          f.investigations[target] = foundMafia;
        case AssassinDecided(:final target):
          if (target != null) f.bulletSpent = true;
        case AssassinShotResolved(
          :final target,
          :final killed,
          :final wasMafia,
        ):
          f.shotResults.add((
            target: target,
            killed: killed,
            wasMafia: wasMafia,
          ));
        case DoctorProtected(:final target):
          f.lastProtected = target;
        case MafiaKillChosen(:final target):
          if (target != null) f.lastMafiaKill = target;
        default:
          break;
      }
    }
    return f;
  }
}

/// Renders one event as a transcript line, or null for events that carry
/// no conversational information (phase markers render, internals do not).
String? renderEvent(GameEvent event, List<String> names) {
  // 1-based everywhere an agent reads or writes a seat number; the UI
  // counts the same way, so choice parsing and table talk stay aligned.
  String n(int seat) => '${names[seat]} (seat ${seat + 1})';
  return switch (event) {
    GameStarted(:final seats) => 'The game begins with $seats players.',
    NightBegan(:final day) =>
      day == 0 ? 'Night falls before the first day.' : 'Night $day falls.',
    DayBegan(:final day) => 'Day $day dawns.',
    DawnAnnounced(:final deaths, :final revealedRoles) =>
      deaths.isEmpty
          ? 'Nobody died in the night.'
          : deaths
                .map(
                  (s) =>
                      '${n(s)} was found dead at dawn — killed during the night'
                      '${revealedRoles[s] != null ? ' — they were the ${revealedRoles[s]!.name}' : ''}.',
                )
                .join(' '),
    SpeechGiven(:final seat, :final text) => '${n(seat)}: "$text"',
    ArgumentOpened(:final by, :final to, :final text) =>
      to == null || text.isEmpty
          ? '${n(by)} lets the crossfire pass.'
          : '${n(by)} challenges ${n(to)}: "$text"',
    ArgumentRebuttal(:final by, :final to, :final text) =>
      text.isEmpty
          ? '${n(by)} stays silent under ${n(to)}\'s challenge.'
          : '${n(by)} snaps back at ${n(to)}: "$text"',
    NominationCast(:final by, :final target, :final statement) =>
      target == null
          ? '${n(by)} passes.'
          : statement.isEmpty
          ? '${n(by)} nominates ${n(target)}.'
          : '${n(by)} nominates ${n(target)}: "$statement"',
    TrialStarted(:final nominees) => 'On trial: ${nominees.map(n).join(', ')}.',
    DefenseGiven(:final seat, :final text) => '${n(seat)} (defense): "$text"',
    VotesRevealed(:final votes) =>
      'Votes: ${votes.entries.map((e) => e.value == null ? '${names[e.key]}→abstain' : '${names[e.key]}→${names[e.value!]}').join(', ')}.',
    Verdict(:final eliminated, :final revealedRole) =>
      eliminated == null
          ? 'The vote fails — nobody is eliminated.'
          : 'The town votes ${n(eliminated)} out'
                '${revealedRole != null ? ' — they were the ${revealedRole.name}' : ''}.',
    LastWordsGiven(:final seat, :final text) =>
      '${n(seat)} (last words): "$text"',
    MafiaChatSaid(:final seat, :final text) =>
      '[mafia chat] ${n(seat)}: "$text"',
    MafiaKillVoteCast(:final by, :final target) =>
      target == null
          ? '[mafia] ${n(by)} abstains from the kill vote.'
          : '[mafia] ${n(by)} votes to kill ${n(target)}.',
    MafiaKillChosen(:final target) =>
      target == null
          ? '[mafia] No kill tonight.'
          : '[mafia] Tonight\'s target: ${n(target)}.',
    MafiaTeamRevealed(:final team) =>
      '[mafia] Your team: ${team.map(n).join(', ')}.',
    RoleReceived(:final role) => 'You are the ${role.name}.',
    DoctorProtected(:final target) => '[private] You protected ${n(target)}.',
    SheriffInvestigated(:final target, :final foundMafia) =>
      '[private] Investigation: ${n(target)} is '
          '${foundMafia ? 'MAFIA' : 'not mafia'}.',
    AssassinDecided(:final target) =>
      target == null
          ? '[private] You held your bullet.'
          : '[private] You fired at ${n(target)}.',
    AssassinShotResolved(:final target, :final killed, :final wasMafia) =>
      '[private] Shot result: ${n(target)} — bullet '
          '${killed ? 'landed' : 'was blocked (they lived)'}; '
          'they were ${wasMafia ? 'MAFIA' : 'not mafia'}.',
    GameEnded(:final winner) =>
      winner == null
          ? 'The game ends in a draw.'
          : 'The game is over — ${winner.name} wins.',
    RolesDealt() || NightResolved() || FallbackApplied() => null,
  };
}
