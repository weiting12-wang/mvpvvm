// 文件位置: lib/features/training/ui/training_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';

class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // iPad 或大屏設備
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 主要內容區域 - 響應式佈局
            isLandscape && isTablet 
                ? _buildLandscapeLayout(screenSize)
                : _buildPortraitLayout(screenSize, isTablet),
            
            
            // 最下方：左右兩個指示燈 - 響應式位置和尺寸
            Positioned(
              bottom: isTablet ? 48 : 32,
              left: isTablet ? 48 : 32,
              child: _buildIndicatorLight(
                color: Colors.yellow,
                shadowColor: Colors.yellow.withOpacity(0.5),
                icon: Icons.lightbulb,
                iconColor: Colors.orange.shade800,
                size: isTablet ? 80 : 60,
                iconSize: isTablet ? 32 : 24,
              ),
            ),
            
            Positioned(
              bottom: isTablet ? 48 : 32,
              right: isTablet ? 48 : 32,
              child: _buildIndicatorLight(
                color: Colors.green,
                shadowColor: Colors.green.withOpacity(0.5),
                icon: Icons.lightbulb,
                iconColor: Colors.green.shade800,
                size: isTablet ? 80 : 60,
                iconSize: isTablet ? 32 : 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 直向佈局（手機 + iPad 直向）
  Widget _buildPortraitLayout(Size screenSize, bool isTablet) {
    return Column(
      children: [
        // 上半部：影片播放區域
        Expanded(
          flex: isTablet ? 2 : 3, // iPad 上影片區域稍微小一點
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(isTablet ? 16 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(isTablet ? 20 : 12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    size: isTablet ? 80 : 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Video Player Area',
                    style: AppTheme.body16.copyWith(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 中間：字卡區域
        Container(
          height: isTablet ? 160 : 120, // iPad 上字卡區域更高
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 16,
            vertical: isTablet ? 24 : 16,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 600 : double.infinity, // iPad 上限制最大寬度
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48 : 32, 
                vertical: isTablet ? 24 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                border: Border.all(
                  color: Colors.blue.shade300, 
                  width: isTablet ? 3 : 2,
                ),
              ),
              child: Text(
                'Word Card Area',
                style: AppTheme.title20.copyWith(
                  color: Colors.blue.shade800,
                  fontSize: isTablet ? 28 : 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        // 下半部：相機區域
        Expanded(
          flex: isTablet ? 2 : 3, // 與影片區域保持平衡
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(isTablet ? 16 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(isTablet ? 20 : 12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: isTablet ? 80 : 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Camera Preview Area',
                    style: AppTheme.body16.copyWith(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 橫向佈局（iPad 橫向）
  Widget _buildLandscapeLayout(Size screenSize) {
    return Row(
      children: [
        // 左側：影片 + 字卡
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // 影片區域
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Video Player Area',
                          style: AppTheme.body16.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 字卡區域
              Container(
                height: 120,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blue.shade300, width: 3),
                    ),
                    child: Text(
                      'Word Card Area',
                      style: AppTheme.title20.copyWith(
                        color: Colors.blue.shade800,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 右側：相機區域
        Expanded(
          flex: 2,
          child: Container(
            height: double.infinity,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Camera Preview',
                    style: AppTheme.body16.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 指示燈組件
  Widget _buildIndicatorLight({
    required Color color,
    required Color shadowColor,
    required IconData icon,
    required Color iconColor,
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
