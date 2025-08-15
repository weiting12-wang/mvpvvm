
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../../features/common/ui/widgets/common_back_button.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validator.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? prefillEmail; // 從 Sign In 頁面帶過來的 email

  const ForgotPasswordScreen({
    super.key,
    this.prefillEmail,
  });

  @override
  ConsumerState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isEmailValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 🆕 預填 email (如果有的話)
    _emailController = TextEditingController(text: widget.prefillEmail ?? '');
    _emailController.addListener(_validateEmail);
    
    // 如果預填了 email，立即驗證
    if (widget.prefillEmail != null) {
      _validateEmail();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text.trim());
    });
  }

  // 🆕 顯示錯誤對話框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('發送失敗'),
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

  // 🆕 發送重設密碼 Email
  Future<void> _sendResetEmail() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authenticationViewModelProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        // 🆕 發送成功，回到 Sign In 頁面並顯示提示
        context.pop(true); // 回傳 true 表示發送成功
      }
    } catch (error) {
      if (mounted) {
        // 🆕 根據錯誤類型顯示不同訊息
        String errorMessage = '發送失敗，請稍後再試';
        
        if (error.toString().contains('not found') || 
            error.toString().contains('not registered')) {
          errorMessage = '此信箱未註冊';
        } else if (error.toString().contains('rate') || 
                   error.toString().contains('limit')) {
          errorMessage = '發送過於頻繁，請稍後再試';
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
                        semanticsLabel: 'Forgot Password',
                      ),
                    ),
                  ),
                  
                  // 🆕 標題和說明
                  Text(
                    'Forgot Password?',
                    style: AppTheme.title32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '輸入您的信箱，我們將發送重設密碼連結給您',
                    style: AppTheme.body16.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 🆕 Email 輸入欄位
                  CommonTextFormField(
                    label: 'Email',
                    controller: _emailController,
                    validator: notEmptyEmailValidator,
                    //enabled: !_isLoading, // 發送中時禁用
                  ),
                  const SizedBox(height: 32),
                  
                  // 🆕 發送按鈕
                  PrimaryButton(
                    text: _isLoading ? '發送中...' : '發送重設連結',
                    isEnable: _isEmailValid && !_isLoading,
                    onPressed: _sendResetEmail,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 🆕 返回登入按鈕
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.pop(),
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
            
            // 🆕 返回按鈕
            Positioned(
              top: 16,
              left: 16,
              child: CommonBackButton(
                onBack: _isLoading ? null : () => context.pop(),
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
