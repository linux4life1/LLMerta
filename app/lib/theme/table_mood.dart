import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'table_mood.g.dart';

enum TableMood { day, night }

@riverpod
class TableMoodController extends _$TableMoodController {
  @override
  TableMood build() => TableMood.night;

  void set(TableMood mood) => state = mood;
}
