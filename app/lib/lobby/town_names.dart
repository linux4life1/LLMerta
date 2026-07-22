import 'dart:math';

/// Curated pool (UI_UX.md §4.6): the town name anchors narrator copy,
/// persona flavor, and save names.
const townNamePool = [
  'Brasshollow',
  'Veilport',
  'Cinder Falls',
  'Moretti Bay',
  'Gaslamp Hollow',
  'Duskwater',
  'Salt & Ash',
  'Ravenmoor',
  'Old Calvera',
  'Fogline',
  'Marrow Creek',
  'Vetralla',
  'Hushfield',
  'Palermo Heights',
  'Larkspur Landing',
  'Nocturne Bluffs',
  'Silverstrand',
  'Corvo Junction',
  'Ambergris Row',
  "Widow's Harbor",
  'Tenebria',
  'Rustcanal',
  'Mirefield',
  'Sotto Voce',
];

String pickTownName(Random rng, {String? avoid}) {
  final pool = [
    for (final name in townNamePool)
      if (name != avoid) name,
  ];
  return pool[rng.nextInt(pool.length)];
}
