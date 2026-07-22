// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateState implements DiagnosticableTreeMixin {

 UpdatePhase get phase; ReleaseInfo? get latest; double get progress; String? get error; DateTime? get checkedAt; bool get autoCheck;
/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateStateCopyWith<UpdateState> get copyWith => _$UpdateStateCopyWithImpl<UpdateState>(this as UpdateState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UpdateState'))
    ..add(DiagnosticsProperty('phase', phase))..add(DiagnosticsProperty('latest', latest))..add(DiagnosticsProperty('progress', progress))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('checkedAt', checkedAt))..add(DiagnosticsProperty('autoCheck', autoCheck));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.error, error) || other.error == error)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.autoCheck, autoCheck) || other.autoCheck == autoCheck));
}


@override
int get hashCode => Object.hash(runtimeType,phase,latest,progress,error,checkedAt,autoCheck);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UpdateState(phase: $phase, latest: $latest, progress: $progress, error: $error, checkedAt: $checkedAt, autoCheck: $autoCheck)';
}


}

/// @nodoc
abstract mixin class $UpdateStateCopyWith<$Res>  {
  factory $UpdateStateCopyWith(UpdateState value, $Res Function(UpdateState) _then) = _$UpdateStateCopyWithImpl;
@useResult
$Res call({
 UpdatePhase phase, ReleaseInfo? latest, double progress, String? error, DateTime? checkedAt, bool autoCheck
});




}
/// @nodoc
class _$UpdateStateCopyWithImpl<$Res>
    implements $UpdateStateCopyWith<$Res> {
  _$UpdateStateCopyWithImpl(this._self, this._then);

  final UpdateState _self;
  final $Res Function(UpdateState) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? latest = freezed,Object? progress = null,Object? error = freezed,Object? checkedAt = freezed,Object? autoCheck = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as UpdatePhase,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as ReleaseInfo?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,autoCheck: null == autoCheck ? _self.autoCheck : autoCheck // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateState].
extension UpdateStatePatterns on UpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateState value)  $default,){
final _that = this;
switch (_that) {
case _UpdateState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateState value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UpdatePhase phase,  ReleaseInfo? latest,  double progress,  String? error,  DateTime? checkedAt,  bool autoCheck)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateState() when $default != null:
return $default(_that.phase,_that.latest,_that.progress,_that.error,_that.checkedAt,_that.autoCheck);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UpdatePhase phase,  ReleaseInfo? latest,  double progress,  String? error,  DateTime? checkedAt,  bool autoCheck)  $default,) {final _that = this;
switch (_that) {
case _UpdateState():
return $default(_that.phase,_that.latest,_that.progress,_that.error,_that.checkedAt,_that.autoCheck);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UpdatePhase phase,  ReleaseInfo? latest,  double progress,  String? error,  DateTime? checkedAt,  bool autoCheck)?  $default,) {final _that = this;
switch (_that) {
case _UpdateState() when $default != null:
return $default(_that.phase,_that.latest,_that.progress,_that.error,_that.checkedAt,_that.autoCheck);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateState with DiagnosticableTreeMixin implements UpdateState {
  const _UpdateState({this.phase = UpdatePhase.idle, this.latest, this.progress = 0.0, this.error, this.checkedAt, this.autoCheck = true});
  

@override@JsonKey() final  UpdatePhase phase;
@override final  ReleaseInfo? latest;
@override@JsonKey() final  double progress;
@override final  String? error;
@override final  DateTime? checkedAt;
@override@JsonKey() final  bool autoCheck;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateStateCopyWith<_UpdateState> get copyWith => __$UpdateStateCopyWithImpl<_UpdateState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UpdateState'))
    ..add(DiagnosticsProperty('phase', phase))..add(DiagnosticsProperty('latest', latest))..add(DiagnosticsProperty('progress', progress))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('checkedAt', checkedAt))..add(DiagnosticsProperty('autoCheck', autoCheck));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.error, error) || other.error == error)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.autoCheck, autoCheck) || other.autoCheck == autoCheck));
}


@override
int get hashCode => Object.hash(runtimeType,phase,latest,progress,error,checkedAt,autoCheck);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UpdateState(phase: $phase, latest: $latest, progress: $progress, error: $error, checkedAt: $checkedAt, autoCheck: $autoCheck)';
}


}

/// @nodoc
abstract mixin class _$UpdateStateCopyWith<$Res> implements $UpdateStateCopyWith<$Res> {
  factory _$UpdateStateCopyWith(_UpdateState value, $Res Function(_UpdateState) _then) = __$UpdateStateCopyWithImpl;
@override @useResult
$Res call({
 UpdatePhase phase, ReleaseInfo? latest, double progress, String? error, DateTime? checkedAt, bool autoCheck
});




}
/// @nodoc
class __$UpdateStateCopyWithImpl<$Res>
    implements _$UpdateStateCopyWith<$Res> {
  __$UpdateStateCopyWithImpl(this._self, this._then);

  final _UpdateState _self;
  final $Res Function(_UpdateState) _then;

/// Create a copy of UpdateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? latest = freezed,Object? progress = null,Object? error = freezed,Object? checkedAt = freezed,Object? autoCheck = null,}) {
  return _then(_UpdateState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as UpdatePhase,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as ReleaseInfo?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,autoCheck: null == autoCheck ? _self.autoCheck : autoCheck // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
