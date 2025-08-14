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
