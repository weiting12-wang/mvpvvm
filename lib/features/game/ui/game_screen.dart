import 'package:flutter/material.dart';
import '../model/rive_loader.dart';
import '../../../constants/assets.dart';
import '../../../constants/languages.dart';
import 'dog_control_screen.dart';

class RiveMenuScreen extends StatefulWidget {
  const RiveMenuScreen({super.key});

  @override
  State<RiveMenuScreen> createState() => _RiveMenuScreenState();
  
  static Future<T?> open<T>(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const RiveMenuScreen()),
    );
  }
}

class _RiveMenuScreenState extends State<RiveMenuScreen> {
  // 進場動畫設定（依你的素材名稱調整）
  // static const _introAsset = RiveAssets.rive_game_intro;
  // static const String? _introArtboard = null;       // 例: 'Intro'
  // static const String? _introStateMachine = null;   // 例: 'IntroSM'
  // static const String? _introAnimation = 'intro';   // 例: 'intro'
  static const String _gameBgImage = 'assets/images/game/game_welcome_bg.png';
  static const String _gameMapImage = 'assets/images/game/game_map.png';

  bool _showMenu = false;

  void _onStartPressed() {
    if (!mounted) return;
    setState(() => _showMenu = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text(Languages.riveGameTitle)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showMenu ? _buildMenu(context) : _buildIntroWithStart(),
      ),
    );
  }

  /// 進場畫面 + START 按鈕（按下才顯示主選單）
  Widget _buildIntroWithStart() {
    return Stack(
      key: const ValueKey('intro'),
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            _gameBgImage,
            fit: BoxFit.cover,          // 充滿全螢幕
            filterQuality: FilterQuality.medium,
          ),
        ),

        // Rive 全畫面播放（可依素材比例改用 AspectRatio）
        // Center(
        //   child: RivePlayer(
        //     assetPath: _introAsset,
        //     artboard: _introArtboard,
        //     stateMachineName: _introStateMachine,
        //     animation: _introAnimation,
        //   ),
        // ),
        // 半透明漸層遮罩（讓按鈕更顯眼，可移除）
        IgnorePointer(
          ignoring: true,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.6, 1.0],
                colors: [Colors.black54, Colors.transparent, Colors.transparent],
              ),
            ),
          ),
        ),
        // 置底的 START 按鈕
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _onStartPressed,
                    child: Text(Languages.gameStart),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3 個功能按鈕的主選單
  Widget _buildMenu(BuildContext context) {
    return Stack(
      key: const ValueKey('menu'),
    fit: StackFit.expand,
    children: [
      // [NEW] 背景照片（僅在 Menu 顯示）
      Positioned.fill(
        child: Image.asset(
          _gameMapImage,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
      // [NEW] 可讀性漸層（可選，想拿掉就移除這段）
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed:() {
                      Navigator.of(context,rootNavigator: true).push(MaterialPageRoute(
                        builder: (_) => DogControlScreen(
                        ),
                      ));
                    },
                    child: Text(Languages.riveGame1),
                  ),
                ),
              ),
            ),
          ),
        ),
      // ListView(
      //   key: const ValueKey('menu'),
      //   padding: const EdgeInsets.all(16),
      //   children: [
      //     ElevatedButton(
      //       onPressed: () {
      //         Navigator.of(context,rootNavigator: true).push(MaterialPageRoute(
      //           builder: (_) => DogControlScreen(
      //           ),
      //         ));
      //       },
      //       child: Text(Languages.riveGame1),
      //     ),
      //   ],
      //   ),
      ],
    );
  }
}