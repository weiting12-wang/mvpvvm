import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/constants/constants.dart';
import '/extensions/string_extension.dart';
import '/features/profile/ui/view_model/profile_view_model.dart';
import '../../repository/authentication_repository.dart';
import '../../ui/state/authentication_state.dart';

part 'authentication_view_model.g.dart';

@riverpod
class AuthenticationViewModel extends _$AuthenticationViewModel {
  @override
  FutureOr<AuthenticationState> build() async {
    return const AuthenticationState();
  }

  // 🆕 EC2 密碼登入
  Future<void> signInWithEC2Password({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    
    try {
      final result = await authRepo.signInWithEC2Password(
        email: email,
        password: password,
      );
      
      debugPrint('${Constants.tag} [AuthenticationViewModel.signInWithEC2Password] result: $result');
      
      // 🆕 處理 EC2 登入結果
      if (result['status'] == 'success') {
        // 登入成功，更新狀態
        state = AsyncData(AuthenticationState(
          isEC2SignInSuccessfully: true,
          profileComplete: result['profile_complete'] ?? false,
          ec2AccessToken: result['token'],
        ));
        
        // 🆕 更新本地 Profile
        ref.read(profileViewModelProvider.notifier).updateProfile(
          email: email,
          name: result['profile_data']?['name'],
          gender: result['profile_data']?['gender'],
          birthday: result['profile_data']?['birthday'],
          avatar: result['profile_data']?['avatar'],
        );
        
        // 🆕 標記為已登入
        await authRepo.setIsLogin(true);
        
      } else {
        // 登入失敗，統一錯誤處理
        throw Exception('登錄失敗，稍後再試');
      }
      
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [AuthenticationViewModel.signInWithEC2Password] error: $error');
      state = AsyncError(error.toString(), stackTrace);
    }
  }

  // 🆕 發送重設密碼 Email (使用 Supabase)
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      
      // 🆕 使用 Supabase 發送重設密碼 Email
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-password', // 專用的重設密碼連結
      );
      
      // 🆕 發送成功
      state = AsyncData(state.value?.copyWith(
        isPasswordResetEmailSent: true,
        passwordResetError: null,
      ) ?? const AuthenticationState(
        isPasswordResetEmailSent: true,
      ));
      
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [AuthenticationViewModel.sendPasswordResetEmail] error: $error');
      
      // 🆕 處理不同類型的錯誤
      String errorMessage = error.toString();
      if (errorMessage.contains('not found') || errorMessage.contains('not registered')) {
        errorMessage = '此信箱未註冊';
      } else if (errorMessage.contains('rate') || errorMessage.contains('limit')) {
        errorMessage = '發送過於頻繁，請稍後再試';
      }
      
      state = AsyncData(state.value?.copyWith(
        isPasswordResetEmailSent: false,
        passwordResetError: errorMessage,
      ) ?? AuthenticationState(
        isPasswordResetEmailSent: false,
        passwordResetError: errorMessage,
      ));
      
      // 🆕 拋出錯誤讓 UI 處理
      throw Exception(errorMessage);
    }
  }

  // 🆕 重設密碼 (Supabase + EC2 同步)
  Future<void> resetPassword({
    required String newPassword,
    String? token,
    String? accessToken,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      
      // 🆕 Step 1: 使用 Supabase 更新密碼
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      // 🆕 Step 2: 取得當前 session
      final session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Session not found');
      }
      
      // 🆕 Step 3: 同步新密碼到 EC2
      final authRepo = ref.read(authenticationRepositoryProvider);
      await authRepo.syncPasswordToEC2(
        newPassword: newPassword,
        supabaseToken: session.accessToken,
      );
      
      // 🆕 Step 4: 更新 Profile (用戶已登入狀態)
      final userEmail = session.user.email;
      if (userEmail != null) {
        ref.read(profileViewModelProvider.notifier).updateProfile(
          email: userEmail,
        );
        
        // 🆕 標記為已登入
        await authRepo.setIsLogin(true);
      }
      
      // 🆕 重設成功
      state = AsyncData(state.value?.copyWith(
        isPasswordResetSuccessfully: true,
        passwordResetError: null,
        isSignInSuccessfully: true, // 重設後自動登入
      ) ?? const AuthenticationState(
        isPasswordResetSuccessfully: true,
        isSignInSuccessfully: true,
      ));
      
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [AuthenticationViewModel.resetPassword] error: $error');
      
      String errorMessage = error.toString();
      if (errorMessage.contains('invalid') || errorMessage.contains('expired')) {
        errorMessage = '重設連結已失效，請重新申請';
      } else if (errorMessage.contains('weak')) {
        errorMessage = '密碼強度不足，請使用更複雜的密碼';
      }
      
      state = AsyncData(state.value?.copyWith(
        isPasswordResetSuccessfully: false,
        passwordResetError: errorMessage,
      ) ?? AuthenticationState(
        isPasswordResetSuccessfully: false,
        passwordResetError: errorMessage,
      ));
      
      throw Exception(errorMessage);
    }
  }



Future<void> signInWithMagicLink(String email) async {
  state = const AsyncValue.loading();

  try {
    final supabase = Supabase.instance.client;

    await supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.flutter://login-callback', // ⚠️ 替換為你的 Deeplink
    );

    // 這裡不會立即登入成功，而是等使用者點擊 Email 裡的 magic link
    state = const AsyncData(AuthenticationState());
  } catch (error, stackTrace) {
    state = AsyncError(error.toString(), stackTrace);
  }
}

Future<void> sendOtp(String email) async {
  state = const AsyncValue.loading();
  final authRepo = ref.read(authenticationRepositoryProvider);
  final result = await AsyncValue.guard(() => authRepo.sendOtpEmail(email));

  if (result is AsyncError) {
    state = AsyncError(result.error, result.stackTrace); // ✅ 這樣才型別安全
  } else {
    state = const AsyncData(AuthenticationState());
  }
}




  Future<void> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
    String? password, //
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(
      () => authRepo.verifyOtp(
        email: email,
        token: token,
        isRegister: isRegister,
        password: password, // ✅ 傳下去
      ),
    );
    handleResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithGoogle);
    handleResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithApple);
    handleResult(result);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signOut);

    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  void handleResult(AsyncValue result) async {
    debugPrint(
        '${Constants.tag} [AuthenticationViewModel.handleResult] result: $result');
    if (result is AsyncError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    final AuthResponse? authResponse = result.value;
    debugPrint(
        '${Constants.tag} [AuthenticationViewModel.handleResult] authResponse: ${authResponse?.user?.toJson()}');
    if (authResponse == null) {
      state = AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
      return;
    }

    final isExistAccount =
        await ref.read(authenticationRepositoryProvider).isExistAccount();
    if (!isExistAccount) {
      ref.read(authenticationRepositoryProvider).setIsExistAccount(true);
    }

    String? name;
    String? avatar;
    final metaData = authResponse.user?.userMetadata;
    if (metaData != null) {
      name = metaData['full_name'];
      avatar = metaData['avatar_url'];
    }
    ref.read(authenticationRepositoryProvider).setIsLogin(true);
    ref.read(profileViewModelProvider.notifier).updateProfile(
          email: authResponse.user?.email.orEmpty(),
          name: name,
          avatar: avatar,
        );

    state = AsyncData(
      AuthenticationState(
        authResponse: authResponse,
        isRegisterSuccessfully: !isExistAccount,
        isSignInSuccessfully: true,
      ),
    );
  }

// 🆕 新增處理 Supabase Auth 成功後的 EC2 驗證
  Future<void> handleSupabaseAuthSuccess(Session session) async {
    try {
      // 設定 EC2 驗證中狀態
      state = AsyncData(
        state.value?.copyWith(
          isEC2Verifying: true,
          authResponse: AuthResponse(session: session, user: session.user),
        ) ?? AuthenticationState(
          isEC2Verifying: true,
          authResponse: AuthResponse(session: session, user: session.user),
        ),
      );

      // 更新基本 profile
      ref.read(profileViewModelProvider.notifier)
         .updateProfile(email: session.user.email ?? '');

      // 進行 EC2 驗證
      final authRepo = ref.read(authenticationRepositoryProvider);
      final ec2Result = await authRepo.verifyWithEC2(session.accessToken);

      // 處理 EC2 結果
      final ec2Status = ec2Result['status'] as String;
      final ec2ProfileComplete = ec2Result['profile_complete'] as bool? ?? false;
      final isNewUser = ec2Status == 'new_user';

      state = AsyncData(
        state.value!.copyWith(
          isEC2Verifying: false,
          isEC2Verified: true,
          ec2Status: ec2Status,
          // 統一邏輯：新用戶肯定不完整，舊用戶看 EC2 回應
          profileComplete: isNewUser ? false : ec2ProfileComplete,
          ec2ErrorMessage: null,
        ),
      );

    } catch (e) {
      state = AsyncData(
        state.value?.copyWith(
          isEC2Verifying: false,
          isEC2Verified: false,
          ec2ErrorMessage: e.toString(),
        ) ?? AuthenticationState(
          ec2ErrorMessage: e.toString(),
        ),
      );
    }
  }

  // 🆕 重試 EC2 驗證
  Future<void> retryEC2Verification() async {
    final session = state.value?.authResponse?.session;
    if (session != null) {
      await handleSupabaseAuthSuccess(session);
    }
  }

  // 🆕 處理 EC2 錯誤（簡化版）
  void handleEC2Error(String message, {bool canRetry = true}) {
    if (canRetry) {
      // 網絡錯誤等可重試的情況
      state = AsyncData(
        state.value?.copyWith(
          isEC2Verifying: false,
          isEC2Verified: false,
          ec2ErrorMessage: message,
        ) ?? AuthenticationState(ec2ErrorMessage: message),
      );
    } else {
      // token_invalid 等需要重新開始的情況
      state = const AsyncData(AuthenticationState());
    }
  }


  
}
