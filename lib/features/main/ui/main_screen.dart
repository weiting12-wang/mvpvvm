import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../features/hero_list/ui/hero_list_screen.dart';
import '../../../features/profile/ui/profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../../hero_list/ui/view_model/hero_count_provider.dart';
import '../../hero_list/ui/view_model/hero_list_view_model.dart';
import '../../../features/game/ui/game_screen.dart';
import '../../../features/training/ui/training_page.dart';

// const List<Widget> _screens = [
//   HeroListScreen(),
//   HeroListScreen(),
//   ProfileScreen(),
//   //RiveMenuScreen(),
//   // 用 ValueKey 強制在被選到時重建，讓進場動畫每次都跑
//   RiveMenuScreen(key: ValueKey('rive-$_riveRebuildTick')),
// ];

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  //late PersistentTabController _controller;
  //var _controller = PersistentTabController(initialIndex: 0);
  late final PersistentTabController _controller;

  static const int _riveTabIndex = 3; // Rive tab 的位置 (依你的 items 調整)
  int _riveRebuildTick = 0;           // 每次選到 Rive tab 就遞增，用於強制重建
 
   List<Widget> _buildScreens() {
    return [
      const TrainingPage(), // 🆕 第一個 tab 改為 TrainingPage（閃電圖標）
      const HeroListScreen(),
      const ProfileScreen(),
      // 注意：不要加 const，並用 ValueKey 綁定 tick
      RiveMenuScreen(key: ValueKey<int>(_riveRebuildTick)),
    ];
  }

  @override
  void initState() {
    super.initState();
    //_controller = PersistentTabController();
    _controller = PersistentTabController(initialIndex: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PersistentBottomNavBarItem> _navBarsItems(
    BuildContext context,
    Color selectedColor,
    Color unselectedColor,
    int count,
  ) {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(MingCuteIcons.mgc_lightning_fill, color: selectedColor),
        inactiveIcon:
            Icon(MingCuteIcons.mgc_lightning_line, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: AppColors.blueberry90,
          size: 20,
        ),
        inactiveIcon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: AppColors.blueberry90,
          size: 20,
        ),
        activeColorPrimary: selectedColor,
        inactiveColorPrimary: unselectedColor,
        onPressed: (_) async {
          final randomHero = sampleHeroes[count % sampleHeroes.length];
          await ref.read(heroListViewModelProvider.notifier).addHero(
                name: randomHero.name,
                description: randomHero.description,
                imageUrl: randomHero.imageUrl,
                power: randomHero.power,
              );
          ref.read(heroCountProvider.notifier).increment();
        },
      ),
      PersistentBottomNavBarItem(
        icon: Icon(MingCuteIcons.mgc_user_3_fill, color: selectedColor),
        inactiveIcon:
            Icon(MingCuteIcons.mgc_user_3_line, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.sports_baseball, color: selectedColor),
        inactiveIcon: Icon(Icons.sports_baseball_outlined, color: unselectedColor),
        //title: 'Games',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        context.isDarkMode ? AppColors.blueberry100 : AppColors.blueberry100;
    final unselectedColor =
        context.isDarkMode ? AppColors.mono40 : AppColors.mono60;
    final count = ref.watch(heroCountProvider);
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(
          context,
          selectedColor,
          unselectedColor,
          count,
        ),
        onItemSelected: (index) {
          if (index == _riveTabIndex) {
          setState(() => _riveRebuildTick++); // 選到 Rive → 重新 mount RiveMenuScreen
          }
        },
        //popAllScreensOnTapOfSelectedTab: true, // 同 tab 再點可把 push 的頁面全部 pop 回根頁
        confineToSafeArea: true,
        backgroundColor: context.secondaryWidgetColor,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          colorBehindNavBar: context.secondaryBackgroundColor,
        ),
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            // Screen transition animation on change of selected tab.
            animateTabTransition: true,
            duration: Duration(milliseconds: 300),
            screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
          ),
          onNavBarHideAnimation: OnHideAnimationSettings(
            duration: Duration(milliseconds: 100),
            curve: Curves.bounceInOut,
          ),
        ),
        navBarStyle: NavBarStyle.style6,
      ),
    );
  }
}
