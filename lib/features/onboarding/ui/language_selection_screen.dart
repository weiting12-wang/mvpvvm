// lib/features/onboarding/ui/language_selection_screen.dart - 改進版本

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/languages.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../profile/ui/view_model/profile_view_model.dart';

// 語言數據模型
class LanguageOption {
  final String id;
  final String name;
  final String nativeName;
  final String code;
  final String flag;

  const LanguageOption({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flag,
  });
}

// 支援的語言清單
final List<LanguageOption> availableLanguages = [
  const LanguageOption(
    id: 'english_us',
    name: 'English (United States)',
    nativeName: 'English',
    code: 'en',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'english_uk',
    name: 'English (United Kingdom)',
    nativeName: 'English',
    code: 'en_GB',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'spanish_es',
    name: 'Spanish - Español',
    nativeName: 'Español',
    code: 'es',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'portuguese_br',
    name: 'Portuguese - Português',
    nativeName: 'Português',
    code: 'pt',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'chinese_cn',
    name: 'Chinese - 中文',
    nativeName: '中文',
    code: 'zh',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'hindi',
    name: 'Hindi - हिन्दी',
    nativeName: 'हिन्दी',
    code: 'hi',
    flag: '', // 移除國旗
  ),
  const LanguageOption(
    id: 'arabic',
    name: 'Arabic - العربية',
    nativeName: 'العربية',
    code: 'ar',
    flag: '', // 移除國旗
  ),
];

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String? _selectedLanguageId;

  @override
  void initState() {
    super.initState();
    // 預設選擇英語（美國）
    _selectedLanguageId = 'english_us';
  }

  void _selectLanguage(String languageId) {
    setState(() {
      _selectedLanguageId = languageId;
    });
  }

  Future<void> _continueWithLanguage() async {
    if (_selectedLanguageId == null) return;
    
    final selectedLang = availableLanguages.firstWhere(
      (lang) => lang.id == _selectedLanguageId,
    );
    
    try {
      // 保存語言選擇到 profile
      await ref.read(profileViewModelProvider.notifier).updateProfile(
        // 可以添加一個 language 欄位到 Profile model
        // language: selectedLang.code,
      );
      
      print('✅ 選擇語言: ${selectedLang.name} (${selectedLang.code})');
      
      if (mounted) {
        context.pushReplacement(Routes.speechTherapistExperience);
      }
    } catch (error) {
      print('❌ 保存語言選擇失敗: $error');
      if (mounted) {
        context.showErrorSnackBar('Failed to save language selection: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedLanguageId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF7CB342), // 綠色背景
      body: SafeArea(
        child: Column(
          children: [
            // 縮小的 Header Section - 只保留 logo 和標題
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // App Logo/Icon Area - 小綠色角色圖示
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🌱', // 簡單的表情符號代替角色
                        style: TextStyle(fontSize: 30),
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
            
            // 主要白色區域 - 問題和語言選單
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // 🆕 問題區塊移到白色區域
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Text(
                            'What languages\nare spoken\nat home:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5A87),
                              height: 1.3,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          const Text(
                            '(Choose at least one\nlanguage)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 語言列表 - 更大的點選區域
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: availableLanguages.length,
                        itemBuilder: (context, index) {
                          final language = availableLanguages[index];
                          final isSelected = _selectedLanguageId == language.id;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12), // 增加間距
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectLanguage(language.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18, // 增加垂直內邊距
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? const Color(0xFF7CB342).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF7CB342)
                                          : Colors.grey.shade300,
                                      width: isSelected ? 3 : 1, // 更粗的邊框
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Checkbox - 更大
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF7CB342)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF7CB342)
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 18,
                                              )
                                            : null,
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Language Name - 更大的字體
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              language.name,
                                              style: TextStyle(
                                                fontSize: 18, // 增加字體大小
                                                fontWeight: isSelected 
                                                    ? FontWeight.w600 
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? const Color(0xFF7CB342)
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (language.name != language.nativeName)
                                              Text(
                                                language.nativeName,
                                                style: TextStyle(
                                                  fontSize: 16, // 增加字體大小
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Bottom Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: hasSelection ? _continueWithLanguage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasSelection
                                    ? const Color(0xFF7CB342)
                                    : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: hasSelection ? 2 : 0,
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
                              context.pushReplacement(Routes.speechTherapistExperience);
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
                          
                          const SizedBox(height: 32),
                          
                          // Copyright
                          const Text(
                            '© 2025 Enlightenary LLC. All rights reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}