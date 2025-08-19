import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/device_info_service.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/environment/env.dart';
import '/main.dart';
import 'package:dio/dio.dart'; // 
part 'authentication_repository.g.dart';


@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

// 🆕 新增 EC2 登入結果模型
class EC2SignInResult {
  final String status; // 'success', 'invalid_password', 'user_not_found', 'account_disabled', etc.
  final String? message;
  final String? token;
  final bool profileComplete;
  final Map<String, dynamic>? profileData;
  
  EC2SignInResult({
    required this.status,
    this.message,
    this.token,
    this.profileComplete = false,
    this.profileData,
  });
  
  factory EC2SignInResult.fromJson(Map<String, dynamic> json) {
    return EC2SignInResult(
      status: json['status'] ?? 'error',
      message: json['message'],
      token: json['token'],
      profileComplete: json['profile_complete'] ?? false,
      profileData: json['profile_data'],
    );
  }
  
  // 🆕 轉換為 Map 供 ViewModel 使用
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'message': message,
      'token': token,
      'profile_complete': profileComplete,
      'profile_data': profileData,
    };
  }
}


class AuthenticationRepository {
  const AuthenticationRepository();
  // 🆕 新增 EC2 帳密登入方法
  Future<Map<String, dynamic>> signInWithEC2Password({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-ec2-server.com/api/auth/signin'), // 🔴 替換為你的 EC2 URL
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final result = EC2SignInResult.fromJson(responseData);
        return result.toMap();
      } else {
        // 🆕 根據 HTTP 狀態碼處理不同錯誤
        switch (response.statusCode) {
          case 401:
            if (responseData['code'] == 'INVALID_PASSWORD') {
              throw Exception('invalid_password');
            } else if (responseData['code'] == 'USER_NOT_FOUND') {
              throw Exception('user_not_found');
            }
            break;
          case 403:
            throw Exception('account_disabled');
          case 429:
            throw Exception('too_many_attempts');
          default:
            throw Exception('server_error');
        }
        
        throw Exception('登錄失敗，稍後再試');
      }
    } catch (e) {
      if (e.toString().contains('invalid_password') ||
          e.toString().contains('user_not_found') ||
          e.toString().contains('account_disabled')) {
        rethrow; // 保持原有錯誤訊息
      }
      throw Exception('網路連線錯誤，請檢查網路設定');
    }
  }

  // 🆕 新增同步密碼到 EC2 方法
  Future<void> syncPasswordToEC2({
    required String newPassword,
    required String supabaseToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-ec2-server.com/api/auth/sync-password'), // 🔴 替換為你的 EC2 URL
        headers: {
          'Authorization': 'Bearer $supabaseToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'new_password': newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'EC2 密碼同步失敗');
      }
    } catch (e) {
      throw Exception('密碼同步失敗: ${e.toString()}');
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    // TODO: fake data
    //return;

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        //移除 emailRedirectTo，否則會觸發 magic link emailRedirectTo: Constants.supabaseLoginCallback,
      );
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }
  Future<void> sendOtpEmail(String email) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: '', //
      );
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }
// 🆕 新增 EC2 驗證方法 register 使用
  Future<Map<String, dynamic>> verifyWithEC2(String supabaseToken) async {
    try {

      print('${Constants.tag} [verifyWithEC2] 🚀 開始呼叫 EC2 API');
      print('${Constants.tag} [verifyWithEC2] 🔗 URL: http://ec2-44-221-228-28.compute-1.amazonaws.com/user/register');
      print('${Constants.tag} [verifyWithEC2] 🔑 Token: ${supabaseToken.substring(0, 20)}...');
          // 🆕 從 SharedPreferences 取得註冊時的資訊
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('temp_registration_email') ?? '';
      final password = prefs.getString('temp_registration_password') ?? '';
      final uuid = DeviceInfoService.instance.deviceUuid ?? '';
      
      print('${Constants.tag} [verifyWithEC2] 📧 Email: $email');
      print('${Constants.tag} [verifyWithEC2] 🔒 Password: ${password.isNotEmpty ? '***有密碼***' : '***無密碼***'}');
      print('${Constants.tag} [verifyWithEC2] 📱 UUID: $uuid');

      final requestBody = {
        'supabase_token': supabaseToken,
        'email': email,
        'password': password,
        'uuid': uuid,
      };

      final response = await http.post(
        //Uri.parse('http://ec2-44-221-228-28.compute-1.amazonaws.com/user/register'),
        Uri.parse('http://httpbin.org/post'),
        headers: {
          'Authorization': 'Bearer $supabaseToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
          // 🆕 加入這些 print
      print('${Constants.tag} [verifyWithEC2] 📊 HTTP 狀態碼: ${response.statusCode}');
      print('${Constants.tag} [verifyWithEC2] 📄 回應內容: ${response.body}');
      if (response.statusCode == 200) {
        //return jsonDecode(response.body); //aws
              // ✅ 直接返回正確格式，不解析 httpbin 回應
        return {
          'status': 'new_user',
          'profile_complete': false,
        };
      } else {
        throw Exception('EC2 驗證失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('EC2 驗證錯誤: $e');
    }
  }


  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
    String? password, // 
  }) async {
    try {
      final result = await supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email, // ✅ 使用 6 碼 OTP 驗證
      );

      // ✅ 根據 isRegister 呼叫 EC2 註冊
      if (isRegister) {
        if (password == null) {
          throw Exception('Password is required for registration');
        }
      }

      return result;
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<void> registerToEc2({
    required String email,
    required String password,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('http://your-ec2-api/register'), // 👈 請換成你自己的 API
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('EC2 註冊失敗：${response.body}');
    }
  }




  Future<AuthResponse> signInWithGoogle() async {
    // TODO: fake data
    return AuthResponse(
      user: User(
        id: '',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
        email: 'henry@google.com',
      ),
    );

    try {
      const List<String> scopes = <String>[
        Constants.googleEmailScope,
        Constants.googleUserInfoScope,
      ];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Env.googleClientId,
        serverClientId: Env.googleServerClientId,
        scopes: scopes,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('access_token_not_found'.tr());
      }

      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return result;
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<AuthResponse> signInWithApple() async {
    // TODO: fake data
    return AuthResponse(
      user: User(
        id: '',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
        email: 'henry@apple.com',
      ),
    );

    try {
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return result;
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<void> signOut() async {
    // TODO: fake data
    return;

    try {
      await supabase.auth.signOut();
      setIsLogin(false);
      Purchases.logOut();
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isLoginKey) ?? false;
  }

  Future<void> setIsLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isLoginKey, value);
  }

  Future<bool> isExistAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isExistAccountKey) ?? false;
  }

  Future<void> setIsExistAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isExistAccountKey, value);
  }
}
