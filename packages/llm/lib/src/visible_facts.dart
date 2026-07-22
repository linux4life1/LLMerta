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
  final Set<int> mafiaTeam = {};
  final Map<int, bool> investigations = {};
  bool bulletSpent = false;
  int? lastProtected;
  Role? ownRole;

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
        case Verdict(:final eliminated, :final revealedRole):
          if (eliminated != null) {
            f.alive.remove(eliminated);
            if (revealedRole != null) {
              f.revealedRoles[eliminated] = revealedRole;
            }
          }
        case SheriffInvestigated(:final target, :final foundMafia):
          f.investigations[target] = foundMafia;
        case AssassinDecided(:final target):
          if (target != null) f.bulletSpent = true;
        case DoctorProtected(:final target):
          f.lastProtected = target;
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
  String n(int seat) => '${names[seat]} (seat $seat)';
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
                      '${n(s)} was found dead'
                      '${revealedRoles[s] != null ? ' — they were the ${revealedRoles[s]!.name}' : ''}.',
                )
                .join(' '),
    SpeechGiven(:final seat, :final text) => '${n(seat)}: "$text"',
    NominationCast(:final by, :final target) =>
      target == null ? '${n(by)} passes.' : '${n(by)} nominates ${n(target)}.',
    TrialStarted(:final nominees) => 'On trial: ${nominees.map(n).join(', ')}.',
    DefenseGiven(:final seat, :final text) => '${n(seat)} (defense): "$text"',
    VotesRevealed(:final votes) =>
      'Votes: ${votes.entries.map((e) => e.value == null ? '${names[e.key]}→abstain' : '${names[e.key]}→${names[e.value!]}').join(', ')}.',
    Verdict(:final eliminated, :final revealedRole) =>
      eliminated == null
          ? 'The vote fails — nobody is eliminated.'
          : '${n(eliminated)} is eliminated'
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
    GameEnded(:final winner) =>
      winner == null
          ? 'The game ends in a draw.'
          : 'The game is over — ${winner.name} wins.',
    RolesDealt() || NightResolved() || FallbackApplied() => null,
  };
}
