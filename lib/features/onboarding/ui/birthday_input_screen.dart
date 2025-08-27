import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import '../../../routing/routes.dart';

class BirthdayInputScreen extends ConsumerStatefulWidget {
  const BirthdayInputScreen({super.key});

  @override
  ConsumerState createState() => _BirthdayInputScreenState();
}

class _BirthdayInputScreenState extends ConsumerState<BirthdayInputScreen> {
  final TextEditingController _birthdayController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _birthdayController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _birthdayController.removeListener(_updateButtonState);
    _birthdayController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final text = _birthdayController.text;
    // 檢查格式是否正確 (dd/mm/yyyy)
    final isValid = _isValidDate(text);
    if (isValid != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isValid;
      });
    }
  }

  bool _isValidDate(String text) {
    if (text.length != 10) return false;
    
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(text)) return false;
    
    try {
      final parts = text.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // 基本驗證
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;
      
      // 嘗試建立日期物件驗證
      final date = DateTime(year, month, day);
      return date.day == day && date.month == month && date.year == year;
    } catch (e) {
      return false;
    }
  }

  String _calculateAge() {
    if (!_isValidDate(_birthdayController.text)) return '';
    
    try {
      final parts = _birthdayController.text.split('/');
      final birthday = DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
      
      final now = DateTime.now();
      int age = now.year - birthday.year;
      
      // 如果還沒過今年的生日，年齡減1
      if (now.month < birthday.month || 
          (now.month == birthday.month && now.day < birthday.day)) {
        age--;
      }
      
      return age.toString();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - 顯示用戶名字
              Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(profileViewModelProvider).value?.profile;
                  final name = profile?.name ?? 'child';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How old is $name?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '(Let\'s make sure we have the right age to match the learning stage!)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // Select Date of Birth Section
              const Text(
                'Select Date of Birth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5A87),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Birthday Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _birthdayController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D5A87),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'dd/mm/yyyy',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // 顯示年齡
              if (age.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Age: $age years old',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled ? () => _saveBirthdayAndContinue(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonEnabled 
                        ? const Color(0xFF7CB342) 
                        : const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
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
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pushReplacement('/language-selection'); // 👈 改成跳轉到語言選擇
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Copyright
              const Center(
                child: Text(
                  '© 2025 Enlightenary LLC. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBirthdayAndContinue(BuildContext context) async {
    try {
      // 儲存生日到 profile
      await ref.read(profileViewModelProvider.notifier).updateProfile(
        birthday: _birthdayController.text,
      );
      
      print('✅ 生日已儲存: ${_birthdayController.text}');
      print('✅ 年齡: ${_calculateAge()} 歲');
      
      if (context.mounted) {
        context.pushReplacement('/language-selection');
        //context.pushReplacement(Routes.main);
      }
    } catch (error) {
      print('❌ 儲存生日失敗: $error');
      if (context.mounted) {
        context.showErrorSnackBar('Failed to save birthday: $error');
      }
    }
  }
}

// 自定義輸入格式化器，自動添加 / 分隔符
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 2) {
      return newValue;
    } else if (text.length <= 4) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else if (text.length <= 8) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}',
        selection: TextSelection.collapsed(offset: text.length + 2),
      );
    } else {
      // 限制最大長度為 8 個數字 (ddmmyyyy)
      final limitedText = text.substring(0, 8);
      return TextEditingValue(
        text: '${limitedText.substring(0, 2)}/${limitedText.substring(2, 4)}/${limitedText.substring(4)}',
        selection: const TextSelection.collapsed(offset: 10),
      );
    }
  }
}