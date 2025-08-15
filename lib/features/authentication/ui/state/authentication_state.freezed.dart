// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authentication_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthenticationState _$AuthenticationStateFromJson(Map<String, dynamic> json) {
  return _AuthenticationState.fromJson(json);
}

/// @nodoc
mixin _$AuthenticationState {
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  AuthResponse? get authResponse => throw _privateConstructorUsedError;
  bool get isRegisterSuccessfully => throw _privateConstructorUsedError;
  bool get isSignInSuccessfully =>
      throw _privateConstructorUsedError; // 🆕 EC2 登入相關狀態
  bool get isEC2SignInSuccessfully => throw _privateConstructorUsedError;
  bool get profileComplete => throw _privateConstructorUsedError;
  String? get ec2ErrorMessage => throw _privateConstructorUsedError;
  String? get ec2AccessToken =>
      throw _privateConstructorUsedError; // 原本的 EC2 相關狀態 (保留)
  bool get isEC2Verifying => throw _privateConstructorUsedError;
  bool get isEC2Verified => throw _privateConstructorUsedError;
  String? get ec2Status =>
      throw _privateConstructorUsedError; // 'new_user', 'existing_user', 'token_invalid'
// 🆕 忘記密碼相關狀態
  bool get isPasswordResetEmailSent => throw _privateConstructorUsedError;
  bool get isPasswordResetSuccessfully => throw _privateConstructorUsedError;
  String? get passwordResetError => throw _privateConstructorUsedError;

  /// Serializes this AuthenticationState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthenticationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthenticationStateCopyWith<AuthenticationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationStateCopyWith(
          AuthenticationState value, $Res Function(AuthenticationState) then) =
      _$AuthenticationStateCopyWithImpl<$Res, AuthenticationState>;
  @useResult
  $Res call(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      AuthResponse? authResponse,
      bool isRegisterSuccessfully,
      bool isSignInSuccessfully,
      bool isEC2SignInSuccessfully,
      bool profileComplete,
      String? ec2ErrorMessage,
      String? ec2AccessToken,
      bool isEC2Verifying,
      bool isEC2Verified,
      String? ec2Status,
      bool isPasswordResetEmailSent,
      bool isPasswordResetSuccessfully,
      String? passwordResetError});
}

/// @nodoc
class _$AuthenticationStateCopyWithImpl<$Res, $Val extends AuthenticationState>
    implements $AuthenticationStateCopyWith<$Res> {
  _$AuthenticationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthenticationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authResponse = freezed,
    Object? isRegisterSuccessfully = null,
    Object? isSignInSuccessfully = null,
    Object? isEC2SignInSuccessfully = null,
    Object? profileComplete = null,
    Object? ec2ErrorMessage = freezed,
    Object? ec2AccessToken = freezed,
    Object? isEC2Verifying = null,
    Object? isEC2Verified = null,
    Object? ec2Status = freezed,
    Object? isPasswordResetEmailSent = null,
    Object? isPasswordResetSuccessfully = null,
    Object? passwordResetError = freezed,
  }) {
    return _then(_value.copyWith(
      authResponse: freezed == authResponse
          ? _value.authResponse
          : authResponse // ignore: cast_nullable_to_non_nullable
              as AuthResponse?,
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isSignInSuccessfully: null == isSignInSuccessfully
          ? _value.isSignInSuccessfully
          : isSignInSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isEC2SignInSuccessfully: null == isEC2SignInSuccessfully
          ? _value.isEC2SignInSuccessfully
          : isEC2SignInSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      profileComplete: null == profileComplete
          ? _value.profileComplete
          : profileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      ec2ErrorMessage: freezed == ec2ErrorMessage
          ? _value.ec2ErrorMessage
          : ec2ErrorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      ec2AccessToken: freezed == ec2AccessToken
          ? _value.ec2AccessToken
          : ec2AccessToken // ignore: cast_nullable_to_non_nullable
              as String?,
      isEC2Verifying: null == isEC2Verifying
          ? _value.isEC2Verifying
          : isEC2Verifying // ignore: cast_nullable_to_non_nullable
              as bool,
      isEC2Verified: null == isEC2Verified
          ? _value.isEC2Verified
          : isEC2Verified // ignore: cast_nullable_to_non_nullable
              as bool,
      ec2Status: freezed == ec2Status
          ? _value.ec2Status
          : ec2Status // ignore: cast_nullable_to_non_nullable
              as String?,
      isPasswordResetEmailSent: null == isPasswordResetEmailSent
          ? _value.isPasswordResetEmailSent
          : isPasswordResetEmailSent // ignore: cast_nullable_to_non_nullable
              as bool,
      isPasswordResetSuccessfully: null == isPasswordResetSuccessfully
          ? _value.isPasswordResetSuccessfully
          : isPasswordResetSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordResetError: freezed == passwordResetError
          ? _value.passwordResetError
          : passwordResetError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthenticationStateImplCopyWith<$Res>
    implements $AuthenticationStateCopyWith<$Res> {
  factory _$$AuthenticationStateImplCopyWith(_$AuthenticationStateImpl value,
          $Res Function(_$AuthenticationStateImpl) then) =
      __$$AuthenticationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      AuthResponse? authResponse,
      bool isRegisterSuccessfully,
      bool isSignInSuccessfully,
      bool isEC2SignInSuccessfully,
      bool profileComplete,
      String? ec2ErrorMessage,
      String? ec2AccessToken,
      bool isEC2Verifying,
      bool isEC2Verified,
      String? ec2Status,
      bool isPasswordResetEmailSent,
      bool isPasswordResetSuccessfully,
      String? passwordResetError});
}

/// @nodoc
class __$$AuthenticationStateImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$AuthenticationStateImpl>
    implements _$$AuthenticationStateImplCopyWith<$Res> {
  __$$AuthenticationStateImplCopyWithImpl(_$AuthenticationStateImpl _value,
      $Res Function(_$AuthenticationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthenticationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authResponse = freezed,
    Object? isRegisterSuccessfully = null,
    Object? isSignInSuccessfully = null,
    Object? isEC2SignInSuccessfully = null,
    Object? profileComplete = null,
    Object? ec2ErrorMessage = freezed,
    Object? ec2AccessToken = freezed,
    Object? isEC2Verifying = null,
    Object? isEC2Verified = null,
    Object? ec2Status = freezed,
    Object? isPasswordResetEmailSent = null,
    Object? isPasswordResetSuccessfully = null,
    Object? passwordResetError = freezed,
  }) {
    return _then(_$AuthenticationStateImpl(
      authResponse: freezed == authResponse
          ? _value.authResponse
          : authResponse // ignore: cast_nullable_to_non_nullable
              as AuthResponse?,
      isRegisterSuccessfully: null == isRegisterSuccessfully
          ? _value.isRegisterSuccessfully
          : isRegisterSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isSignInSuccessfully: null == isSignInSuccessfully
          ? _value.isSignInSuccessfully
          : isSignInSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      isEC2SignInSuccessfully: null == isEC2SignInSuccessfully
          ? _value.isEC2SignInSuccessfully
          : isEC2SignInSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      profileComplete: null == profileComplete
          ? _value.profileComplete
          : profileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      ec2ErrorMessage: freezed == ec2ErrorMessage
          ? _value.ec2ErrorMessage
          : ec2ErrorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      ec2AccessToken: freezed == ec2AccessToken
          ? _value.ec2AccessToken
          : ec2AccessToken // ignore: cast_nullable_to_non_nullable
              as String?,
      isEC2Verifying: null == isEC2Verifying
          ? _value.isEC2Verifying
          : isEC2Verifying // ignore: cast_nullable_to_non_nullable
              as bool,
      isEC2Verified: null == isEC2Verified
          ? _value.isEC2Verified
          : isEC2Verified // ignore: cast_nullable_to_non_nullable
              as bool,
      ec2Status: freezed == ec2Status
          ? _value.ec2Status
          : ec2Status // ignore: cast_nullable_to_non_nullable
              as String?,
      isPasswordResetEmailSent: null == isPasswordResetEmailSent
          ? _value.isPasswordResetEmailSent
          : isPasswordResetEmailSent // ignore: cast_nullable_to_non_nullable
              as bool,
      isPasswordResetSuccessfully: null == isPasswordResetSuccessfully
          ? _value.isPasswordResetSuccessfully
          : isPasswordResetSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      passwordResetError: freezed == passwordResetError
          ? _value.passwordResetError
          : passwordResetError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthenticationStateImpl implements _AuthenticationState {
  const _$AuthenticationStateImpl(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      this.authResponse,
      this.isRegisterSuccessfully = false,
      this.isSignInSuccessfully = false,
      this.isEC2SignInSuccessfully = false,
      this.profileComplete = false,
      this.ec2ErrorMessage,
      this.ec2AccessToken,
      this.isEC2Verifying = false,
      this.isEC2Verified = false,
      this.ec2Status,
      this.isPasswordResetEmailSent = false,
      this.isPasswordResetSuccessfully = false,
      this.passwordResetError});

  factory _$AuthenticationStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthenticationStateImplFromJson(json);

  @override
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  final AuthResponse? authResponse;
  @override
  @JsonKey()
  final bool isRegisterSuccessfully;
  @override
  @JsonKey()
  final bool isSignInSuccessfully;
// 🆕 EC2 登入相關狀態
  @override
  @JsonKey()
  final bool isEC2SignInSuccessfully;
  @override
  @JsonKey()
  final bool profileComplete;
  @override
  final String? ec2ErrorMessage;
  @override
  final String? ec2AccessToken;
// 原本的 EC2 相關狀態 (保留)
  @override
  @JsonKey()
  final bool isEC2Verifying;
  @override
  @JsonKey()
  final bool isEC2Verified;
  @override
  final String? ec2Status;
// 'new_user', 'existing_user', 'token_invalid'
// 🆕 忘記密碼相關狀態
  @override
  @JsonKey()
  final bool isPasswordResetEmailSent;
  @override
  @JsonKey()
  final bool isPasswordResetSuccessfully;
  @override
  final String? passwordResetError;

  @override
  String toString() {
    return 'AuthenticationState(authResponse: $authResponse, isRegisterSuccessfully: $isRegisterSuccessfully, isSignInSuccessfully: $isSignInSuccessfully, isEC2SignInSuccessfully: $isEC2SignInSuccessfully, profileComplete: $profileComplete, ec2ErrorMessage: $ec2ErrorMessage, ec2AccessToken: $ec2AccessToken, isEC2Verifying: $isEC2Verifying, isEC2Verified: $isEC2Verified, ec2Status: $ec2Status, isPasswordResetEmailSent: $isPasswordResetEmailSent, isPasswordResetSuccessfully: $isPasswordResetSuccessfully, passwordResetError: $passwordResetError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthenticationStateImpl &&
            (identical(other.authResponse, authResponse) ||
                other.authResponse == authResponse) &&
            (identical(other.isRegisterSuccessfully, isRegisterSuccessfully) ||
                other.isRegisterSuccessfully == isRegisterSuccessfully) &&
            (identical(other.isSignInSuccessfully, isSignInSuccessfully) ||
                other.isSignInSuccessfully == isSignInSuccessfully) &&
            (identical(
                    other.isEC2SignInSuccessfully, isEC2SignInSuccessfully) ||
                other.isEC2SignInSuccessfully == isEC2SignInSuccessfully) &&
            (identical(other.profileComplete, profileComplete) ||
                other.profileComplete == profileComplete) &&
            (identical(other.ec2ErrorMessage, ec2ErrorMessage) ||
                other.ec2ErrorMessage == ec2ErrorMessage) &&
            (identical(other.ec2AccessToken, ec2AccessToken) ||
                other.ec2AccessToken == ec2AccessToken) &&
            (identical(other.isEC2Verifying, isEC2Verifying) ||
                other.isEC2Verifying == isEC2Verifying) &&
            (identical(other.isEC2Verified, isEC2Verified) ||
                other.isEC2Verified == isEC2Verified) &&
            (identical(other.ec2Status, ec2Status) ||
                other.ec2Status == ec2Status) &&
            (identical(
                    other.isPasswordResetEmailSent, isPasswordResetEmailSent) ||
                other.isPasswordResetEmailSent == isPasswordResetEmailSent) &&
            (identical(other.isPasswordResetSuccessfully,
                    isPasswordResetSuccessfully) ||
                other.isPasswordResetSuccessfully ==
                    isPasswordResetSuccessfully) &&
            (identical(other.passwordResetError, passwordResetError) ||
                other.passwordResetError == passwordResetError));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      authResponse,
      isRegisterSuccessfully,
      isSignInSuccessfully,
      isEC2SignInSuccessfully,
      profileComplete,
      ec2ErrorMessage,
      ec2AccessToken,
      isEC2Verifying,
      isEC2Verified,
      ec2Status,
      isPasswordResetEmailSent,
      isPasswordResetSuccessfully,
      passwordResetError);

  /// Create a copy of AuthenticationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthenticationStateImplCopyWith<_$AuthenticationStateImpl> get copyWith =>
      __$$AuthenticationStateImplCopyWithImpl<_$AuthenticationStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthenticationStateImplToJson(
      this,
    );
  }
}

abstract class _AuthenticationState implements AuthenticationState {
  const factory _AuthenticationState(
      {@JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
      final AuthResponse? authResponse,
      final bool isRegisterSuccessfully,
      final bool isSignInSuccessfully,
      final bool isEC2SignInSuccessfully,
      final bool profileComplete,
      final String? ec2ErrorMessage,
      final String? ec2AccessToken,
      final bool isEC2Verifying,
      final bool isEC2Verified,
      final String? ec2Status,
      final bool isPasswordResetEmailSent,
      final bool isPasswordResetSuccessfully,
      final String? passwordResetError}) = _$AuthenticationStateImpl;

  factory _AuthenticationState.fromJson(Map<String, dynamic> json) =
      _$AuthenticationStateImpl.fromJson;

  @override
  @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson)
  AuthResponse? get authResponse;
  @override
  bool get isRegisterSuccessfully;
  @override
  bool get isSignInSuccessfully; // 🆕 EC2 登入相關狀態
  @override
  bool get isEC2SignInSuccessfully;
  @override
  bool get profileComplete;
  @override
  String? get ec2ErrorMessage;
  @override
  String? get ec2AccessToken; // 原本的 EC2 相關狀態 (保留)
  @override
  bool get isEC2Verifying;
  @override
  bool get isEC2Verified;
  @override
  String? get ec2Status; // 'new_user', 'existing_user', 'token_invalid'
// 🆕 忘記密碼相關狀態
  @override
  bool get isPasswordResetEmailSent;
  @override
  bool get isPasswordResetSuccessfully;
  @override
  String? get passwordResetError;

  /// Create a copy of AuthenticationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthenticationStateImplCopyWith<_$AuthenticationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
