// lib/features/onboarding/ui/speech_therapist_experience_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import '../../../routing/routes.dart';

class SpeechTherapistExperienceScreen extends ConsumerStatefulWidget {
  const SpeechTherapistExperienceScreen({super.key});

  @override
  ConsumerState createState() => _SpeechTherapistExperienceScreenState();
}

class _SpeechTherapistExperienceScreenState extends ConsumerState<SpeechTherapistExperienceScreen> {
  bool? _hasExperience; // null = 未選擇, true = Yes, false = No
  final TextEditingController _referralCodeController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _referralCodeController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _referralCodeController.removeListener(_updateButtonState);
    _referralCodeController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    // 必須選擇 Yes 或 No 才能繼續
    setState(() {
      _isButtonEnabled = _hasExperience != null;
    });
  }

  void _selectExperience(bool hasExperience) {
    setState(() {
      _hasExperience = hasExperience;
      _updateButtonState();
    });
  }

  bool _isValidReferralCode(String code) {
    if (code.isEmpty) return true; // 空的也可以（選填）
    if (code.length != 6) return false;
    
    // 檢查是否只包含英文字母和數字
    final regex = RegExp(r'^[A-Za-z0-9]{6}$');
    return regex.hasMatch(code);
  }

  @override
  Widget build(BuildContext context) {
    // 取得用戶姓名
    final profile = ref.watch(profileViewModelProvider).value?.profile;
    final userName = profile?.name ?? 'child';
    
    final referralCode = _referralCodeController.text.toUpperCase();
    final isReferralCodeValid = _isValidReferralCode(referralCode);

    return Scaffold(
      backgroundColor: const Color(0xFF7CB342), // 綠色背景
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - 綠色區域
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // App Logo/Character
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '😊', // 可愛的小角色表情
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'Enlighten\nSpeech Learning',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content - 白色區域
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Question
                        Text(
                          'Has $userName ever\nworked with a\nspeech therapist\nbefore?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D5A87),
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle
                        const Text(
                          '(We\'d love to hear about\nany past experience so we\ncan make this journey\nbetter!)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Yes/No Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectExperience(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _hasExperience == true
                                        ? Colors.grey.shade300
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _hasExperience == true
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Yes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _hasExperience == true
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectExperience(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _hasExperience == false
                                        ? const Color(0xFF2D5A87)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _hasExperience == false
                                          ? const Color(0xFF2D5A87)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'No',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _hasExperience == false
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Referral Code Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Referral Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D5A87),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isReferralCodeValid && referralCode.isNotEmpty
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                controller: _referralCodeController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                  UpperCaseTextFormatter(),
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'ABC123',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    letterSpacing: 2.0,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            
                            if (!isReferralCodeValid && referralCode.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Referral code must be exactly 6 letters/numbers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isButtonEnabled && isReferralCodeValid
                                ? () => _continueToNext()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isButtonEnabled && isReferralCodeValid
                                  ? const Color(0xFF7CB342)
                                  : Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: _isButtonEnabled && isReferralCodeValid ? 2 : 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Skip Button
                        TextButton(
                          onPressed: () {
                            context.pushReplacement(Routes.main);
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Copyright
                        const Text(
                          '© 2025 Enlightenary LLC. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continueToNext() async {
    try {
      final referralCode = _referralCodeController.text.trim();
      
      // 保存語言治療師經驗和推薦碼到 profile
      await ref.read(profileViewModelProvider.notifier).updateProfile(
        // 這裡可以添加新欄位到 Profile model
        // speechTherapistExperience: _hasExperience,
        // referralCode: referralCode.isEmpty ? null : referralCode,
      );
      
      print('✅ 語言治療師經驗: ${_hasExperience == true ? 'Yes' : 'No'}');
      if (referralCode.isNotEmpty) {
        print('✅ 推薦碼: $referralCode');
      }
      
      if (mounted) {
        context.pushReplacement(Routes.main);
      }
    } catch (error) {
      print('❌ 保存經驗資訊失敗: $error');
      if (mounted) {
        context.showErrorSnackBar('Failed to save information: $error');
      }
    }
  }
}

// 自定義輸入格式化器，將輸入自動轉為大寫
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}