import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../../../constants/assets.dart';
import '../../../constants/languages.dart';


/// 讀取 Rive 並提供 3 個動作控制：眨眼 / 跳 / 跑
class DogControlScreen extends StatefulWidget {
  const DogControlScreen({
    super.key,
    this.assetPath = RiveAssets.rive_game_1,
    this.artboardName = 'Dog',
    this.stateMachineName = 'DogSM',
    this.inputBlink = 'blink',
    this.inputJump = 'click',
    this.inputRun = 'run',
  });

  final String assetPath;
  final String artboardName;
  final String stateMachineName;

  /// State Machine Inputs 名稱（需與 Rive 檔一致）
  final String inputBlink; // Trigger
  final String inputJump;  // Trigger
  final String inputRun;   // Boolean

  @override
  State<DogControlScreen> createState() => _DogControlScreenState();
}

class _DogControlScreenState extends State<DogControlScreen> {
  Artboard? _artboard;
  StateMachineController? _controller;

  SMITrigger? _jump;
  
  // === 要疊在前景的照片清單 ===
  final List<String> _photos = const [
    'assets/images/game1_words/L001.png',
    'assets/images/game1_words/L002.png',
    'assets/images/game1_words/L003.png',
    'assets/images/game1_words/L004.png',
  ];
  int _photoIndex = 0;

  void _nextPhoto() {
    setState(() {
      _photoIndex = (_photoIndex + 1) % _photos.length;
    });
  }

  void _onRiveInit(Artboard artboard) {
    if (widget.stateMachineName.isEmpty) return;
    final c = StateMachineController.fromArtboard(artboard, widget.stateMachineName);
    if (c == null) return;
    artboard.addController(c);
    _controller = c;

    // 依你的 Rive input 名稱取值（示例：blink/click/run）
    // 如果名稱不同，請改成你的 input 名稱
    _jump = c.inputs.whereType<SMITrigger>().cast<SMITrigger?>().firstWhere(
          (i) => i?.name == 'click' || i?.name == 'jump',
          orElse: () => null,
        );
  }

  bool get _isReady => _artboard != null && _controller != null;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final file = RiveFile.import(data);
      final art = file.artboardByName(widget.artboardName) ?? file.mainArtboard;
      final controller = StateMachineController.fromArtboard(art, widget.stateMachineName);

      if (controller == null) {
        if (!mounted) return;
        _showError('找不到 StateMachine：${widget.stateMachineName}');
        return;
      }

      art.addController(controller);

      // 取得 Inputs（名稱需與 Rive 編輯器一致）
      _jump  = controller.findInput<bool>(widget.inputJump) as SMITrigger?;
      
      if (!mounted) return;
      setState(() {
        _artboard = art;
        _controller = controller;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('載入 Rive 失敗：$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onJump() {
    if (_jump == null) return _showError('找不到 Trigger：${widget.inputJump}');
    _jump!.fire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       // 若想透明 AppBar，可改成透明樣式
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 透明
        elevation: 0,
        scrolledUnderElevation: 0,            // M3 移除滾動陰影
        surfaceTintColor: Colors.transparent, // M3 移除表面色
        systemOverlayStyle: SystemUiOverlayStyle.light, // 狀態列白字圖示（深色背景用）
        title: const Text(
          ' ', // 或你的標題文字；若要白色字：style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 上半部：Rive + 前景照片
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ===== 底層：Rive 畫面 =====
                _buildRive(),

                // ===== 前景：可切換的照片 =====
                // IgnorePointer 讓按鈕事件不被圖片攔截
                IgnorePointer(
                  ignoring: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Align(
                      alignment: const Alignment(0, -2), // 往上移：-0.5 可自行調整
                      child: Image.asset(
                        _photos[_photoIndex],
                        key: ValueKey(_photos[_photoIndex]),
                        fit: BoxFit.contain,
                        // width: 280, height: 280, // 需要固定大小可解註
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 下半部：控制列（含「換照片」）
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => _jump?.fire(),
                    child: const Text('跳躍'),
                  ),
                  // 這顆按鈕：切換前景照片
                  FilledButton.icon(
                    onPressed: _nextPhoto,
                    icon: const Icon(Icons.image),
                    label: const Text('換照片'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildRive() {
  // 直接填滿整個可用空間
  return SizedBox.expand(
    child: RiveAnimation.asset(
      widget.assetPath,
      artboard: widget.artboardName.isEmpty ? null : widget.artboardName,
      stateMachines: widget.stateMachineName.isEmpty ? const [] : [widget.stateMachineName],
      fit: BoxFit.cover,        // 關鍵：全螢幕填滿（可能裁切）
      alignment: Alignment.center,
      onInit: _onRiveInit,
    ),
  );
}

  @override
  void dispose() {
    // 不需要特別處理 Rive 資源；清空參考即可
    _controller = null;
    _artboard = null;
    super.dispose();
  }
}
