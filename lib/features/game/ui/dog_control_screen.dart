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
    this.dogStateMachineName = 'DogSM',
    this.pizzaStateMachineName = 'PizzaSM',
    this.inputBlink = 'blink',
    this.inputJump = 'game1_dog_jump',
    this.inputRun = 'run',
  });

  final String assetPath;
  final String artboardName;
  final String dogStateMachineName;
  final String pizzaStateMachineName;

  /// State Machine Inputs 名稱（需與 Rive 檔一致）
  final String inputBlink; // Trigger
  final String inputJump;  // Trigger
  final String inputRun;   // Boolean

  @override
  State<DogControlScreen> createState() => _DogControlScreenState();
}

class _DogControlScreenState extends State<DogControlScreen> {
  Artboard? _artboard;
  StateMachineController? _dogController,_pizzaController;

  SMITrigger? _jump;
  
  // === 要疊在前景的照片清單 ===
  final List<String> _photos = const [
    'assets/images/game1_words/L001.png',
    'assets/images/game1_words/L002.png',
    'assets/images/game1_words/L003.png',
    'assets/images/game1_words/L004.png',
  ];
  int _photoIndex = 0;

   // 照片在畫面中的對齊（往上移一點：y = -0.5；置中改 Alignment.center）
  static const Alignment _photoAlignment = Alignment(0, -2);
  double _photoScale = 1; // 照片縮放比例（初始為 1）
  
  // 高亮綠色邊框狀態
  bool _highlightBorder = false;
  // 發光框相對於照片的縮放比例：1.0 = 跟照片一樣大；越小越縮
  double _glowBoxFactor_height = 0.3;
  double _glowBoxFactor_width = 0.75;
  double _glowBoxFactor = 1;

  // （可調）邊框與光暈強度
  double _borderWidth = 25.0;
  double _glowBlur = 12.0;
  double _glowSpread = 0.5;
  double _cornerRadius = 10.0;

  void _nextPhoto() {
    setState(() {
      _photoIndex = (_photoIndex + 1) % _photos.length;
      //_photoScale = 1;
    });
  }

  void _onRiveInit(Artboard artboard) {
    try {
      
      if (widget.dogStateMachineName.isEmpty ||  widget.pizzaStateMachineName.isEmpty) return;
      final dogC = StateMachineController.fromArtboard(artboard, widget.dogStateMachineName);
      //final pizzaC = StateMachineController.fromArtboard(artboard, widget.pizzaStateMachineName);
      if ( dogC== null) return;
      artboard.addController(dogC);
      //artboard.addController(pizzaC);
      _dogController = dogC;
      //_pizzaController = pizzaC;

      // 依你的 Rive input 名稱取值（示例：blink/click/run）
      // 如果名稱不同，請改成你的 input 名稱
      //     // 取得 Inputs（名稱需與 Rive 編輯器一致）
      _jump  = dogC.findInput<bool>(widget.inputJump) as SMITrigger?;

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showError('Rive 初始化失敗：$e');
    }
    
 
  }

  bool get _isReady => _artboard != null && _dogController != null;

  @override
  void initState() {
    super.initState();
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
                Align(
  alignment: _photoAlignment,
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    child: Transform.scale(
      key: ValueKey('photo_${_photos[_photoIndex]}_$_photoScale$_highlightBorder$_glowBoxFactor'),
      scale: _photoScale,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          
          // ① 上層：原本的照片
          ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius - 2),
            child: Image.asset(
              _photos[_photoIndex],
              fit: BoxFit.contain,
            ),
          ),

          // ② 上層：縮小後的發光容器（只在高亮時顯示）
          // ② 底層：縮小後的發光容器（只在高亮時顯示）
          if (_highlightBorder)
            FractionallySizedBox(
              widthFactor: _glowBoxFactor_width,
              heightFactor: _glowBoxFactor_height,
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_cornerRadius),
                    border: Border.all(color: Colors.greenAccent, width: _borderWidth),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.transparent,
                        blurRadius: _glowBlur,
                        spreadRadius: _glowSpread,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
                    onPressed: () => _onJump(),
                    child: const Text('跳躍'),
                  ),
                  // 這顆按鈕：切換前景照片
                  FilledButton.icon(
                    onPressed: _nextPhoto,
                    icon: const Icon(Icons.image),
                    label: const Text('換照片'),
                  ),
                  // 邊框高亮切換
                  FilledButton.icon( // [NEW]
                    onPressed: () =>
                        setState(() => _highlightBorder = !_highlightBorder), // [NEW]
                    icon: const Icon(Icons.auto_awesome), // [NEW]
                    label: Text(_highlightBorder ? '關閉高亮' : '邊框變亮綠'), // [NEW]
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
      stateMachines: widget.dogStateMachineName.isEmpty ? const [] : [widget.dogStateMachineName],
      fit: BoxFit.cover,        // 關鍵：全螢幕填滿（可能裁切）
      alignment: Alignment.center,
      onInit: _onRiveInit,
    ),
  );
}

  @override
  void dispose() {
    // 不需要特別處理 Rive 資源；清空參考即可
    _dogController = null;
    _artboard = null;
    super.dispose();
  }
}
