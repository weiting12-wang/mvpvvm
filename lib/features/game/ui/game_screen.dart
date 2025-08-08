import 'package:flutter/material.dart';
import '../model/rive_loader.dart';
import 'rive_player_screen.dart';
import '../../../constants/assets.dart';
import '../../../constants/languages.dart';

class RiveMenuScreen extends StatefulWidget {
  const RiveMenuScreen({super.key});

  @override
  State<RiveMenuScreen> createState() => _RiveMenuScreenState();
}

class _RiveMenuScreenState extends State<RiveMenuScreen> {
  // === 這裡設定「進場動畫」 ===
  static const _introDuration = Duration(seconds: 3); // 播放幾秒後顯示按鈕
  static const _introAsset = RiveAssets.rive_game_into;
  static const String? _introArtboard = null;          // 例: 'Intro'
  static const String? _introStateMachine = null;      // 例: 'IntroSM'（若用 SM）
  static const String? _introAnimation = 'intro';      // 例: 'intro'（若用 SimpleAnimation）

  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _playIntroThenShowMenu();
  }

  Future<void> _playIntroThenShowMenu() async {
    setState(() => _showMenu = false);
    await Future<void>.delayed(_introDuration);
    if (!mounted) return;
    setState(() => _showMenu = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Languages.riveGameTitle)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _showMenu ? _buildMenu(context) : _buildIntro(),
      ),
    );
  }

  // 進場 Rive 畫面（先顯示這個）
  Widget _buildIntro() {
    return Center(
      key: const ValueKey('intro'),
      child: AspectRatio(
        aspectRatio: 1, // 依素材調整
        child: RivePlayer(
          assetPath: _introAsset,
          artboard: _introArtboard,
          stateMachineName: _introStateMachine,
          animation: _introAnimation,
        ),
      ),
    );
  }

  // 3 個按鈕的主選單（到時間才顯示）
  Widget _buildMenu(BuildContext context) {
    return ListView(
      key: const ValueKey('menu'),
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RivePlayerScreen(
                title: Languages.riveGame1,
                assetPath: RiveAssets.rive_game_1,
                stateMachineName: 'StateMachine1',
              ),
            ));
          },
          child: Text(Languages.riveGame1),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RivePlayerScreen(
                title: Languages.riveGame2,
                assetPath: RiveAssets.rive_game_2,
                animation: 'wag',
              ),
            ));
          },
          child: Text(Languages.riveGame2),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RivePlayerScreen(
                title: Languages.riveGame3,
                assetPath: RiveAssets.rive_game_3,
                artboard: 'DogDance',
                stateMachineName: 'DanceSM',
              ),
            ));
          },
          child: Text(Languages.riveGame3),
        ),
      ],
    );
  }
}
