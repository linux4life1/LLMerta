// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSession {

 GameStage get stage; List<GameEvent> get visibleEvents; int get humanSeat; List<String> get names; Map<int, String> get modelBadges; Map<int, Persona> get personas; bool get humanIsMafia; Scene? get scene; String? get townName; String? get gameId; String get notes; Faction? get winner; String? get error;
/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSessionCopyWith<GameSession> get copyWith => _$GameSessionCopyWithImpl<GameSession>(this as GameSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSession&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other.visibleEvents, visibleEvents)&&(identical(other.humanSeat, humanSeat) || other.humanSeat == humanSeat)&&const DeepCollectionEquality().equals(other.names, names)&&const DeepCollectionEquality().equals(other.modelBadges, modelBadges)&&const DeepCollectionEquality().equals(other.personas, personas)&&(identical(other.humanIsMafia, humanIsMafia) || other.humanIsMafia == humanIsMafia)&&(identical(other.scene, scene) || other.scene == scene)&&(identical(other.townName, townName) || other.townName == townName)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.winner, winner) || other.winner == winner)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,stage,const DeepCollectionEquality().hash(visibleEvents),humanSeat,const DeepCollectionEquality().hash(names),const DeepCollectionEquality().hash(modelBadges),const DeepCollectionEquality().hash(personas),humanIsMafia,scene,townName,gameId,notes,winner,error);

@override
String toString() {
  return 'GameSession(stage: $stage, visibleEvents: $visibleEvents, humanSeat: $humanSeat, names: $names, modelBadges: $modelBadges, personas: $personas, humanIsMafia: $humanIsMafia, scene: $scene, townName: $townName, gameId: $gameId, notes: $notes, winner: $winner, error: $error)';
}


}

/// @nodoc
abstract mixin class $GameSessionCopyWith<$Res>  {
  factory $GameSessionCopyWith(GameSession value, $Res Function(GameSession) _then) = _$GameSessionCopyWithImpl;
@useResult
$Res call({
 GameStage stage, List<GameEvent> visibleEvents, int humanSeat, List<String> names, Map<int, String> modelBadges, Map<int, Persona> personas, bool humanIsMafia, Scene? scene, String? townName, String? gameId, String notes, Faction? winner, String? error
});




}
/// @nodoc
class _$GameSessionCopyWithImpl<$Res>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._self, this._then);

  final GameSession _self;
  final $Res Function(GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? visibleEvents = null,Object? humanSeat = null,Object? names = null,Object? modelBadges = null,Object? personas = null,Object? humanIsMafia = null,Object? scene = freezed,Object? townName = freezed,Object? gameId = freezed,Object? notes = null,Object? winner = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as GameStage,visibleEvents: null == visibleEvents ? _self.visibleEvents : visibleEvents // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,humanSeat: null == humanSeat ? _self.humanSeat : humanSeat // ignore: cast_nullable_to_non_nullable
as int,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as List<String>,modelBadges: null == modelBadges ? _self.modelBadges : modelBadges // ignore: cast_nullable_to_non_nullable
as Map<int, String>,personas: null == personas ? _self.personas : personas // ignore: cast_nullable_to_non_nullable
as Map<int, Persona>,humanIsMafia: null == humanIsMafia ? _self.humanIsMafia : humanIsMafia // ignore: cast_nullable_to_non_nullable
as bool,scene: freezed == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as Scene?,townName: freezed == townName ? _self.townName : townName // ignore: cast_nullable_to_non_nullable
as String?,gameId: freezed == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Faction?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameSession].
extension GameSessionPatterns on GameSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSession value)  $default,){
final _that = this;
switch (_that) {
case _GameSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSession value)?  $default,){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameStage stage,  List<GameEvent> visibleEvents,  int humanSeat,  List<String> names,  Map<int, String> modelBadges,  Map<int, Persona> personas,  bool humanIsMafia,  Scene? scene,  String? townName,  String? gameId,  String notes,  Faction? winner,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.stage,_that.visibleEvents,_that.humanSeat,_that.names,_that.modelBadges,_that.personas,_that.humanIsMafia,_that.scene,_that.townName,_that.gameId,_that.notes,_that.winner,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameStage stage,  List<GameEvent> visibleEvents,  int humanSeat,  List<String> names,  Map<int, String> modelBadges,  Map<int, Persona> personas,  bool humanIsMafia,  Scene? scene,  String? townName,  String? gameId,  String notes,  Faction? winner,  String? error)  $default,) {final _that = this;
switch (_that) {
case _GameSession():
return $default(_that.stage,_that.visibleEvents,_that.humanSeat,_that.names,_that.modelBadges,_that.personas,_that.humanIsMafia,_that.scene,_that.townName,_that.gameId,_that.notes,_that.winner,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameStage stage,  List<GameEvent> visibleEvents,  int humanSeat,  List<String> names,  Map<int, String> modelBadges,  Map<int, Persona> personas,  bool humanIsMafia,  Scene? scene,  String? townName,  String? gameId,  String notes,  Faction? winner,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.stage,_that.visibleEvents,_that.humanSeat,_that.names,_that.modelBadges,_that.personas,_that.humanIsMafia,_that.scene,_that.townName,_that.gameId,_that.notes,_that.winner,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _GameSession implements GameSession {
  const _GameSession({this.stage = GameStage.idle, final  List<GameEvent> visibleEvents = const [], this.humanSeat = 0, final  List<String> names = const [], final  Map<int, String> modelBadges = const {}, final  Map<int, Persona> personas = const {}, this.humanIsMafia = false, this.scene, this.townName, this.gameId, this.notes = '', this.winner, this.error}): _visibleEvents = visibleEvents,_names = names,_modelBadges = modelBadges,_personas = personas;
  

@override@JsonKey() final  GameStage stage;
 final  List<GameEvent> _visibleEvents;
@override@JsonKey() List<GameEvent> get visibleEvents {
  if (_visibleEvents is EqualUnmodifiableListView) return _visibleEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleEvents);
}

@override@JsonKey() final  int humanSeat;
 final  List<String> _names;
@override@JsonKey() List<String> get names {
  if (_names is EqualUnmodifiableListView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_names);
}

 final  Map<int, String> _modelBadges;
@override@JsonKey() Map<int, String> get modelBadges {
  if (_modelBadges is EqualUnmodifiableMapView) return _modelBadges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_modelBadges);
}

 final  Map<int, Persona> _personas;
@override@JsonKey() Map<int, Persona> get personas {
  if (_personas is EqualUnmodifiableMapView) return _personas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_personas);
}

@override@JsonKey() final  bool humanIsMafia;
@override final  Scene? scene;
@override final  String? townName;
@override final  String? gameId;
@override@JsonKey() final  String notes;
@override final  Faction? winner;
@override final  String? error;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSessionCopyWith<_GameSession> get copyWith => __$GameSessionCopyWithImpl<_GameSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSession&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other._visibleEvents, _visibleEvents)&&(identical(other.humanSeat, humanSeat) || other.humanSeat == humanSeat)&&const DeepCollectionEquality().equals(other._names, _names)&&const DeepCollectionEquality().equals(other._modelBadges, _modelBadges)&&const DeepCollectionEquality().equals(other._personas, _personas)&&(identical(other.humanIsMafia, humanIsMafia) || other.humanIsMafia == humanIsMafia)&&(identical(other.scene, scene) || other.scene == scene)&&(identical(other.townName, townName) || other.townName == townName)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.winner, winner) || other.winner == winner)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,stage,const DeepCollectionEquality().hash(_visibleEvents),humanSeat,const DeepCollectionEquality().hash(_names),const DeepCollectionEquality().hash(_modelBadges),const DeepCollectionEquality().hash(_personas),humanIsMafia,scene,townName,gameId,notes,winner,error);

@override
String toString() {
  return 'GameSession(stage: $stage, visibleEvents: $visibleEvents, humanSeat: $humanSeat, names: $names, modelBadges: $modelBadges, personas: $personas, humanIsMafia: $humanIsMafia, scene: $scene, townName: $townName, gameId: $gameId, notes: $notes, winner: $winner, error: $error)';
}


}

/// @nodoc
abstract mixin class _$GameSessionCopyWith<$Res> implements $GameSessionCopyWith<$Res> {
  factory _$GameSessionCopyWith(_GameSession value, $Res Function(_GameSession) _then) = __$GameSessionCopyWithImpl;
@override @useResult
$Res call({
 GameStage stage, List<GameEvent> visibleEvents, int humanSeat, List<String> names, Map<int, String> modelBadges, Map<int, Persona> personas, bool humanIsMafia, Scene? scene, String? townName, String? gameId, String notes, Faction? winner, String? error
});




}
/// @nodoc
class __$GameSessionCopyWithImpl<$Res>
    implements _$GameSessionCopyWith<$Res> {
  __$GameSessionCopyWithImpl(this._self, this._then);

  final _GameSession _self;
  final $Res Function(_GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? visibleEvents = null,Object? humanSeat = null,Object? names = null,Object? modelBadges = null,Object? personas = null,Object? humanIsMafia = null,Object? scene = freezed,Object? townName = freezed,Object? gameId = freezed,Object? notes = null,Object? winner = freezed,Object? error = freezed,}) {
  return _then(_GameSession(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as GameStage,visibleEvents: null == visibleEvents ? _self._visibleEvents : visibleEvents // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,humanSeat: null == humanSeat ? _self.humanSeat : humanSeat // ignore: cast_nullable_to_non_nullable
as int,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as List<String>,modelBadges: null == modelBadges ? _self._modelBadges : modelBadges // ignore: cast_nullable_to_non_nullable
as Map<int, String>,personas: null == personas ? _self._personas : personas // ignore: cast_nullable_to_non_nullable
as Map<int, Persona>,humanIsMafia: null == humanIsMafia ? _self.humanIsMafia : humanIsMafia // ignore: cast_nullable_to_non_nullable
as bool,scene: freezed == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as Scene?,townName: freezed == townName ? _self.townName : townName // ignore: cast_nullable_to_non_nullable
as String?,gameId: freezed == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Faction?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
