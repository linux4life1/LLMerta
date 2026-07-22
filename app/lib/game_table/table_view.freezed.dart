// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TableViewState {

 String get banner; bool get night; int get day; String? get narratorLine; (int, String)? get activeSpeech; Set<int> get dead; Set<int> get onTrial; Map<int, Role> get revealedRoles; Map<int, int?> get lastVotes; Set<int> get mafiaTeam; Role? get humanRole; int? get bulletSpentNight; bool get over; Faction? get winner;
/// Create a copy of TableViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableViewStateCopyWith<TableViewState> get copyWith => _$TableViewStateCopyWithImpl<TableViewState>(this as TableViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableViewState&&(identical(other.banner, banner) || other.banner == banner)&&(identical(other.night, night) || other.night == night)&&(identical(other.day, day) || other.day == day)&&(identical(other.narratorLine, narratorLine) || other.narratorLine == narratorLine)&&(identical(other.activeSpeech, activeSpeech) || other.activeSpeech == activeSpeech)&&const DeepCollectionEquality().equals(other.dead, dead)&&const DeepCollectionEquality().equals(other.onTrial, onTrial)&&const DeepCollectionEquality().equals(other.revealedRoles, revealedRoles)&&const DeepCollectionEquality().equals(other.lastVotes, lastVotes)&&const DeepCollectionEquality().equals(other.mafiaTeam, mafiaTeam)&&(identical(other.humanRole, humanRole) || other.humanRole == humanRole)&&(identical(other.bulletSpentNight, bulletSpentNight) || other.bulletSpentNight == bulletSpentNight)&&(identical(other.over, over) || other.over == over)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode => Object.hash(runtimeType,banner,night,day,narratorLine,activeSpeech,const DeepCollectionEquality().hash(dead),const DeepCollectionEquality().hash(onTrial),const DeepCollectionEquality().hash(revealedRoles),const DeepCollectionEquality().hash(lastVotes),const DeepCollectionEquality().hash(mafiaTeam),humanRole,bulletSpentNight,over,winner);

@override
String toString() {
  return 'TableViewState(banner: $banner, night: $night, day: $day, narratorLine: $narratorLine, activeSpeech: $activeSpeech, dead: $dead, onTrial: $onTrial, revealedRoles: $revealedRoles, lastVotes: $lastVotes, mafiaTeam: $mafiaTeam, humanRole: $humanRole, bulletSpentNight: $bulletSpentNight, over: $over, winner: $winner)';
}


}

/// @nodoc
abstract mixin class $TableViewStateCopyWith<$Res>  {
  factory $TableViewStateCopyWith(TableViewState value, $Res Function(TableViewState) _then) = _$TableViewStateCopyWithImpl;
@useResult
$Res call({
 String banner, bool night, int day, String? narratorLine, (int, String)? activeSpeech, Set<int> dead, Set<int> onTrial, Map<int, Role> revealedRoles, Map<int, int?> lastVotes, Set<int> mafiaTeam, Role? humanRole, int? bulletSpentNight, bool over, Faction? winner
});




}
/// @nodoc
class _$TableViewStateCopyWithImpl<$Res>
    implements $TableViewStateCopyWith<$Res> {
  _$TableViewStateCopyWithImpl(this._self, this._then);

  final TableViewState _self;
  final $Res Function(TableViewState) _then;

/// Create a copy of TableViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? banner = null,Object? night = null,Object? day = null,Object? narratorLine = freezed,Object? activeSpeech = freezed,Object? dead = null,Object? onTrial = null,Object? revealedRoles = null,Object? lastVotes = null,Object? mafiaTeam = null,Object? humanRole = freezed,Object? bulletSpentNight = freezed,Object? over = null,Object? winner = freezed,}) {
  return _then(_self.copyWith(
banner: null == banner ? _self.banner : banner // ignore: cast_nullable_to_non_nullable
as String,night: null == night ? _self.night : night // ignore: cast_nullable_to_non_nullable
as bool,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int,narratorLine: freezed == narratorLine ? _self.narratorLine : narratorLine // ignore: cast_nullable_to_non_nullable
as String?,activeSpeech: freezed == activeSpeech ? _self.activeSpeech : activeSpeech // ignore: cast_nullable_to_non_nullable
as (int, String)?,dead: null == dead ? _self.dead : dead // ignore: cast_nullable_to_non_nullable
as Set<int>,onTrial: null == onTrial ? _self.onTrial : onTrial // ignore: cast_nullable_to_non_nullable
as Set<int>,revealedRoles: null == revealedRoles ? _self.revealedRoles : revealedRoles // ignore: cast_nullable_to_non_nullable
as Map<int, Role>,lastVotes: null == lastVotes ? _self.lastVotes : lastVotes // ignore: cast_nullable_to_non_nullable
as Map<int, int?>,mafiaTeam: null == mafiaTeam ? _self.mafiaTeam : mafiaTeam // ignore: cast_nullable_to_non_nullable
as Set<int>,humanRole: freezed == humanRole ? _self.humanRole : humanRole // ignore: cast_nullable_to_non_nullable
as Role?,bulletSpentNight: freezed == bulletSpentNight ? _self.bulletSpentNight : bulletSpentNight // ignore: cast_nullable_to_non_nullable
as int?,over: null == over ? _self.over : over // ignore: cast_nullable_to_non_nullable
as bool,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Faction?,
  ));
}

}


/// Adds pattern-matching-related methods to [TableViewState].
extension TableViewStatePatterns on TableViewState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableViewState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableViewState value)  $default,){
final _that = this;
switch (_that) {
case _TableViewState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableViewState value)?  $default,){
final _that = this;
switch (_that) {
case _TableViewState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String banner,  bool night,  int day,  String? narratorLine,  (int, String)? activeSpeech,  Set<int> dead,  Set<int> onTrial,  Map<int, Role> revealedRoles,  Map<int, int?> lastVotes,  Set<int> mafiaTeam,  Role? humanRole,  int? bulletSpentNight,  bool over,  Faction? winner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableViewState() when $default != null:
return $default(_that.banner,_that.night,_that.day,_that.narratorLine,_that.activeSpeech,_that.dead,_that.onTrial,_that.revealedRoles,_that.lastVotes,_that.mafiaTeam,_that.humanRole,_that.bulletSpentNight,_that.over,_that.winner);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String banner,  bool night,  int day,  String? narratorLine,  (int, String)? activeSpeech,  Set<int> dead,  Set<int> onTrial,  Map<int, Role> revealedRoles,  Map<int, int?> lastVotes,  Set<int> mafiaTeam,  Role? humanRole,  int? bulletSpentNight,  bool over,  Faction? winner)  $default,) {final _that = this;
switch (_that) {
case _TableViewState():
return $default(_that.banner,_that.night,_that.day,_that.narratorLine,_that.activeSpeech,_that.dead,_that.onTrial,_that.revealedRoles,_that.lastVotes,_that.mafiaTeam,_that.humanRole,_that.bulletSpentNight,_that.over,_that.winner);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String banner,  bool night,  int day,  String? narratorLine,  (int, String)? activeSpeech,  Set<int> dead,  Set<int> onTrial,  Map<int, Role> revealedRoles,  Map<int, int?> lastVotes,  Set<int> mafiaTeam,  Role? humanRole,  int? bulletSpentNight,  bool over,  Faction? winner)?  $default,) {final _that = this;
switch (_that) {
case _TableViewState() when $default != null:
return $default(_that.banner,_that.night,_that.day,_that.narratorLine,_that.activeSpeech,_that.dead,_that.onTrial,_that.revealedRoles,_that.lastVotes,_that.mafiaTeam,_that.humanRole,_that.bulletSpentNight,_that.over,_that.winner);case _:
  return null;

}
}

}

/// @nodoc


class _TableViewState extends TableViewState {
  const _TableViewState({this.banner = 'The table is empty', this.night = false, this.day = 0, this.narratorLine, this.activeSpeech, final  Set<int> dead = const {}, final  Set<int> onTrial = const {}, final  Map<int, Role> revealedRoles = const {}, final  Map<int, int?> lastVotes = const {}, final  Set<int> mafiaTeam = const {}, this.humanRole, this.bulletSpentNight, this.over = false, this.winner}): _dead = dead,_onTrial = onTrial,_revealedRoles = revealedRoles,_lastVotes = lastVotes,_mafiaTeam = mafiaTeam,super._();
  

@override@JsonKey() final  String banner;
@override@JsonKey() final  bool night;
@override@JsonKey() final  int day;
@override final  String? narratorLine;
@override final  (int, String)? activeSpeech;
 final  Set<int> _dead;
@override@JsonKey() Set<int> get dead {
  if (_dead is EqualUnmodifiableSetView) return _dead;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_dead);
}

 final  Set<int> _onTrial;
@override@JsonKey() Set<int> get onTrial {
  if (_onTrial is EqualUnmodifiableSetView) return _onTrial;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_onTrial);
}

 final  Map<int, Role> _revealedRoles;
@override@JsonKey() Map<int, Role> get revealedRoles {
  if (_revealedRoles is EqualUnmodifiableMapView) return _revealedRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_revealedRoles);
}

 final  Map<int, int?> _lastVotes;
@override@JsonKey() Map<int, int?> get lastVotes {
  if (_lastVotes is EqualUnmodifiableMapView) return _lastVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lastVotes);
}

 final  Set<int> _mafiaTeam;
@override@JsonKey() Set<int> get mafiaTeam {
  if (_mafiaTeam is EqualUnmodifiableSetView) return _mafiaTeam;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_mafiaTeam);
}

@override final  Role? humanRole;
@override final  int? bulletSpentNight;
@override@JsonKey() final  bool over;
@override final  Faction? winner;

/// Create a copy of TableViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableViewStateCopyWith<_TableViewState> get copyWith => __$TableViewStateCopyWithImpl<_TableViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableViewState&&(identical(other.banner, banner) || other.banner == banner)&&(identical(other.night, night) || other.night == night)&&(identical(other.day, day) || other.day == day)&&(identical(other.narratorLine, narratorLine) || other.narratorLine == narratorLine)&&(identical(other.activeSpeech, activeSpeech) || other.activeSpeech == activeSpeech)&&const DeepCollectionEquality().equals(other._dead, _dead)&&const DeepCollectionEquality().equals(other._onTrial, _onTrial)&&const DeepCollectionEquality().equals(other._revealedRoles, _revealedRoles)&&const DeepCollectionEquality().equals(other._lastVotes, _lastVotes)&&const DeepCollectionEquality().equals(other._mafiaTeam, _mafiaTeam)&&(identical(other.humanRole, humanRole) || other.humanRole == humanRole)&&(identical(other.bulletSpentNight, bulletSpentNight) || other.bulletSpentNight == bulletSpentNight)&&(identical(other.over, over) || other.over == over)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode => Object.hash(runtimeType,banner,night,day,narratorLine,activeSpeech,const DeepCollectionEquality().hash(_dead),const DeepCollectionEquality().hash(_onTrial),const DeepCollectionEquality().hash(_revealedRoles),const DeepCollectionEquality().hash(_lastVotes),const DeepCollectionEquality().hash(_mafiaTeam),humanRole,bulletSpentNight,over,winner);

@override
String toString() {
  return 'TableViewState(banner: $banner, night: $night, day: $day, narratorLine: $narratorLine, activeSpeech: $activeSpeech, dead: $dead, onTrial: $onTrial, revealedRoles: $revealedRoles, lastVotes: $lastVotes, mafiaTeam: $mafiaTeam, humanRole: $humanRole, bulletSpentNight: $bulletSpentNight, over: $over, winner: $winner)';
}


}

/// @nodoc
abstract mixin class _$TableViewStateCopyWith<$Res> implements $TableViewStateCopyWith<$Res> {
  factory _$TableViewStateCopyWith(_TableViewState value, $Res Function(_TableViewState) _then) = __$TableViewStateCopyWithImpl;
@override @useResult
$Res call({
 String banner, bool night, int day, String? narratorLine, (int, String)? activeSpeech, Set<int> dead, Set<int> onTrial, Map<int, Role> revealedRoles, Map<int, int?> lastVotes, Set<int> mafiaTeam, Role? humanRole, int? bulletSpentNight, bool over, Faction? winner
});




}
/// @nodoc
class __$TableViewStateCopyWithImpl<$Res>
    implements _$TableViewStateCopyWith<$Res> {
  __$TableViewStateCopyWithImpl(this._self, this._then);

  final _TableViewState _self;
  final $Res Function(_TableViewState) _then;

/// Create a copy of TableViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? banner = null,Object? night = null,Object? day = null,Object? narratorLine = freezed,Object? activeSpeech = freezed,Object? dead = null,Object? onTrial = null,Object? revealedRoles = null,Object? lastVotes = null,Object? mafiaTeam = null,Object? humanRole = freezed,Object? bulletSpentNight = freezed,Object? over = null,Object? winner = freezed,}) {
  return _then(_TableViewState(
banner: null == banner ? _self.banner : banner // ignore: cast_nullable_to_non_nullable
as String,night: null == night ? _self.night : night // ignore: cast_nullable_to_non_nullable
as bool,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int,narratorLine: freezed == narratorLine ? _self.narratorLine : narratorLine // ignore: cast_nullable_to_non_nullable
as String?,activeSpeech: freezed == activeSpeech ? _self.activeSpeech : activeSpeech // ignore: cast_nullable_to_non_nullable
as (int, String)?,dead: null == dead ? _self._dead : dead // ignore: cast_nullable_to_non_nullable
as Set<int>,onTrial: null == onTrial ? _self._onTrial : onTrial // ignore: cast_nullable_to_non_nullable
as Set<int>,revealedRoles: null == revealedRoles ? _self._revealedRoles : revealedRoles // ignore: cast_nullable_to_non_nullable
as Map<int, Role>,lastVotes: null == lastVotes ? _self._lastVotes : lastVotes // ignore: cast_nullable_to_non_nullable
as Map<int, int?>,mafiaTeam: null == mafiaTeam ? _self._mafiaTeam : mafiaTeam // ignore: cast_nullable_to_non_nullable
as Set<int>,humanRole: freezed == humanRole ? _self.humanRole : humanRole // ignore: cast_nullable_to_non_nullable
as Role?,bulletSpentNight: freezed == bulletSpentNight ? _self.bulletSpentNight : bulletSpentNight // ignore: cast_nullable_to_non_nullable
as int?,over: null == over ? _self.over : over // ignore: cast_nullable_to_non_nullable
as bool,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Faction?,
  ));
}


}

// dart format on
