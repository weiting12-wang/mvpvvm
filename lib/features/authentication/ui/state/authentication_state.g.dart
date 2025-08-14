// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthenticationStateImpl _$$AuthenticationStateImplFromJson(
        Map<String, dynamic> json) =>
    _$AuthenticationStateImpl(
      authResponse:
          _authResponseFromJson(json['authResponse'] as Map<String, dynamic>?),
      isRegisterSuccessfully: json['isRegisterSuccessfully'] as bool? ?? false,
      isSignInSuccessfully: json['isSignInSuccessfully'] as bool? ?? false,
      isEC2Verifying: json['isEC2Verifying'] as bool? ?? false,
      isEC2Verified: json['isEC2Verified'] as bool? ?? false,
      ec2Status: json['ec2Status'] as String?,
      profileComplete: json['profileComplete'] as bool? ?? false,
      ec2ErrorMessage: json['ec2ErrorMessage'] as String?,
    );

Map<String, dynamic> _$$AuthenticationStateImplToJson(
        _$AuthenticationStateImpl instance) =>
    <String, dynamic>{
      'authResponse': _authResponseToJson(instance.authResponse),
      'isRegisterSuccessfully': instance.isRegisterSuccessfully,
      'isSignInSuccessfully': instance.isSignInSuccessfully,
      'isEC2Verifying': instance.isEC2Verifying,
      'isEC2Verified': instance.isEC2Verified,
      'ec2Status': instance.ec2Status,
      'profileComplete': instance.profileComplete,
      'ec2ErrorMessage': instance.ec2ErrorMessage,
    };
