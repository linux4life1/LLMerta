import 'config.dart';
import 'event.dart';
import 'role.dart';

/// JSON codec for saves and replays (ARCHITECTURE.md §3: a save file is
/// `{config, rngSeed, events[]}`). Scopes are derived, never serialized.

Map<String, Object?> eventToJson(GameEvent event) => switch (event) {
  GameStarted(:final seats) => {'t': 'gameStarted', 'seats': seats},
  RolesDealt(:final roles) => {
    't': 'rolesDealt',
    'roles': {
      for (final MapEntry(:key, :value) in roles.entries) '$key': value.name,
    },
  },
  RoleReceived(:final seat, :final role) => {
    't': 'roleReceived',
    'seat': seat,
    'role': role.name,
  },
  MafiaTeamRevealed(:final team) => {
    't': 'mafiaTeamRevealed',
    'team': [...team],
  },
  NightBegan(:final day) => {'t': 'nightBegan', 'day': day},
  DayBegan(:final day) => {'t': 'dayBegan', 'day': day},
  DawnAnnounced(:final deaths, :final revealedRoles) => {
    't': 'dawnAnnounced',
    'deaths': deaths,
    'revealedRoles': {
      for (final MapEntry(:key, :value) in revealedRoles.entries)
        '$key': value.name,
    },
  },
  SpeechGiven(:final seat, :final text) => {
    't': 'speechGiven',
    'seat': seat,
    'text': text,
  },
  ArgumentOpened(:final by, :final to, :final text) => {
    't': 'argumentOpened',
    'by': by,
    'to': to,
    'text': text,
  }, // to may be null (pass)
  ArgumentRebuttal(:final by, :final to, :final text) => {
    't': 'argumentRebuttal',
    'by': by,
    'to': to,
    'text': text,
  },
  NominationCast(:final by, :final target, :final statement) => {
    't': 'nominationCast',
    'by': by,
    'target': target,
    'statement': statement,
  },
  TrialStarted(:final nominees) => {'t': 'trialStarted', 'nominees': nominees},
  DefenseGiven(:final seat, :final text) => {
    't': 'defenseGiven',
    'seat': seat,
    'text': text,
  },
  VotesRevealed(:final votes) => {
    't': 'votesRevealed',
    'votes': {
      for (final MapEntry(:key, :value) in votes.entries) '$key': value,
    },
  },
  Verdict(:final eliminated, :final revealedRole) => {
    't': 'verdict',
    'eliminated': eliminated,
    'revealedRole': revealedRole?.name,
  },
  LastWordsGiven(:final seat, :final text) => {
    't': 'lastWordsGiven',
    'seat': seat,
    'text': text,
  },
  MafiaChatSaid(:final seat, :final text) => {
    't': 'mafiaChatSaid',
    'seat': seat,
    'text': text,
  },
  MafiaKillVoteCast(:final by, :final target) => {
    't': 'mafiaKillVoteCast',
    'by': by,
    'target': target,
  },
  MafiaKillChosen(:final target) => {'t': 'mafiaKillChosen', 'target': target},
  DoctorProtected(:final doctor, :final target) => {
    't': 'doctorProtected',
    'doctor': doctor,
    'target': target,
  },
  SheriffInvestigated(:final sheriff, :final target, :final foundMafia) => {
    't': 'sheriffInvestigated',
    'sheriff': sheriff,
    'target': target,
    'foundMafia': foundMafia,
  },
  AssassinDecided(:final assassin, :final target) => {
    't': 'assassinDecided',
    'assassin': assassin,
    'target': target,
  },
  AssassinShotResolved(
    :final assassin,
    :final target,
    :final killed,
    :final wasMafia,
  ) =>
    {
      't': 'assassinShotResolved',
      'assassin': assassin,
      'target': target,
      'killed': killed,
      'wasMafia': wasMafia,
    },
  NightResolved(:final killed, :final saved) => {
    't': 'nightResolved',
    'killed': killed,
    'saved': saved,
  },
  FallbackApplied(:final seat, :final action, :final reason) => {
    't': 'fallbackApplied',
    'seat': seat,
    'action': action,
    'reason': reason,
  },
  GameEnded(:final winner) => {'t': 'gameEnded', 'winner': winner?.name},
};

Role _role(Object? name) => Role.values.byName(name! as String);

List<int> _seats(Object? list) => (list! as List).cast<int>();

GameEvent eventFromJson(Map<String, Object?> json) => switch (json['t']) {
  'gameStarted' => GameStarted(seats: json['seats']! as int),
  'rolesDealt' => RolesDealt({
    for (final MapEntry(:key, :value)
        in (json['roles']! as Map<String, Object?>).entries)
      int.parse(key): _role(value),
  }),
  'roleReceived' => RoleReceived(
    seat: json['seat']! as int,
    role: _role(json['role']),
  ),
  'mafiaTeamRevealed' => MafiaTeamRevealed({..._seats(json['team'])}),
  'nightBegan' => NightBegan(json['day']! as int),
  'dayBegan' => DayBegan(json['day']! as int),
  'dawnAnnounced' => DawnAnnounced(
    deaths: _seats(json['deaths']),
    revealedRoles: {
      for (final MapEntry(:key, :value)
          in (json['revealedRoles']! as Map<String, Object?>).entries)
        int.parse(key): _role(value),
    },
  ),
  'speechGiven' => SpeechGiven(
    seat: json['seat']! as int,
    text: json['text']! as String,
  ),
  'argumentOpened' => ArgumentOpened(
    by: json['by']! as int,
    to: json['to'] as int?,
    text: json['text']! as String,
  ),
  'argumentRebuttal' => ArgumentRebuttal(
    by: json['by']! as int,
    to: json['to']! as int,
    text: json['text']! as String,
  ),
  'nominationCast' => NominationCast(
    by: json['by']! as int,
    target: json['target'] as int?,
    statement: json['statement'] as String? ?? '',
  ),
  'trialStarted' => TrialStarted(_seats(json['nominees'])),
  'defenseGiven' => DefenseGiven(
    seat: json['seat']! as int,
    text: json['text']! as String,
  ),
  'votesRevealed' => VotesRevealed({
    for (final MapEntry(:key, :value)
        in (json['votes']! as Map<String, Object?>).entries)
      int.parse(key): value as int?,
  }),
  'verdict' => Verdict(
    eliminated: json['eliminated'] as int?,
    revealedRole: json['revealedRole'] == null
        ? null
        : _role(json['revealedRole']),
  ),
  'lastWordsGiven' => LastWordsGiven(
    seat: json['seat']! as int,
    text: json['text']! as String,
  ),
  'mafiaChatSaid' => MafiaChatSaid(
    seat: json['seat']! as int,
    text: json['text']! as String,
  ),
  'mafiaKillVoteCast' => MafiaKillVoteCast(
    by: json['by']! as int,
    target: json['target'] as int?,
  ),
  'mafiaKillChosen' => MafiaKillChosen(json['target'] as int?),
  'doctorProtected' => DoctorProtected(
    doctor: json['doctor']! as int,
    target: json['target']! as int,
  ),
  'sheriffInvestigated' => SheriffInvestigated(
    sheriff: json['sheriff']! as int,
    target: json['target']! as int,
    foundMafia: json['foundMafia']! as bool,
  ),
  'assassinDecided' => AssassinDecided(
    assassin: json['assassin']! as int,
    target: json['target'] as int?,
  ),
  'assassinShotResolved' => AssassinShotResolved(
    assassin: json['assassin']! as int,
    target: json['target']! as int,
    killed: json['killed']! as bool,
    wasMafia: json['wasMafia']! as bool,
  ),
  'nightResolved' => NightResolved(
    killed: _seats(json['killed']),
    saved: _seats(json['saved']),
  ),
  'fallbackApplied' => FallbackApplied(
    seat: json['seat']! as int,
    action: json['action']! as String,
    reason: json['reason']! as String,
  ),
  'gameEnded' => GameEnded(
    winner: json['winner'] == null
        ? null
        : Faction.values.byName(json['winner']! as String),
  ),
  _ => throw FormatException('Unknown event type ${json['t']}'),
};

Map<String, Object?> configToJson(GameConfig config) => {
  'seats': config.seats,
  'doctorMayProtectSelf': config.doctorMayProtectSelf,
  'doctorNoRepeatTarget': config.doctorNoRepeatTarget,
  'night0': config.night0,
  'night0SheriffPeek': config.night0SheriffPeek,
  'revealRolesOnDeath': config.revealRolesOnDeath,
  'discussionRounds': config.discussionRounds,
  'crossfireRounds': config.crossfireRounds,
  'nomineesVote': config.nomineesVote,
  'tieRule': config.tieRule.name,
  'includeDoctor': config.includeDoctor,
  'includeSheriff': config.includeSheriff,
  'includeAssassin': config.includeAssassin,
  'mafiaCountDelta': config.mafiaCountDelta,
  'maxDays': config.maxDays,
};

GameConfig configFromJson(Map<String, Object?> json) => GameConfig(
  seats: json['seats']! as int,
  doctorMayProtectSelf: json['doctorMayProtectSelf']! as bool,
  doctorNoRepeatTarget: json['doctorNoRepeatTarget']! as bool,
  night0: json['night0']! as bool,
  night0SheriffPeek: json['night0SheriffPeek']! as bool,
  revealRolesOnDeath: json['revealRolesOnDeath']! as bool,
  discussionRounds: json['discussionRounds']! as int,
  crossfireRounds: json['crossfireRounds'] as int? ?? 0,
  nomineesVote: json['nomineesVote']! as bool,
  tieRule: TieRule.values.byName(json['tieRule']! as String),
  includeDoctor: json['includeDoctor']! as bool,
  includeSheriff: json['includeSheriff']! as bool,
  includeAssassin: json['includeAssassin']! as bool,
  mafiaCountDelta: json['mafiaCountDelta']! as int,
  maxDays: json['maxDays']! as int,
);
