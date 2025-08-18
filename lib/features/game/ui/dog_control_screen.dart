import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../../../constants/assets.dart';
import '../../../constants/languages.dart';
// [REC] 新增：錄音、HTTP、暫存路徑
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

/// 同一個 .riv 同時顯示兩個 artboard：
/// - 背景：Dog（DogSM）
/// - 前景：Pizza（PizzaSM）
/// 各自擁有獨立的 Input：blink(Trigger) / jump(Trigger) / run(Bool)
class DogControlScreen extends StatefulWidget {
  const DogControlScreen({
    super.key,
    this.assetPath = RiveAssets.rive_game_1, // 你的 .riv 檔路徑（同檔包含 Dog / Pizza 兩個 artboard）
  });

  final String assetPath;

  @override
  State<DogControlScreen> createState() => _DogControlScreenState();
}

class _DogControlScreenState extends State<DogControlScreen> {

  // [REC] API 端點（請換掉）
  static const String _audioApiEndpoint = 'https://example.com/api/upload-audio';

  // [REC] 錄音器與狀態
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastResponseMessage;

  // ===== 依你的 .riv 實際命名在此調整 =====
  static const String _dogArtboardName = 'Dog';
  static const String _dogStateMachine = 'DogSM';
  static const String _dogBlink = 'blink';
  static const String _dogJump  = 'game1_dog_jump';
  static const String _dogRun   = 'run';

  static const String _pizzaArtboardName = 'Pizza';
  static const String _pizzaStateMachine = 'State Machine 1';
  static const String _pizzaBlink = 'blink';
  static const String _pizzaJump  = 'jump';
  static const String _pizzaRun   = 'run';
  // =====================================

  // 背景 Dog
  Artboard? _dogArt;
  StateMachineController? _dogCtrl;
  SMITrigger? _dogBlinkTrig;
  SMITrigger? _dogJumpTrig;
  SMIBool? _dogRunBool;

  // 前景 Pizza
  Artboard? _pizzaArt;
  StateMachineController? _pizzaCtrl;
  SMITrigger? _pizzaBlinkTrig;
  SMITrigger? _pizzaJumpTrig;
  SMIBool? _pizzaRunBool;

  bool get _dogReady => _dogArt != null && _dogCtrl != null;
  bool get _pizzaReady => _pizzaArt != null && _pizzaCtrl != null;

  // ===== 可調參數 =====
  // Artboard? _artboard;
  // StateMachineController? _dogController;

  // SMITrigger? _jump;
  
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
  double _glowBoxFactor = 0.3;

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

  @override
  void initState() {
    super.initState();
    _loadBoth();
  }

  // [REC] 主流程：錄 10 秒 -> 停 -> 上傳 -> 顯示回應
  Future<void> _record10sAndUpload() async {
    if (_isRecording) return;
    try {
      // v6：還是用 hasPermission()
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack('未取得麥克風權限');
        return;
      }

      setState(() => _isRecording = true);

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // ✅ v6 正確啟動：start(RecordConfig, path: ...)
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc, // m4a
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      await Future.delayed(const Duration(seconds: 10));

      // ✅ v6：stop() 仍回傳實際檔案路徑（或 null）
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path == null) {
        _showSnack('未取得錄音檔');
        return;
      }

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        _showSnack('錄音檔無效');
        return;
      }

      // 上傳 multipart
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(_audioApiEndpoint),
      )..files.add(
          await http.MultipartFile.fromPath(
            'audio',
            path,
            contentType: MediaType('audio', 'm4a'),
          ),
        );

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final msg = resp.body.isEmpty ? '上傳成功（無內容）' : resp.body;
        setState(() => _lastResponseMessage = msg);
        _showSnack('伺服器回應：$msg');

        // ✅ 上傳成功後刪除暫存檔
        try {
          await File(path).delete();
        } catch (e) {
          debugPrint('刪除暫存檔失敗: $e');
        }
      } else {
        _showSnack('上傳失敗：${resp.statusCode} ${resp.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnack('錄音/上傳發生錯誤：$e');
    }
  }

  Future<void> _loadBoth() async {
    // 清空舊狀態
    setState(() {
      _dogArt = null; _dogCtrl = null; _dogBlinkTrig = null; _dogJumpTrig = null; _dogRunBool = null;
      _pizzaArt = null; _pizzaCtrl = null; _pizzaBlinkTrig = null; _pizzaJumpTrig = null; _pizzaRunBool = null;
    });

    try {
      // 同一份 bytes，分別取出兩個 artboard
      final data = await rootBundle.load(widget.assetPath);
      final file = RiveFile.import(data);

      // --- Dog（背景） ---
      final dogArt = file.artboardByName(_dogArtboardName) ?? file.mainArtboard;
      final dogCtrl = StateMachineController.fromArtboard(dogArt, _dogStateMachine);
      if (dogCtrl == null) {
        if (!mounted) return;
        _showSnack('找不到 Dog 的 StateMachine：$_dogStateMachine');
      } else {
        dogArt.addController(dogCtrl);
        _dogBlinkTrig = dogCtrl.findInput<bool>(_dogBlink) as SMITrigger?;
        _dogJumpTrig  = dogCtrl.findInput<bool>(_dogJump)  as SMITrigger?;
        _dogRunBool   = dogCtrl.findInput<bool>(_dogRun)   as SMIBool?;
      }

      // --- Pizza（前景） ---
      final pizzaArt = file.artboardByName(_pizzaArtboardName) ?? file.mainArtboard;
      final pizzaCtrl = StateMachineController.fromArtboard(pizzaArt, _pizzaStateMachine);
      if (pizzaCtrl == null) {
        if (!mounted) return;
        _showSnack('找不到 Pizza 的 StateMachine：$_pizzaStateMachine');
      } else {
        pizzaArt.addController(pizzaCtrl);
        _pizzaBlinkTrig = pizzaCtrl.findInput<bool>(_pizzaBlink) as SMITrigger?;
        _pizzaJumpTrig  = pizzaCtrl.findInput<bool>(_pizzaJump)  as SMITrigger?;
        _pizzaRunBool   = pizzaCtrl.findInput<bool>(_pizzaRun)   as SMIBool?;
      }

      if (!mounted) return;
      setState(() {
        _dogArt = dogArt;   _dogCtrl = dogCtrl;
        _pizzaArt = pizzaArt; _pizzaCtrl = pizzaCtrl;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('載入 Rive 失敗：$e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

   // ---- Dog controls ----
  void _dogBlinkFire() {
    if (_dogBlinkTrig == null) {
      _showSnack('Dog: 找不到 Trigger：$_dogBlink');
    } else {
      _dogBlinkTrig!.fire();
    }
  }
  void _dogJumpFire() {
    if (_dogJumpTrig == null) {
      _showSnack('Dog: 找不到 Trigger：$_dogJump');
    } else {
      _dogJumpTrig!.fire();
    }
  }
  void _dogRunToggle() {
    if (_dogRunBool == null) return _showSnack('Dog: 找不到 Bool：$_dogRun');
    _dogRunBool!.value = !_dogRunBool!.value;
    setState(() {});
  }

  // ---- Pizza controls ----
  void _pizzaBlinkFire() {
    if (_pizzaBlinkTrig == null) {
      _showSnack('Pizza: 找不到 Trigger：$_pizzaBlink');
    } else {
      _pizzaBlinkTrig!.fire();
    }
  }
  void _pizzaJumpFire() {
    if (_pizzaJumpTrig == null) {
      _showSnack('Pizza: 找不到 Trigger：$_pizzaJumpTrig');
    } else {
      _pizzaJumpTrig!.fire();
    }
  }
  void _pizzaRunToggle() {
    if (_pizzaRunBool == null) return _showSnack('Pizza: 找不到 Bool：$_pizzaRun');
    _pizzaRunBool!.value = !_pizzaRunBool!.value;
    setState(() {});
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
                _buildOverlay(),

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
                    onPressed: () => _dogJumpFire(),
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
                  // [REC] 錄音 10 秒並送出
                  FilledButton.icon(
                    onPressed: _isRecording ? null : _record10sAndUpload,
                    icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
                    label: Text(_isRecording ? '錄音中…' : '錄音 10 秒並送出'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景：Dog
        _dogReady
            ? Rive(artboard: _dogArt!, fit: BoxFit.cover) // 或改 BoxFit.cover 讓背景鋪滿
            : const Center(child: CircularProgressIndicator()),
        // 前景：Pizza（必要時可用 Transform 做位移/縮放）
        _pizzaReady
            ? Rive(artboard: _pizzaArt!, fit: BoxFit.cover)
            : const SizedBox.shrink(),

        // 左上角標籤
        // Positioned(
        //   left: 8, top: 8,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //     decoration: BoxDecoration(
        //       color: Colors.black54, borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: const Text('Dog(後) + Pizza(前)', style: TextStyle(color: Colors.white)),
        //   ),
        // ),

        // // 底部控制列：第一排 Dog、第二排 Pizza
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: Container(
        //     color: Colors.black54,
        //     padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        //     child: SafeArea(
        //       top: false,
        //       child: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Row(
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: _dogButtons(),
        //           ),
        //           const SizedBox(height: 8),
        //           Row(
        //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //             children: _pizzaButtons(),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // List<Widget> _dogButtons() => [
  //       FilledButton.icon(
  //         onPressed: _dogReady ? _dogBlinkFire : null,
  //         icon: const Icon(Icons.visibility),
  //         label: const Text('眨眼'),
  //       ),
  //       FilledButton.icon(
  //         onPressed: _dogReady ? _dogJumpFire : null,
  //         icon: const Icon(Icons.arrow_upward),
  //         label: const Text('跳'),
  //       ),
  //       FilledButton.icon(
  //         onPressed: _dogReady ? _dogRunToggle : null,
  //         icon: const Icon(Icons.directions_run),
  //         label: Text(_dogRunBool?.value == true ? '停止跑' : '開始跑'),
  //       ),
  //     ];

  // List<Widget> _pizzaButtons() => [
  //       FilledButton.icon(
  //         onPressed: _pizzaReady ? _pizzaBlinkFire : null,
  //         icon: const Icon(Icons.visibility),
  //         label: const Text('眨眼'),
  //       ),
  //       FilledButton.icon(
  //         onPressed: _pizzaReady ? _pizzaJumpFire : null,
  //         icon: const Icon(Icons.arrow_upward),
  //         label: const Text('跳'),
  //       ),
  //       FilledButton.icon(
  //         onPressed: _pizzaReady ? _pizzaRunToggle : null,
  //         icon: const Icon(Icons.local_pizza),
  //         label: Text(_pizzaRunBool?.value == true ? '停止跑' : '開始跑'),
  //       ),
  //     ];

  @override
  void dispose() {
    // [REC] 停掉錄音器
    try { _recorder.dispose(); } catch (_) {}
    // 不需要特別處理 Rive 資源；清空參考即可
    _dogCtrl = null; _dogArt = null;
    _pizzaCtrl = null; _pizzaArt = null;
    super.dispose();
  }
}
