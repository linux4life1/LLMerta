/// Visibility scopes from GAME_DESIGN.md §6. Every event carries exactly one.
sealed class Scope {
  const Scope();

  /// [isMafia] is the viewer's own alignment knowledge; mafia-scoped events
  /// are visible only to mafia seats.
  bool visibleTo(int seat, {required bool isMafia}) => switch (this) {
    PublicScope() => true,
    MafiaScope() => isMafia,
    PrivateScope(seat: final s) => s == seat,
    OmniscientScope() => false,
  };
}

class PublicScope extends Scope {
  const PublicScope();
}

class MafiaScope extends Scope {
  const MafiaScope();
}

class PrivateScope extends Scope {
  const PrivateScope(this.seat);

  final int seat;
}

class OmniscientScope extends Scope {
  const OmniscientScope();
}

const public = PublicScope();
const mafiaOnly = MafiaScope();
const omniscient = OmniscientScope();
