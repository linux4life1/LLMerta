// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lobby_setup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SeatCasting {

 String? get personaName; String? get connectionId; String? get model; double get temperature; String? get voice;
/// Create a copy of SeatCasting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatCastingCopyWith<SeatCasting> get copyWith => _$SeatCastingCopyWithImpl<SeatCasting>(this as SeatCasting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatCasting&&(identical(other.personaName, personaName) || other.personaName == personaName)&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.voice, voice) || other.voice == voice));
}


@override
int get hashCode => Object.hash(runtimeType,personaName,connectionId,model,temperature,voice);

@override
String toString() {
  return 'SeatCasting(personaName: $personaName, connectionId: $connectionId, model: $model, temperature: $temperature, voice: $voice)';
}


}

/// @nodoc
abstract mixin class $SeatCastingCopyWith<$Res>  {
  factory $SeatCastingCopyWith(SeatCasting value, $Res Function(SeatCasting) _then) = _$SeatCastingCopyWithImpl;
@useResult
$Res call({
 String? personaName, String? connectionId, String? model, double temperature, String? voice
});




}
/// @nodoc
class _$SeatCastingCopyWithImpl<$Res>
    implements $SeatCastingCopyWith<$Res> {
  _$SeatCastingCopyWithImpl(this._self, this._then);

  final SeatCasting _self;
  final $Res Function(SeatCasting) _then;

/// Create a copy of SeatCasting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? personaName = freezed,Object? connectionId = freezed,Object? model = freezed,Object? temperature = null,Object? voice = freezed,}) {
  return _then(_self.copyWith(
personaName: freezed == personaName ? _self.personaName : personaName // ignore: cast_nullable_to_non_nullable
as String?,connectionId: freezed == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeatCasting].
extension SeatCastingPatterns on SeatCasting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatCasting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatCasting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatCasting value)  $default,){
final _that = this;
switch (_that) {
case _SeatCasting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatCasting value)?  $default,){
final _that = this;
switch (_that) {
case _SeatCasting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? personaName,  String? connectionId,  String? model,  double temperature,  String? voice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatCasting() when $default != null:
return $default(_that.personaName,_that.connectionId,_that.model,_that.temperature,_that.voice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? personaName,  String? connectionId,  String? model,  double temperature,  String? voice)  $default,) {final _that = this;
switch (_that) {
case _SeatCasting():
return $default(_that.personaName,_that.connectionId,_that.model,_that.temperature,_that.voice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? personaName,  String? connectionId,  String? model,  double temperature,  String? voice)?  $default,) {final _that = this;
switch (_that) {
case _SeatCasting() when $default != null:
return $default(_that.personaName,_that.connectionId,_that.model,_that.temperature,_that.voice);case _:
  return null;

}
}

}

/// @nodoc


class _SeatCasting implements SeatCasting {
  const _SeatCasting({this.personaName, this.connectionId, this.model, this.temperature = 0.7, this.voice});
  

@override final  String? personaName;
@override final  String? connectionId;
@override final  String? model;
@override@JsonKey() final  double temperature;
@override final  String? voice;

/// Create a copy of SeatCasting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatCastingCopyWith<_SeatCasting> get copyWith => __$SeatCastingCopyWithImpl<_SeatCasting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatCasting&&(identical(other.personaName, personaName) || other.personaName == personaName)&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.model, model) || other.model == model)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.voice, voice) || other.voice == voice));
}


@override
int get hashCode => Object.hash(runtimeType,personaName,connectionId,model,temperature,voice);

@override
String toString() {
  return 'SeatCasting(personaName: $personaName, connectionId: $connectionId, model: $model, temperature: $temperature, voice: $voice)';
}


}

/// @nodoc
abstract mixin class _$SeatCastingCopyWith<$Res> implements $SeatCastingCopyWith<$Res> {
  factory _$SeatCastingCopyWith(_SeatCasting value, $Res Function(_SeatCasting) _then) = __$SeatCastingCopyWithImpl;
@override @useResult
$Res call({
 String? personaName, String? connectionId, String? model, double temperature, String? voice
});




}
/// @nodoc
class __$SeatCastingCopyWithImpl<$Res>
    implements _$SeatCastingCopyWith<$Res> {
  __$SeatCastingCopyWithImpl(this._self, this._then);

  final _SeatCasting _self;
  final $Res Function(_SeatCasting) _then;

/// Create a copy of SeatCasting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? personaName = freezed,Object? connectionId = freezed,Object? model = freezed,Object? temperature = null,Object? voice = freezed,}) {
  return _then(_SeatCasting(
personaName: freezed == personaName ? _self.personaName : personaName // ignore: cast_nullable_to_non_nullable
as String?,connectionId: freezed == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$LobbySetup {

 GameConfig get config; String get townName; List<SeatCasting> get seats; Difficulty get difficulty; Scene get scene; int get humanSeat; String get humanName; FpPersona? get humanPersona; bool get grudgeMode;/// Write multi-card game memories for Front Porch AI (pending JSON).
 bool get porchMemories;
/// Create a copy of LobbySetup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LobbySetupCopyWith<LobbySetup> get copyWith => _$LobbySetupCopyWithImpl<LobbySetup>(this as LobbySetup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LobbySetup&&(identical(other.config, config) || other.config == config)&&(identical(other.townName, townName) || other.townName == townName)&&const DeepCollectionEquality().equals(other.seats, seats)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.scene, scene) || other.scene == scene)&&(identical(other.humanSeat, humanSeat) || other.humanSeat == humanSeat)&&(identical(other.humanName, humanName) || other.humanName == humanName)&&(identical(other.humanPersona, humanPersona) || other.humanPersona == humanPersona)&&(identical(other.grudgeMode, grudgeMode) || other.grudgeMode == grudgeMode)&&(identical(other.porchMemories, porchMemories) || other.porchMemories == porchMemories));
}


@override
int get hashCode => Object.hash(runtimeType,config,townName,const DeepCollectionEquality().hash(seats),difficulty,scene,humanSeat,humanName,humanPersona,grudgeMode,porchMemories);

@override
String toString() {
  return 'LobbySetup(config: $config, townName: $townName, seats: $seats, difficulty: $difficulty, scene: $scene, humanSeat: $humanSeat, humanName: $humanName, humanPersona: $humanPersona, grudgeMode: $grudgeMode, porchMemories: $porchMemories)';
}


}

/// @nodoc
abstract mixin class $LobbySetupCopyWith<$Res>  {
  factory $LobbySetupCopyWith(LobbySetup value, $Res Function(LobbySetup) _then) = _$LobbySetupCopyWithImpl;
@useResult
$Res call({
 GameConfig config, String townName, List<SeatCasting> seats, Difficulty difficulty, Scene scene, int humanSeat, String humanName, FpPersona? humanPersona, bool grudgeMode, bool porchMemories
});




}
/// @nodoc
class _$LobbySetupCopyWithImpl<$Res>
    implements $LobbySetupCopyWith<$Res> {
  _$LobbySetupCopyWithImpl(this._self, this._then);

  final LobbySetup _self;
  final $Res Function(LobbySetup) _then;

/// Create a copy of LobbySetup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? config = null,Object? townName = null,Object? seats = null,Object? difficulty = null,Object? scene = null,Object? humanSeat = null,Object? humanName = null,Object? humanPersona = freezed,Object? grudgeMode = null,Object? porchMemories = null,}) {
  return _then(_self.copyWith(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,townName: null == townName ? _self.townName : townName // ignore: cast_nullable_to_non_nullable
as String,seats: null == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as List<SeatCasting>,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,scene: null == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as Scene,humanSeat: null == humanSeat ? _self.humanSeat : humanSeat // ignore: cast_nullable_to_non_nullable
as int,humanName: null == humanName ? _self.humanName : humanName // ignore: cast_nullable_to_non_nullable
as String,humanPersona: freezed == humanPersona ? _self.humanPersona : humanPersona // ignore: cast_nullable_to_non_nullable
as FpPersona?,grudgeMode: null == grudgeMode ? _self.grudgeMode : grudgeMode // ignore: cast_nullable_to_non_nullable
as bool,porchMemories: null == porchMemories ? _self.porchMemories : porchMemories // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LobbySetup].
extension LobbySetupPatterns on LobbySetup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LobbySetup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LobbySetup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LobbySetup value)  $default,){
final _that = this;
switch (_that) {
case _LobbySetup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LobbySetup value)?  $default,){
final _that = this;
switch (_that) {
case _LobbySetup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameConfig config,  String townName,  List<SeatCasting> seats,  Difficulty difficulty,  Scene scene,  int humanSeat,  String humanName,  FpPersona? humanPersona,  bool grudgeMode,  bool porchMemories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LobbySetup() when $default != null:
return $default(_that.config,_that.townName,_that.seats,_that.difficulty,_that.scene,_that.humanSeat,_that.humanName,_that.humanPersona,_that.grudgeMode,_that.porchMemories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameConfig config,  String townName,  List<SeatCasting> seats,  Difficulty difficulty,  Scene scene,  int humanSeat,  String humanName,  FpPersona? humanPersona,  bool grudgeMode,  bool porchMemories)  $default,) {final _that = this;
switch (_that) {
case _LobbySetup():
return $default(_that.config,_that.townName,_that.seats,_that.difficulty,_that.scene,_that.humanSeat,_that.humanName,_that.humanPersona,_that.grudgeMode,_that.porchMemories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameConfig config,  String townName,  List<SeatCasting> seats,  Difficulty difficulty,  Scene scene,  int humanSeat,  String humanName,  FpPersona? humanPersona,  bool grudgeMode,  bool porchMemories)?  $default,) {final _that = this;
switch (_that) {
case _LobbySetup() when $default != null:
return $default(_that.config,_that.townName,_that.seats,_that.difficulty,_that.scene,_that.humanSeat,_that.humanName,_that.humanPersona,_that.grudgeMode,_that.porchMemories);case _:
  return null;

}
}

}

/// @nodoc


class _LobbySetup extends LobbySetup {
  const _LobbySetup({required this.config, required this.townName, required final  List<SeatCasting> seats, this.difficulty = Difficulty.standard, this.scene = const BuiltInScene(BuiltInSceneId.midnightStudy), this.humanSeat = 0, this.humanName = '', this.humanPersona, this.grudgeMode = true, this.porchMemories = true}): _seats = seats,super._();
  

@override final  GameConfig config;
@override final  String townName;
 final  List<SeatCasting> _seats;
@override List<SeatCasting> get seats {
  if (_seats is EqualUnmodifiableListView) return _seats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seats);
}

@override@JsonKey() final  Difficulty difficulty;
@override@JsonKey() final  Scene scene;
@override@JsonKey() final  int humanSeat;
@override@JsonKey() final  String humanName;
@override final  FpPersona? humanPersona;
@override@JsonKey() final  bool grudgeMode;
/// Write multi-card game memories for Front Porch AI (pending JSON).
@override@JsonKey() final  bool porchMemories;

/// Create a copy of LobbySetup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbySetupCopyWith<_LobbySetup> get copyWith => __$LobbySetupCopyWithImpl<_LobbySetup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LobbySetup&&(identical(other.config, config) || other.config == config)&&(identical(other.townName, townName) || other.townName == townName)&&const DeepCollectionEquality().equals(other._seats, _seats)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.scene, scene) || other.scene == scene)&&(identical(other.humanSeat, humanSeat) || other.humanSeat == humanSeat)&&(identical(other.humanName, humanName) || other.humanName == humanName)&&(identical(other.humanPersona, humanPersona) || other.humanPersona == humanPersona)&&(identical(other.grudgeMode, grudgeMode) || other.grudgeMode == grudgeMode)&&(identical(other.porchMemories, porchMemories) || other.porchMemories == porchMemories));
}


@override
int get hashCode => Object.hash(runtimeType,config,townName,const DeepCollectionEquality().hash(_seats),difficulty,scene,humanSeat,humanName,humanPersona,grudgeMode,porchMemories);

@override
String toString() {
  return 'LobbySetup(config: $config, townName: $townName, seats: $seats, difficulty: $difficulty, scene: $scene, humanSeat: $humanSeat, humanName: $humanName, humanPersona: $humanPersona, grudgeMode: $grudgeMode, porchMemories: $porchMemories)';
}


}

/// @nodoc
abstract mixin class _$LobbySetupCopyWith<$Res> implements $LobbySetupCopyWith<$Res> {
  factory _$LobbySetupCopyWith(_LobbySetup value, $Res Function(_LobbySetup) _then) = __$LobbySetupCopyWithImpl;
@override @useResult
$Res call({
 GameConfig config, String townName, List<SeatCasting> seats, Difficulty difficulty, Scene scene, int humanSeat, String humanName, FpPersona? humanPersona, bool grudgeMode, bool porchMemories
});




}
/// @nodoc
class __$LobbySetupCopyWithImpl<$Res>
    implements _$LobbySetupCopyWith<$Res> {
  __$LobbySetupCopyWithImpl(this._self, this._then);

  final _LobbySetup _self;
  final $Res Function(_LobbySetup) _then;

/// Create a copy of LobbySetup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? config = null,Object? townName = null,Object? seats = null,Object? difficulty = null,Object? scene = null,Object? humanSeat = null,Object? humanName = null,Object? humanPersona = freezed,Object? grudgeMode = null,Object? porchMemories = null,}) {
  return _then(_LobbySetup(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,townName: null == townName ? _self.townName : townName // ignore: cast_nullable_to_non_nullable
as String,seats: null == seats ? _self._seats : seats // ignore: cast_nullable_to_non_nullable
as List<SeatCasting>,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty,scene: null == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as Scene,humanSeat: null == humanSeat ? _self.humanSeat : humanSeat // ignore: cast_nullable_to_non_nullable
as int,humanName: null == humanName ? _self.humanName : humanName // ignore: cast_nullable_to_non_nullable
as String,humanPersona: freezed == humanPersona ? _self.humanPersona : humanPersona // ignore: cast_nullable_to_non_nullable
as FpPersona?,grudgeMode: null == grudgeMode ? _self.grudgeMode : grudgeMode // ignore: cast_nullable_to_non_nullable
as bool,porchMemories: null == porchMemories ? _self.porchMemories : porchMemories // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
