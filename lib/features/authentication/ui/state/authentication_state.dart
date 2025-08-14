import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'authentication_state.freezed.dart';

part 'authentication_state.g.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState({
    @JsonKey(toJson: _authResponseToJson, fromJson: _authResponseFromJson) AuthResponse? authResponse,
    @Default(false) bool isRegisterSuccessfully,
    @Default(false) bool isSignInSuccessfully,
        // 🆕 新增 EC2 相關狀態
    @Default(false) bool isEC2Verifying,
    @Default(false) bool isEC2Verified,
    String? ec2Status, // 'new_user', 'existing_user', 'token_invalid'
    @Default(false) bool profileComplete,
    String? ec2ErrorMessage,
  }) = _AuthenticationState;

  factory AuthenticationState.fromJson(Map<String, Object?> json) =>
      _$AuthenticationStateFromJson(json);
}

AuthResponse? _authResponseFromJson(Map<String, dynamic>? json) {
  return json == null ? null : AuthResponse.fromJson(json);
}

Map<String, dynamic>? _authResponseToJson(AuthResponse? instance) {
  if (instance == null) return null;
  return {
    'user': instance.user?.toJson(),
    'session': instance.session?.toJson(),
  };
}
