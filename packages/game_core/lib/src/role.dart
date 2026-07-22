enum Faction { town, mafia }

enum Role {
  mafioso(Faction.mafia),
  doctor(Faction.town),
  sheriff(Faction.town),
  assassin(Faction.town),
  villager(Faction.town);

  const Role(this.faction);

  final Faction faction;
}
