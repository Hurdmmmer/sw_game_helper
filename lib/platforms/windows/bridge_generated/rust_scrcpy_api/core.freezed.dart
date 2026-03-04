// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'core.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionEvent()';
}


}

/// @nodoc
class $SessionEventCopyWith<$Res>  {
$SessionEventCopyWith(SessionEvent _, $Res Function(SessionEvent) __);
}


/// Adds pattern-matching-related methods to [SessionEvent].
extension SessionEventPatterns on SessionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionEvent_Starting value)?  starting,TResult Function( SessionEvent_Running value)?  running,TResult Function( SessionEvent_Reconnecting value)?  reconnecting,TResult Function( SessionEvent_Stopped value)?  stopped,TResult Function( SessionEvent_Error value)?  error,TResult Function( SessionEvent_OrientationChanged value)?  orientationChanged,TResult Function( SessionEvent_ResolutionChanged value)?  resolutionChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionEvent_Starting() when starting != null:
return starting(_that);case SessionEvent_Running() when running != null:
return running(_that);case SessionEvent_Reconnecting() when reconnecting != null:
return reconnecting(_that);case SessionEvent_Stopped() when stopped != null:
return stopped(_that);case SessionEvent_Error() when error != null:
return error(_that);case SessionEvent_OrientationChanged() when orientationChanged != null:
return orientationChanged(_that);case SessionEvent_ResolutionChanged() when resolutionChanged != null:
return resolutionChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionEvent_Starting value)  starting,required TResult Function( SessionEvent_Running value)  running,required TResult Function( SessionEvent_Reconnecting value)  reconnecting,required TResult Function( SessionEvent_Stopped value)  stopped,required TResult Function( SessionEvent_Error value)  error,required TResult Function( SessionEvent_OrientationChanged value)  orientationChanged,required TResult Function( SessionEvent_ResolutionChanged value)  resolutionChanged,}){
final _that = this;
switch (_that) {
case SessionEvent_Starting():
return starting(_that);case SessionEvent_Running():
return running(_that);case SessionEvent_Reconnecting():
return reconnecting(_that);case SessionEvent_Stopped():
return stopped(_that);case SessionEvent_Error():
return error(_that);case SessionEvent_OrientationChanged():
return orientationChanged(_that);case SessionEvent_ResolutionChanged():
return resolutionChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionEvent_Starting value)?  starting,TResult? Function( SessionEvent_Running value)?  running,TResult? Function( SessionEvent_Reconnecting value)?  reconnecting,TResult? Function( SessionEvent_Stopped value)?  stopped,TResult? Function( SessionEvent_Error value)?  error,TResult? Function( SessionEvent_OrientationChanged value)?  orientationChanged,TResult? Function( SessionEvent_ResolutionChanged value)?  resolutionChanged,}){
final _that = this;
switch (_that) {
case SessionEvent_Starting() when starting != null:
return starting(_that);case SessionEvent_Running() when running != null:
return running(_that);case SessionEvent_Reconnecting() when reconnecting != null:
return reconnecting(_that);case SessionEvent_Stopped() when stopped != null:
return stopped(_that);case SessionEvent_Error() when error != null:
return error(_that);case SessionEvent_OrientationChanged() when orientationChanged != null:
return orientationChanged(_that);case SessionEvent_ResolutionChanged() when resolutionChanged != null:
return resolutionChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  starting,TResult Function()?  running,TResult Function()?  reconnecting,TResult Function()?  stopped,TResult Function( ErrorCode code,  String message)?  error,TResult Function( OrientationMode mode,  OrientationChangeSource source)?  orientationChanged,TResult Function( int width,  int height,  PlatformInt64 newHandle,  BigInt generation)?  resolutionChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionEvent_Starting() when starting != null:
return starting();case SessionEvent_Running() when running != null:
return running();case SessionEvent_Reconnecting() when reconnecting != null:
return reconnecting();case SessionEvent_Stopped() when stopped != null:
return stopped();case SessionEvent_Error() when error != null:
return error(_that.code,_that.message);case SessionEvent_OrientationChanged() when orientationChanged != null:
return orientationChanged(_that.mode,_that.source);case SessionEvent_ResolutionChanged() when resolutionChanged != null:
return resolutionChanged(_that.width,_that.height,_that.newHandle,_that.generation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  starting,required TResult Function()  running,required TResult Function()  reconnecting,required TResult Function()  stopped,required TResult Function( ErrorCode code,  String message)  error,required TResult Function( OrientationMode mode,  OrientationChangeSource source)  orientationChanged,required TResult Function( int width,  int height,  PlatformInt64 newHandle,  BigInt generation)  resolutionChanged,}) {final _that = this;
switch (_that) {
case SessionEvent_Starting():
return starting();case SessionEvent_Running():
return running();case SessionEvent_Reconnecting():
return reconnecting();case SessionEvent_Stopped():
return stopped();case SessionEvent_Error():
return error(_that.code,_that.message);case SessionEvent_OrientationChanged():
return orientationChanged(_that.mode,_that.source);case SessionEvent_ResolutionChanged():
return resolutionChanged(_that.width,_that.height,_that.newHandle,_that.generation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  starting,TResult? Function()?  running,TResult? Function()?  reconnecting,TResult? Function()?  stopped,TResult? Function( ErrorCode code,  String message)?  error,TResult? Function( OrientationMode mode,  OrientationChangeSource source)?  orientationChanged,TResult? Function( int width,  int height,  PlatformInt64 newHandle,  BigInt generation)?  resolutionChanged,}) {final _that = this;
switch (_that) {
case SessionEvent_Starting() when starting != null:
return starting();case SessionEvent_Running() when running != null:
return running();case SessionEvent_Reconnecting() when reconnecting != null:
return reconnecting();case SessionEvent_Stopped() when stopped != null:
return stopped();case SessionEvent_Error() when error != null:
return error(_that.code,_that.message);case SessionEvent_OrientationChanged() when orientationChanged != null:
return orientationChanged(_that.mode,_that.source);case SessionEvent_ResolutionChanged() when resolutionChanged != null:
return resolutionChanged(_that.width,_that.height,_that.newHandle,_that.generation);case _:
  return null;

}
}

}

/// @nodoc


class SessionEvent_Starting extends SessionEvent {
  const SessionEvent_Starting(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_Starting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionEvent.starting()';
}


}




/// @nodoc


class SessionEvent_Running extends SessionEvent {
  const SessionEvent_Running(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_Running);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionEvent.running()';
}


}




/// @nodoc


class SessionEvent_Reconnecting extends SessionEvent {
  const SessionEvent_Reconnecting(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_Reconnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionEvent.reconnecting()';
}


}




/// @nodoc


class SessionEvent_Stopped extends SessionEvent {
  const SessionEvent_Stopped(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_Stopped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionEvent.stopped()';
}


}




/// @nodoc


class SessionEvent_Error extends SessionEvent {
  const SessionEvent_Error({required this.code, required this.message}): super._();
  

 final  ErrorCode code;
 final  String message;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionEvent_ErrorCopyWith<SessionEvent_Error> get copyWith => _$SessionEvent_ErrorCopyWithImpl<SessionEvent_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_Error&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'SessionEvent.error(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $SessionEvent_ErrorCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_ErrorCopyWith(SessionEvent_Error value, $Res Function(SessionEvent_Error) _then) = _$SessionEvent_ErrorCopyWithImpl;
@useResult
$Res call({
 ErrorCode code, String message
});




}
/// @nodoc
class _$SessionEvent_ErrorCopyWithImpl<$Res>
    implements $SessionEvent_ErrorCopyWith<$Res> {
  _$SessionEvent_ErrorCopyWithImpl(this._self, this._then);

  final SessionEvent_Error _self;
  final $Res Function(SessionEvent_Error) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(SessionEvent_Error(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as ErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SessionEvent_OrientationChanged extends SessionEvent {
  const SessionEvent_OrientationChanged({required this.mode, required this.source}): super._();
  

 final  OrientationMode mode;
 final  OrientationChangeSource source;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionEvent_OrientationChangedCopyWith<SessionEvent_OrientationChanged> get copyWith => _$SessionEvent_OrientationChangedCopyWithImpl<SessionEvent_OrientationChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_OrientationChanged&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,mode,source);

@override
String toString() {
  return 'SessionEvent.orientationChanged(mode: $mode, source: $source)';
}


}

/// @nodoc
abstract mixin class $SessionEvent_OrientationChangedCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_OrientationChangedCopyWith(SessionEvent_OrientationChanged value, $Res Function(SessionEvent_OrientationChanged) _then) = _$SessionEvent_OrientationChangedCopyWithImpl;
@useResult
$Res call({
 OrientationMode mode, OrientationChangeSource source
});




}
/// @nodoc
class _$SessionEvent_OrientationChangedCopyWithImpl<$Res>
    implements $SessionEvent_OrientationChangedCopyWith<$Res> {
  _$SessionEvent_OrientationChangedCopyWithImpl(this._self, this._then);

  final SessionEvent_OrientationChanged _self;
  final $Res Function(SessionEvent_OrientationChanged) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? source = null,}) {
  return _then(SessionEvent_OrientationChanged(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as OrientationMode,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as OrientationChangeSource,
  ));
}


}

/// @nodoc


class SessionEvent_ResolutionChanged extends SessionEvent {
  const SessionEvent_ResolutionChanged({required this.width, required this.height, required this.newHandle, required this.generation}): super._();
  

 final  int width;
 final  int height;
 final  PlatformInt64 newHandle;
 final  BigInt generation;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionEvent_ResolutionChangedCopyWith<SessionEvent_ResolutionChanged> get copyWith => _$SessionEvent_ResolutionChangedCopyWithImpl<SessionEvent_ResolutionChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent_ResolutionChanged&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.newHandle, newHandle) || other.newHandle == newHandle)&&(identical(other.generation, generation) || other.generation == generation));
}


@override
int get hashCode => Object.hash(runtimeType,width,height,newHandle,generation);

@override
String toString() {
  return 'SessionEvent.resolutionChanged(width: $width, height: $height, newHandle: $newHandle, generation: $generation)';
}


}

/// @nodoc
abstract mixin class $SessionEvent_ResolutionChangedCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_ResolutionChangedCopyWith(SessionEvent_ResolutionChanged value, $Res Function(SessionEvent_ResolutionChanged) _then) = _$SessionEvent_ResolutionChangedCopyWithImpl;
@useResult
$Res call({
 int width, int height, PlatformInt64 newHandle, BigInt generation
});




}
/// @nodoc
class _$SessionEvent_ResolutionChangedCopyWithImpl<$Res>
    implements $SessionEvent_ResolutionChangedCopyWith<$Res> {
  _$SessionEvent_ResolutionChangedCopyWithImpl(this._self, this._then);

  final SessionEvent_ResolutionChanged _self;
  final $Res Function(SessionEvent_ResolutionChanged) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,Object? newHandle = null,Object? generation = null,}) {
  return _then(SessionEvent_ResolutionChanged(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,newHandle: null == newHandle ? _self.newHandle : newHandle // ignore: cast_nullable_to_non_nullable
as PlatformInt64,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

// dart format on
