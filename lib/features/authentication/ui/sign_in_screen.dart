import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../../features/authentication/ui/widgets/horizontal_divider.dart';
import '../../../features/authentication/ui/widgets/social_sign_in.dart';
import '../../../features/common/ui/widgets/common_back_button.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validator.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _showEmailSentBanner = false; // 🆕 Email 發送提示橫幅

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);
    _passwordController = TextEditingController();
    _passwordController.addListener(_validateForm);

  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
    });
  }
  void _validateForm() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
      _isPasswordValid = _passwordController.text.length >= 6;
    });
  }
  // 🆕 統一錯誤對話框 (模仿 Duolingo)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('登錄失敗'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('好'),
          ),
        ],
      ),
    );
  }

  // 🆕 新增：顯示 Email 發送提示橫幅
  void _displayEmailSentBanner() {
    setState(() {
      _showEmailSentBanner = true;
    });
    
    // 5秒後自動隱藏
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showEmailSentBanner = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // 🆕 監聽認證狀態變化
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        // 統一錯誤處理 - 不透露具體錯誤原因
        _showErrorDialog('登錄失敗，稍後再試');
      }

      if (next is AsyncData) {
        final authState = next.value!;
        
        // 處理 EC2 登入成功
        if (authState.isSignInSuccessfully) {
          // 根據 profile 完整度決定導向
          if (authState.profileComplete) {
            context.go(Routes.main);
          } else {
            context.go(Routes.onboarding);
          }
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 主要內容區域
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SvgPicture.asset(
                            Assets.login,
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.bottomCenter,
                            semanticsLabel: 'Sign in',
                          ),
                        ),
                        Text(
                          'sign_in'.tr(),
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
                        
                        // 🆕 修改為真正的 EC2 登入
                        PrimaryButton(
                          isEnable: _isEmailValid && _isPasswordValid,
                          text: 'sign_in'.tr(), // 改成 "Sign In"
                          onPressed: () async {
                            // 🆕 直接呼叫 EC2 密碼驗證，不跳轉 OTP
                            await ref
                                .read(authenticationViewModelProvider.notifier)
                                .signInWithEC2Password(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 🆕 忘記密碼按鈕 (模仿 Duolingo)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              context.push(
                                Routes.forgotPassword,
                                extra: {
                                  'email': _emailController.text.trim(),
                                },
                              ).then((result) {
                                // 🆕 從忘記密碼頁面回來後，顯示 Email 發送提示
                                if (result == true) {
                                  _displayEmailSentBanner();
                                }
                              });
                            },
                            child: Text(
                              'Forgot Password?',
                              style: AppTheme.body14.copyWith(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const HorizontalDivider(),
                        const SizedBox(height: 16),
                        const SocialSignIn(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CommonBackButton(),
                  ),
                ],
              ),
            ),
            
            // 🆕 Email 發送提示橫幅 (模仿 Duolingo)
            if (_showEmailSentBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '重設密碼連結已發送，請查看您的信箱',
                        style: AppTheme.body14.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showEmailSentBanner = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}