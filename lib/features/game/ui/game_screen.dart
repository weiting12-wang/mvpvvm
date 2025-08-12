import 'package:flutter/material.dart';
import '../model/rive_loader.dart';
import 'rive_player_screen.dart';
import '../../../constants/assets.dart';
import '../../../constants/languages.dart';
import 'package:video_player/video_player.dart';

class RiveMenuScreen extends StatefulWidget {
  const RiveMenuScreen({super.key});

  @override
  State<RiveMenuScreen> createState() => _RiveMenuScreenState();
}

class _RiveMenuScreenState extends State<RiveMenuScreen> {
  // 進場動畫設定（依你的素材名稱調整）
  static const _introAsset = RiveAssets.rive_game_into;
  static const String? _introArtboard = null;       // 例: 'Intro'
  static const String? _introStateMachine = null;   // 例: 'IntroSM'
  static const String? _introAnimation = 'intro';   // 例: 'intro'

  // === 影片設定 ===
  static const String _introVideoAsset = 'assets/videos/intro.mov'; // 你的 mp4 路徑
  late final VideoPlayerController _videoController;
  bool _videoReady = false;
  bool _videoDone = false;

  bool _showMenu = false;

  void _onStartPressed() {
    if (!mounted) return;
    // 關閉影片
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }
    setState(() {
      _videoDone = true;
      _showMenu = true;
    });
  }

  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset(_introVideoAsset);
    await _videoController.initialize();
    _videoController.setLooping(false);
    _videoController.play();
    setState(() => _videoReady = true);

    // 播放完成監聽
    _videoController.addListener(() {
      if (_videoController.value.isInitialized &&
          !_videoController.value.isPlaying &&
          _videoController.value.position >= _videoController.value.duration &&
          !_videoDone) {
        setState(() => _videoDone = true);
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Languages.riveGameTitle)),
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
        // === Rive 背景（底層） ===
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black12),
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RivePlayer(
                  assetPath: _introAsset,
                  artboard: _introArtboard,
                  stateMachineName: _introStateMachine,
                  animation: _introAnimation,
                ),
              ),
            ),
          ),
        ),

        // === MP4 疊在 Rive 上面（中間層） ===
        if (_videoReady)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 10000),
              opacity: _videoDone ? 0 : 1,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: IgnorePointer(
                    // 讓影片不吃點擊，Start 按鈕可點
                    ignoring: true,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),
          ),

        // === Start 按鈕（上層） ===
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _onStartPressed,
              icon: const Icon(Icons.play_arrow),
              label: Text(Languages.gameStart),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3 個功能按鈕的主選單
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
