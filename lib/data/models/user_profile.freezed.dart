// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'email') String get email;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'grade_level') String? get gradeLevel;@JsonKey(name: 'active_subjects') List<String> get activeSubjects;// Agentic feature: RL Strategy Policy reads this JSONB to personalize pathing.
@JsonKey(name: 'learning_preferences') Map<String, dynamic> get learningPreferences;// Agentic feature: enables gentle intervention branch when learner is overloaded.
@JsonKey(name: 'recovery_mode_enabled') bool get recoveryModeEnabled;@JsonKey(name: 'consent_behavioral') bool get consentBehavioral;@JsonKey(name: 'consent_analytics') bool get consentAnalytics;@JsonKey(name: 'subscription_tier') String get subscriptionTier;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'last_active') DateTime? get lastActive;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gradeLevel, gradeLevel) || other.gradeLevel == gradeLevel)&&const DeepCollectionEquality().equals(other.activeSubjects, activeSubjects)&&const DeepCollectionEquality().equals(other.learningPreferences, learningPreferences)&&(identical(other.recoveryModeEnabled, recoveryModeEnabled) || other.recoveryModeEnabled == recoveryModeEnabled)&&(identical(other.consentBehavioral, consentBehavioral) || other.consentBehavioral == consentBehavioral)&&(identical(other.consentAnalytics, consentAnalytics) || other.consentAnalytics == consentAnalytics)&&(identical(other.subscriptionTier, subscriptionTier) || other.subscriptionTier == subscriptionTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,avatarUrl,gradeLevel,const DeepCollectionEquality().hash(activeSubjects),const DeepCollectionEquality().hash(learningPreferences),recoveryModeEnabled,consentBehavioral,consentAnalytics,subscriptionTier,createdAt,updatedAt,lastActive);

@override
String toString() {
  return 'UserProfile(id: $id, fullName: $fullName, email: $email, avatarUrl: $avatarUrl, gradeLevel: $gradeLevel, activeSubjects: $activeSubjects, learningPreferences: $learningPreferences, recoveryModeEnabled: $recoveryModeEnabled, consentBehavioral: $consentBehavioral, consentAnalytics: $consentAnalytics, subscriptionTier: $subscriptionTier, createdAt: $createdAt, updatedAt: $updatedAt, lastActive: $lastActive)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'email') String email,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'grade_level') String? gradeLevel,@JsonKey(name: 'active_subjects') List<String> activeSubjects,@JsonKey(name: 'learning_preferences') Map<String, dynamic> learningPreferences,@JsonKey(name: 'recovery_mode_enabled') bool recoveryModeEnabled,@JsonKey(name: 'consent_behavioral') bool consentBehavioral,@JsonKey(name: 'consent_analytics') bool consentAnalytics,@JsonKey(name: 'subscription_tier') String subscriptionTier,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'last_active') DateTime? lastActive
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? avatarUrl = freezed,Object? gradeLevel = freezed,Object? activeSubjects = null,Object? learningPreferences = null,Object? recoveryModeEnabled = null,Object? consentBehavioral = null,Object? consentAnalytics = null,Object? subscriptionTier = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? lastActive = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,gradeLevel: freezed == gradeLevel ? _self.gradeLevel : gradeLevel // ignore: cast_nullable_to_non_nullable
as String?,activeSubjects: null == activeSubjects ? _self.activeSubjects : activeSubjects // ignore: cast_nullable_to_non_nullable
as List<String>,learningPreferences: null == learningPreferences ? _self.learningPreferences : learningPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,recoveryModeEnabled: null == recoveryModeEnabled ? _self.recoveryModeEnabled : recoveryModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,consentBehavioral: null == consentBehavioral ? _self.consentBehavioral : consentBehavioral // ignore: cast_nullable_to_non_nullable
as bool,consentAnalytics: null == consentAnalytics ? _self.consentAnalytics : consentAnalytics // ignore: cast_nullable_to_non_nullable
as bool,subscriptionTier: null == subscriptionTier ? _self.subscriptionTier : subscriptionTier // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActive: freezed == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'grade_level')  String? gradeLevel, @JsonKey(name: 'active_subjects')  List<String> activeSubjects, @JsonKey(name: 'learning_preferences')  Map<String, dynamic> learningPreferences, @JsonKey(name: 'recovery_mode_enabled')  bool recoveryModeEnabled, @JsonKey(name: 'consent_behavioral')  bool consentBehavioral, @JsonKey(name: 'consent_analytics')  bool consentAnalytics, @JsonKey(name: 'subscription_tier')  String subscriptionTier, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active')  DateTime? lastActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl,_that.gradeLevel,_that.activeSubjects,_that.learningPreferences,_that.recoveryModeEnabled,_that.consentBehavioral,_that.consentAnalytics,_that.subscriptionTier,_that.createdAt,_that.updatedAt,_that.lastActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'grade_level')  String? gradeLevel, @JsonKey(name: 'active_subjects')  List<String> activeSubjects, @JsonKey(name: 'learning_preferences')  Map<String, dynamic> learningPreferences, @JsonKey(name: 'recovery_mode_enabled')  bool recoveryModeEnabled, @JsonKey(name: 'consent_behavioral')  bool consentBehavioral, @JsonKey(name: 'consent_analytics')  bool consentAnalytics, @JsonKey(name: 'subscription_tier')  String subscriptionTier, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active')  DateTime? lastActive)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl,_that.gradeLevel,_that.activeSubjects,_that.learningPreferences,_that.recoveryModeEnabled,_that.consentBehavioral,_that.consentAnalytics,_that.subscriptionTier,_that.createdAt,_that.updatedAt,_that.lastActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'grade_level')  String? gradeLevel, @JsonKey(name: 'active_subjects')  List<String> activeSubjects, @JsonKey(name: 'learning_preferences')  Map<String, dynamic> learningPreferences, @JsonKey(name: 'recovery_mode_enabled')  bool recoveryModeEnabled, @JsonKey(name: 'consent_behavioral')  bool consentBehavioral, @JsonKey(name: 'consent_analytics')  bool consentAnalytics, @JsonKey(name: 'subscription_tier')  String subscriptionTier, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active')  DateTime? lastActive)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl,_that.gradeLevel,_that.activeSubjects,_that.learningPreferences,_that.recoveryModeEnabled,_that.consentBehavioral,_that.consentAnalytics,_that.subscriptionTier,_that.createdAt,_that.updatedAt,_that.lastActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile extends UserProfile {
  const _UserProfile({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'full_name') this.fullName = '', @JsonKey(name: 'email') this.email = '', @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'grade_level') this.gradeLevel, @JsonKey(name: 'active_subjects') final  List<String> activeSubjects = const <String>[], @JsonKey(name: 'learning_preferences') final  Map<String, dynamic> learningPreferences = const <String, dynamic>{}, @JsonKey(name: 'recovery_mode_enabled') this.recoveryModeEnabled = false, @JsonKey(name: 'consent_behavioral') this.consentBehavioral = false, @JsonKey(name: 'consent_analytics') this.consentAnalytics = false, @JsonKey(name: 'subscription_tier') this.subscriptionTier = 'free', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'last_active') this.lastActive}): _activeSubjects = activeSubjects,_learningPreferences = learningPreferences,super._();
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'email') final  String email;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'grade_level') final  String? gradeLevel;
 final  List<String> _activeSubjects;
@override@JsonKey(name: 'active_subjects') List<String> get activeSubjects {
  if (_activeSubjects is EqualUnmodifiableListView) return _activeSubjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeSubjects);
}

// Agentic feature: RL Strategy Policy reads this JSONB to personalize pathing.
 final  Map<String, dynamic> _learningPreferences;
// Agentic feature: RL Strategy Policy reads this JSONB to personalize pathing.
@override@JsonKey(name: 'learning_preferences') Map<String, dynamic> get learningPreferences {
  if (_learningPreferences is EqualUnmodifiableMapView) return _learningPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_learningPreferences);
}

// Agentic feature: enables gentle intervention branch when learner is overloaded.
@override@JsonKey(name: 'recovery_mode_enabled') final  bool recoveryModeEnabled;
@override@JsonKey(name: 'consent_behavioral') final  bool consentBehavioral;
@override@JsonKey(name: 'consent_analytics') final  bool consentAnalytics;
@override@JsonKey(name: 'subscription_tier') final  String subscriptionTier;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'last_active') final  DateTime? lastActive;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gradeLevel, gradeLevel) || other.gradeLevel == gradeLevel)&&const DeepCollectionEquality().equals(other._activeSubjects, _activeSubjects)&&const DeepCollectionEquality().equals(other._learningPreferences, _learningPreferences)&&(identical(other.recoveryModeEnabled, recoveryModeEnabled) || other.recoveryModeEnabled == recoveryModeEnabled)&&(identical(other.consentBehavioral, consentBehavioral) || other.consentBehavioral == consentBehavioral)&&(identical(other.consentAnalytics, consentAnalytics) || other.consentAnalytics == consentAnalytics)&&(identical(other.subscriptionTier, subscriptionTier) || other.subscriptionTier == subscriptionTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastActive, lastActive) || other.lastActive == lastActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,avatarUrl,gradeLevel,const DeepCollectionEquality().hash(_activeSubjects),const DeepCollectionEquality().hash(_learningPreferences),recoveryModeEnabled,consentBehavioral,consentAnalytics,subscriptionTier,createdAt,updatedAt,lastActive);

@override
String toString() {
  return 'UserProfile(id: $id, fullName: $fullName, email: $email, avatarUrl: $avatarUrl, gradeLevel: $gradeLevel, activeSubjects: $activeSubjects, learningPreferences: $learningPreferences, recoveryModeEnabled: $recoveryModeEnabled, consentBehavioral: $consentBehavioral, consentAnalytics: $consentAnalytics, subscriptionTier: $subscriptionTier, createdAt: $createdAt, updatedAt: $updatedAt, lastActive: $lastActive)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'email') String email,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'grade_level') String? gradeLevel,@JsonKey(name: 'active_subjects') List<String> activeSubjects,@JsonKey(name: 'learning_preferences') Map<String, dynamic> learningPreferences,@JsonKey(name: 'recovery_mode_enabled') bool recoveryModeEnabled,@JsonKey(name: 'consent_behavioral') bool consentBehavioral,@JsonKey(name: 'consent_analytics') bool consentAnalytics,@JsonKey(name: 'subscription_tier') String subscriptionTier,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'last_active') DateTime? lastActive
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? avatarUrl = freezed,Object? gradeLevel = freezed,Object? activeSubjects = null,Object? learningPreferences = null,Object? recoveryModeEnabled = null,Object? consentBehavioral = null,Object? consentAnalytics = null,Object? subscriptionTier = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? lastActive = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,gradeLevel: freezed == gradeLevel ? _self.gradeLevel : gradeLevel // ignore: cast_nullable_to_non_nullable
as String?,activeSubjects: null == activeSubjects ? _self._activeSubjects : activeSubjects // ignore: cast_nullable_to_non_nullable
as List<String>,learningPreferences: null == learningPreferences ? _self._learningPreferences : learningPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,recoveryModeEnabled: null == recoveryModeEnabled ? _self.recoveryModeEnabled : recoveryModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,consentBehavioral: null == consentBehavioral ? _self.consentBehavioral : consentBehavioral // ignore: cast_nullable_to_non_nullable
as bool,consentAnalytics: null == consentAnalytics ? _self.consentAnalytics : consentAnalytics // ignore: cast_nullable_to_non_nullable
as bool,subscriptionTier: null == subscriptionTier ? _self.subscriptionTier : subscriptionTier // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActive: freezed == lastActive ? _self.lastActive : lastActive // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
