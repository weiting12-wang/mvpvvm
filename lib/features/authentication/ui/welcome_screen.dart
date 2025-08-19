import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/constants/assets.dart';
import '/constants/constants.dart';
import '/extensions/build_context_extension.dart';
import '/main.dart';
import '/routing/routes.dart';
import '/theme/app_theme.dart';
import '/utils/global_loading.dart';
import '/utils/validator.dart';
import '../../common/ui/widgets/common_text_form_field.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import 'view_model/authentication_view_model.dart';
import 'widgets/horizontal_divider.dart';
import 'widgets/sign_in_agreement.dart';
import 'widgets/social_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final TextEditingController _emailController;
  late final StreamSubscription<AuthState> _authSubscription;
  late final TextEditingController _passwordController;
  bool _isPasswordValid = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);
    _passwordController = TextEditingController();
    _passwordController.addListener(_validatePassword);


    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async { // 🆕 加 async
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      debugPrint(
          '${Constants.tag} [WelcomeScreen.initState] Auth change: $event, session: $session');
      if (event == AuthChangeEvent.signedIn && session != null) {
        print('${Constants.tag} [WelcomeScreen.Auth監聽器] 🚀 準備觸發 handleSupabaseAuthSuccess');
        // 🆕 觸發 EC2 驗證，而不是直接導航
        ref.read(authenticationViewModelProvider.notifier)
          .handleSupabaseAuthSuccess(session);
      }
    });
  }
  // 👇 在這裡添加 _showEC2Error 方法
  void _showEC2Error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
    });
  }
  void _validatePassword() {
    setState(() {
      _isPasswordValid = _passwordController.text.length >= 6;
    });
  }


  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next.isLoading != previous?.isLoading) {
        if (next.isLoading) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next is AsyncData) {
        final authState = next.value!;
        
        debugPrint(
            '${Constants.tag} [WelcomeScreen.build] isRegisterSuccessfully = ${authState.isRegisterSuccessfully}, isSignInSuccessfully = ${authState.isSignInSuccessfully}');
        
        // 處理 EC2 驗證錯誤
        if (authState.ec2ErrorMessage != null) {
          _showEC2Error(authState.ec2ErrorMessage!);
        }
        
        // 處理 EC2 驗證完成後的導航（主要流程）
        if (authState.isEC2Verified && !authState.isEC2Verifying) {
          switch (authState.ec2Status) {
            case 'new_user':
              context.go(Routes.onboarding);
              break;
            case 'existing_user':
              if (authState.profileComplete) {
                context.go(Routes.main);
              } else {
                context.go(Routes.onboarding);
              }
              break;
          }
        }

        // 現有用戶的註冊成功導航
        ////if (authState.isRegisterSuccessfully) {
        ////  context.pushReplacement(Routes.onboarding);
        ////} 
        // 已註冊用戶的備用導航（防護機制）
        else if (authState.isSignInSuccessfully && !authState.isEC2Verifying) {
          if (authState.ec2Status == null) {  // 如果後端沒返回狀態
            if (authState.profileComplete) {
              context.pushReplacement(Routes.main);
            } else {
              context.pushReplacement(Routes.onboarding);
            }
          }
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  Assets.welcome,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  semanticsLabel: 'Welcome',
                ),
              ),
              Text(
                'register'.tr(),
                style: AppTheme.title32,
              ),
              const SizedBox(height: 24),
              CommonTextFormField(
                label: 'Email',
                controller: _emailController,
                validator: notEmptyEmailValidator,
              ),
              const SizedBox(height: 32),
              CommonTextFormField(
                label: 'Password',
                controller: _passwordController,
                isPassword: true,
                validator: (val) => val != null && val.length < 6
                    ? 'Password too short'
                    : null,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                isEnable: _isEmailValid && _isPasswordValid,
                text: 'continue'.tr(),
                onPressed: () async { // 👈 加上 async
                    // 🆕 存儲註冊資訊給後續 EC2 使用
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('temp_registration_email', _emailController.text.trim());
                  await prefs.setString('temp_registration_password', _passwordController.text);
                  ref
                      .read(authenticationViewModelProvider.notifier)
                      .signInWithMagicLink(_emailController.text);

                  context.push(
                    Routes.otp,
                    extra: {
                      'email': _emailController.text,
                      'password': _passwordController.text,
                      'isRegister': true,
                    },
                  );
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'already_have_account'.tr(),
                    style: AppTheme.body14,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      context.push(Routes.login);
                    },
                    child: Text(
                      'sign_in'.tr(),
                      style: AppTheme.title14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const HorizontalDivider(),
              const SizedBox(height: 16),
              const SocialSignIn(),
              const SizedBox(height: 16),
              const SignInAgreement(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
