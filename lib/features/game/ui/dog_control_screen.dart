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

  SMITrigger? _blink;
  SMITrigger? _jump;
  SMIBool? _run;

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
      _blink = controller.findInput<bool>(widget.inputBlink) as SMITrigger?;
      _jump  = controller.findInput<bool>(widget.inputJump) as SMITrigger?;
      _run   = controller.findInput<bool>(widget.inputRun)  as SMIBool?;

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

  void _onBlink() {
    if (_blink == null) return _showError('找不到 Trigger：${widget.inputBlink}');
    _blink!.fire();
  }

  void _onJump() {
    if (_jump == null) return _showError('找不到 Trigger：${widget.inputJump}');
    _jump!.fire();
  }

  void _onRunToggle() {
    if (_run == null) return _showError('找不到 Bool：${widget.inputRun}');
    _run!.value = !(_run!.value);
    setState(() {}); // 讓按鈕文字更新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 讓內容延伸到 AppBar 後
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 透明
        elevation: 0,                         // 去除陰影
        scrolledUnderElevation: 0,            // 移除滾動陰影 (M3)
        surfaceTintColor: Colors.transparent, // 移除表面著色 (M3)
        systemOverlayStyle: SystemUiOverlayStyle.light, // 狀態列白字圖示
        title: Text(
          Languages.riveGame1,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
      fit: StackFit.expand,
      children: [
        // 全螢幕 Rive 畫面
        _isReady
            ? Rive(
                artboard: _artboard!,
                fit: BoxFit.contain, // 或 BoxFit.cover 看需求
              )
            : const Center(child: CircularProgressIndicator()),
        // 底部控制按鈕列（半透明背景）
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.icon(
                    onPressed: _isReady ? _onBlink : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('眨眼'),
                  ),
                  FilledButton.icon(
                    onPressed: _isReady ? _onJump : null,
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('跳'),
                  ),
                  FilledButton.icon(
                    onPressed: _isReady ? _onRunToggle : null,
                    icon: const Icon(Icons.directions_run),
                    label: Text(_run?.value == true ? '停止跑' : '開始跑'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
