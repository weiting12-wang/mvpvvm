import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;        // URL query parameter token
  final String? accessToken;  // Supabase access token from URL fragment

  const ResetPasswordScreen({
    super.key,
    this.token,
    this.accessToken,
  });

  @override
  ConsumerState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isLoading = false;
  bool _isTokenValid = true; // 假設 token 有效，除非驗證失敗

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    
    // 🆕 檢查 token 是否存在
    if (widget.token == null && widget.accessToken == null) {
      _isTokenValid = false;
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _isPasswordValid = _passwordController.text.length >= 6;
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _isConfirmPasswordValid = _confirmPasswordController.text.length >= 6 &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  // 🆕 顯示錯誤對話框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重設失敗'),
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

  // 🆕 顯示成功對話框
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('重設成功'),
        content: Text('密碼已成功重設，即將返回登入頁面'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 🆕 成功後直接進入 Main 頁面 (模仿 Duolingo)
              context.go(Routes.main);
            },
            child: Text('好'),
          ),
        ],
      ),
    );
  }

  // 🆕 重設密碼
  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('密碼不一致');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authenticationViewModelProvider.notifier)
          .resetPassword(
            newPassword: _passwordController.text,
            token: widget.token,
            accessToken: widget.accessToken,
          );

      if (mounted) {
        // 🆕 重設成功，顯示成功對話框
        _showSuccessDialog();
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = '重設失敗，請稍後再試';
        
        if (error.toString().contains('invalid') || 
            error.toString().contains('expired')) {
          errorMessage = '重設連結已失效，請重新申請';
        } else if (error.toString().contains('weak')) {
          errorMessage = '密碼強度不足，請使用更複雜的密碼';
        }
        
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 添加調試信息
    debugPrint('[ResetPasswordScreen] build 被調用');
    debugPrint('[ResetPasswordScreen] _isTokenValid: $_isTokenValid');
    
    // 🆕 監聽 auth 狀態變化
    ref.listen(authenticationViewModelProvider, (previous, next) {
      debugPrint('[ResetPasswordScreen] Auth state 變化: $next');
      if (next is AsyncData) {
        final state = next.value!;
        debugPrint('[ResetPasswordScreen] isPasswordResetSuccessfully: ${state.isPasswordResetSuccessfully}');
        debugPrint('[ResetPasswordScreen] isSignInSuccessfully: ${state.isSignInSuccessfully}');
        
        if (state.isPasswordResetSuccessfully) {
          debugPrint('[ResetPasswordScreen] 觸發跳轉到 main');
          _showSuccessDialog();
        }
      }
    });    
    // 🆕 如果 token 無效，顯示錯誤頁面
    if (!_isTokenValid) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '重設連結無效',
                  style: AppTheme.title24,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '重設連結已失效或無效，請重新申請重設密碼',
                  style: AppTheme.body16,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: '返回登入',
                  onPressed: () => context.go(Routes.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 插圖區域
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.otp, // 重用 OTP 的插圖
                        fit: BoxFit.fitHeight,
                        height: 200,
                        semanticsLabel: 'Reset Password',
                      ),
                    ),
                  ),
                  
                  // 🆕 標題和說明
                  Text(
                    '重設密碼',
                    style: AppTheme.title32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '請輸入您的新密碼',
                    style: AppTheme.body16.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 🆕 新密碼輸入欄位
                  CommonTextFormField(
                    label: '新密碼',
                    controller: _passwordController,
                    isPassword: true,
                    //enabled: !_isLoading,
                    validator: (val) => val != null && val.length < 6
                        ? '密碼至少需要 6 個字符'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // 🆕 確認密碼輸入欄位
                  CommonTextFormField(
                    label: '確認新密碼',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    //enabled: !_isLoading,
                    validator: (val) {
                      if (val != null && val.length < 6) {
                        return '密碼至少需要 6 個字符';
                      }
                      if (val != _passwordController.text) {
                        return '密碼不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // 🆕 重設密碼按鈕
                  PrimaryButton(
                    text: _isLoading ? '重設中...' : '重設密碼',
                    isEnable: _isPasswordValid && _isConfirmPasswordValid && !_isLoading,
                    onPressed: _resetPassword,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 🆕 返回登入按鈕
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.go(Routes.login),
                      child: Text(
                        '返回登入',
                        style: AppTheme.body14.copyWith(
                          color: _isLoading 
                              ? Colors.grey 
                              : Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // 🆕 Loading 覆蓋層
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


