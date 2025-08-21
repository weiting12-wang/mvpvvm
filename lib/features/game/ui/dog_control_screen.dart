import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;
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
  static const String _dogJump  = 'game1_dog_jump';
  static const String _dogWave = 'game1_dog_waving';
  static const String _dogEncourage = 'game1_dog_encourage';
  
  static const String _pizzaArtboardName = 'Pizza';
  static const String _pizzaStateMachine = 'PizzaSM';
  static const String _pizzaBlink = 'blink';

  static const String _pizzaB1BaseTrigName = 'pepperoniTrigger';
  static const String _pizzaB2BaseTrigName = 'greenpepperTrigger';
  static const String _pizzaB3BaseTrigName = 'olivesTrigger';
  static const String _pizzaB4BaseTrigName = 'purpleonionTrigger';
  static const String _pizzaB5BaseTrigName = 'mushroomsTrigger';

  static const String _pizzab1ArtboardName = 'pizza_bt01';
  static const String _pizzab1StateMachine = 'pizza_bt01SM';
  static const String _pizzab2ArtboardName = 'pizza_bt02';
  static const String _pizzab2StateMachine = 'pizza_bt02SM';
  static const String _pizzab3ArtboardName = 'pizza_bt03';
  static const String _pizzab3StateMachine = 'pizza_bt03SM';
  static const String _pizzab4ArtboardName = 'pizza_bt04';
  static const String _pizzab4StateMachine = 'pizza_bt04SM';
  static const String _pizzab5ArtboardName = 'pizza_bt05';
  static const String _pizzab5StateMachine = 'pizza_bt05SM';

  // Pizza base 按鈕的 enabled 觸發器
  rive.SMITrigger? _pizzaB1BaseTrig;
  rive.SMITrigger? _pizzaB2BaseTrig;
  rive.SMITrigger? _pizzaB3BaseTrig;
  rive.SMITrigger? _pizzaB4BaseTrig;
  rive.SMITrigger? _pizzaB5BaseTrig;

  // [NEW] Pizza B1~B5 的 enabled 觸發器
  rive.SMITrigger? _pizzaB1EnabledTrig;
  rive.SMITrigger? _pizzaB2EnabledTrig;
  rive.SMITrigger? _pizzaB3EnabledTrig;
  rive.SMITrigger? _pizzaB4EnabledTrig;
  rive.SMITrigger? _pizzaB5EnabledTrig;

  // === 錄音按鈕 artboard 與 controller ===
  static const String _recButtonArtboardName = 'RecordingIcon';
  static const String _recButtonStateMachine = 'RecordSM';
  // =====================================

  // 背景 Dog
  rive.Artboard? _dogArt;
  rive.StateMachineController? _dogCtrl;
  rive.SMITrigger? _dogJumpTrig;
  rive.SMITrigger? _dogWaveTrig;
  rive.SMITrigger? _dogEncourageTrig;
  
  // 前景 Pizza
  rive.Artboard? _pizzaArt;
  rive.StateMachineController? _pizzaCtrl;
  rive.SMITrigger? _pizzaBlinkTrig;
  
  // 前景 Pizza 配料的 artboard 與 controller
  rive.Artboard? _pizzaB1Art;
  rive.StateMachineController? _pizzaB1Ctrl;
  rive.Artboard? _pizzaB2Art;
  rive.StateMachineController? _pizzaB2Ctrl;
  rive.Artboard? _pizzaB3Art;
  rive.StateMachineController? _pizzaB3Ctrl;
  rive.Artboard? _pizzaB4Art;
  rive.StateMachineController? _pizzaB4Ctrl;
  rive.Artboard? _pizzaB5Art;
  rive.StateMachineController? _pizzaB5Ctrl;

  // 錄音按鈕 Rive 控制
  rive.Artboard? _recordButtonArt;
  rive.StateMachineController? _recordButtonCtrl;
  rive.SMITrigger? _recStartTrig;
  rive.SMITrigger? _recStopTrig;
  rive.SMIBool? _recCheckCorrect;    // trigger: recordStop

  bool _showRecordButton = false;
  int _recordCorrectCount = 0;

  bool get _dogReady => _dogArt != null && _dogCtrl != null;
  bool get _pizzaReady => _pizzaArt != null && _pizzaCtrl != null;
  bool get _recordButtonReady => _recordButtonArt != null && _recordButtonCtrl != null;

  // === 要疊在前景的照片清單 ===
  final List<String> _photos = WordCardAssets.all_L_card;
  int _photoIndex = 0;
  bool _showPhotos = false; // 預設不顯示

   // 照片在畫面中的對齊（往上移一點：y = -0.5；置中改 Alignment.center）
  static const Alignment _photoAlignment = Alignment(0, -1);
  double _photoScale = 0.9; // 照片縮放比例（初始為 1）
  
  // 高亮綠色邊框狀態
  bool _highlightBorder = false;
  // 發光框相對於照片的縮放比例：1.0 = 跟照片一樣大；越小越縮
  double _glowBoxFactor = 0.2;

  // （可調）邊框與光暈強度
  double _borderWidth = 10.0;
  double _glowBlur = 12.0;
  double _glowSpread = 0.5;
  double _cornerRadius = 20.0;

  // ===== 控制按鈕 =====
  void _nextPhoto() {
    setState(() {
      _photoIndex = (_photoIndex + 1) % _photos.length;
      //_photoScale = 1;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadDogAndPizza().then((_) {
      // 延遲 5 秒再播放 wave
      Future.delayed(const Duration(seconds: 1), () {
        _dogWaveTrig?.fire();

        // 播放完 wave 再顯示錄音按鈕（假設 wave 是 2 秒）
        Future.delayed(const Duration(seconds: 2), () {
          _loadRecordButton(); // 👈 這裡載入錄音按鈕 artboard
          _showPhotos = true; // ✅ 錄音按鈕載入完才顯示照片
          _loadPizzaButton();
        });
      });
    });
  }

  // [REC] 主流程：錄 10 秒 -> 停 -> 上傳 -> 顯示回應
  Future<void> _record10sAndUploadWithAnim() async {
    if (_isRecording) return;
    try {
      // v6：還是用 hasPermission()
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack('未取得麥克風權限');
        return;
      }

      setState(() => _isRecording = true);

      // 1) Rive：啟動動畫
      _recStartTrig?.fire();
      // Dog 鼓勵動畫
      _dogEncourageTrig?.fire();
      
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

      await Future.delayed(const Duration(seconds: 5));

      // 停止計時 & 播「結束」動畫
      _recStopTrig?.fire();

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

      // 當response 成功時，播放「正確」動畫
      _showCorrectAnim();

      if(true) {
          if (_recordCorrectCount==0)
            _pizzaB1EnabledTrig?.fire();
          else if (_recordCorrectCount==1)
            _pizzaB2EnabledTrig?.fire();
          else if (_recordCorrectCount==2)
            _pizzaB3EnabledTrig?.fire();
          else if (_recordCorrectCount==3)
            _pizzaB4EnabledTrig?.fire();
          else if (_recordCorrectCount==4)
            _pizzaB5EnabledTrig?.fire();
          _recordCorrectCount = (_recordCorrectCount + 1) % 5;
      }

      _nextPhoto(); // ✅ 每次錄音後換下一張照片

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

  Future<void> _loadDogAndPizza() async {
    // 清空舊狀態
    setState(() {
      _dogArt = null; _dogCtrl = null; _dogJumpTrig = null;
      _pizzaArt = null; _pizzaCtrl = null; _pizzaBlinkTrig = null;
    });

    try {
      // 同一份 bytes，分別取出兩個 artboard
      final data = await rootBundle.load(widget.assetPath);
      final file = rive.RiveFile.import(data);

      // --- Dog（背景） ---
      final dogArt = file.artboardByName(_dogArtboardName) ?? file.mainArtboard;
      final dogCtrl = rive.StateMachineController.fromArtboard(dogArt, _dogStateMachine);
      if (dogCtrl == null) {
        if (!mounted) return;
        _showSnack('找不到 Dog 的 StateMachine：$_dogStateMachine');
      } else {
        dogArt.addController(dogCtrl);
        _dogJumpTrig  = dogCtrl.findInput<bool>(_dogJump)  as rive.SMITrigger?;
        _dogWaveTrig = dogCtrl.findInput<bool>(_dogWave) as rive.SMITrigger?;
        _dogEncourageTrig = dogCtrl.findInput<bool>(_dogEncourage) as rive.SMITrigger?;
      }

      // --- Pizza（前景） ---
      final pizzaArt = file.artboardByName(_pizzaArtboardName) ?? file.mainArtboard;
      final pizzaCtrl = rive.StateMachineController.fromArtboard(pizzaArt, _pizzaStateMachine);
      if (pizzaCtrl == null) {
        if (!mounted) return;
        _showSnack('找不到 Pizza 的 StateMachine：$_pizzaStateMachine');
      } else {
        pizzaArt.addController(pizzaCtrl);
        _pizzaBlinkTrig = pizzaCtrl.findInput<bool>(_pizzaBlink) as rive.SMITrigger?;
        _pizzaB1BaseTrig = pizzaCtrl.findInput<bool>(_pizzaB1BaseTrigName) as rive.SMITrigger?;
        _pizzaB2BaseTrig = pizzaCtrl.findInput<bool>(_pizzaB2BaseTrigName) as rive.SMITrigger?;
        _pizzaB3BaseTrig = pizzaCtrl.findInput<bool>(_pizzaB3BaseTrigName) as rive.SMITrigger?;
        _pizzaB4BaseTrig = pizzaCtrl.findInput<bool>(_pizzaB4BaseTrigName) as rive.SMITrigger?;
        _pizzaB5BaseTrig = pizzaCtrl.findInput<bool>(_pizzaB5BaseTrigName) as rive.SMITrigger?;
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
  void _dogJumpFire() {
    if (_dogJumpTrig == null) {
      _showSnack('Dog: 找不到 Trigger：$_dogJump');
    } else {
      _dogJumpTrig!.fire();
    }
  }
  
  void _dogWaveFire() {
    if (_dogWaveTrig == null) {
      _showSnack('Dog: 找不到 Trigger：$_dogWave');
    } else {
      _dogWaveTrig!.fire();
    }
  }

  // ---- Pizza controls ----
  void _pizzaBlinkFire() {
    if (_pizzaBlinkTrig == null) {
      _showSnack('Pizza: 找不到 Trigger：$_pizzaBlink');
    } else {
      _pizzaBlinkTrig!.fire();
    }
  }

  Future<void> _loadRecordButton() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final file = rive.RiveFile.import(data);

      final recArt = file.artboardByName(_recButtonArtboardName);
      final recCtrl = rive.StateMachineController.fromArtboard(recArt!, _recButtonStateMachine);

      rive.SMITrigger? startTrig;
      rive.SMITrigger? stopTrig;
      rive.SMIBool?    checkCorrectBool;

      if (recCtrl != null) {
        recArt.addController(recCtrl);
        startTrig = recCtrl.findInput<bool>('recordStart') as rive.SMITrigger?;
        stopTrig    = recCtrl.findInput<bool>('recordStop')  as rive.SMITrigger?;
        checkCorrectBool = recCtrl.findInput<bool>('checkCorrect') as rive.SMIBool?;

      }

      if (!mounted) return;
      setState(() {
        _recordButtonArt = recArt;
        _recordButtonCtrl = recCtrl;
        _recStartTrig = startTrig;   // 👈 新增 trigger 變數
        _recStopTrig  = stopTrig;
        _recCheckCorrect   = checkCorrectBool;
      });
    } catch (e) {
      _showSnack('載入錄音按鈕失敗：$e');
    }
  }

  // [NEW] 播放「正確」動畫：設 true -> 等待 -> 還原 false
  void _showCorrectAnim({Duration hold = const Duration(milliseconds: 1200)}) {
    _recCheckCorrect?.value = true;
    Future.delayed(hold, () {
      _recCheckCorrect?.value = false;
    });
  }

  Future<void> _loadPizzaButton() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final file = rive.RiveFile.import(data);

      // 載入 pizzaB1~B5
      final b1 = file.artboardByName(_pizzab1ArtboardName);
      final b2 = file.artboardByName(_pizzab2ArtboardName);
      final b3 = file.artboardByName(_pizzab3ArtboardName);
      final b4 = file.artboardByName(_pizzab4ArtboardName);
      final b5 = file.artboardByName(_pizzab5ArtboardName);

      final b1Ctrl = b1 != null ? rive.StateMachineController.fromArtboard(b1, _pizzab1StateMachine) : null;
      final b2Ctrl = b2 != null ? rive.StateMachineController.fromArtboard(b2, _pizzab2StateMachine) : null;
      final b3Ctrl = b3 != null ? rive.StateMachineController.fromArtboard(b3, _pizzab3StateMachine) : null;
      final b4Ctrl = b4 != null ? rive.StateMachineController.fromArtboard(b4, _pizzab4StateMachine) : null;
      final b5Ctrl = b5 != null ? rive.StateMachineController.fromArtboard(b5, _pizzab5StateMachine) : null;

      if (b1 != null && b1Ctrl != null) b1.addController(b1Ctrl);
      if (b2 != null && b2Ctrl != null) b2.addController(b2Ctrl);
      if (b3 != null && b3Ctrl != null) b3.addController(b3Ctrl);
      if (b4 != null && b4Ctrl != null) b4.addController(b4Ctrl);
      if (b5 != null && b5Ctrl != null) b5.addController(b5Ctrl);

      // [NEW] 取各自 StateMachine 的 enabled 觸發器（名稱都叫 'enabled'）
      final b1Enabled = b1Ctrl?.findInput<bool>('enabled') as rive.SMITrigger?;
      final b2Enabled = b2Ctrl?.findInput<bool>('enabled') as rive.SMITrigger?;
      final b3Enabled = b3Ctrl?.findInput<bool>('enabled') as rive.SMITrigger?;
      final b4Enabled = b4Ctrl?.findInput<bool>('enabled') as rive.SMITrigger?;
      final b5Enabled = b5Ctrl?.findInput<bool>('enabled') as rive.SMITrigger?;


      if (!mounted) return;
      setState(() {
        _pizzaB1Art = b1; _pizzaB1Ctrl = b1Ctrl;
        _pizzaB2Art = b2; _pizzaB2Ctrl = b2Ctrl;
        _pizzaB3Art = b3; _pizzaB3Ctrl = b3Ctrl;
        _pizzaB4Art = b4; _pizzaB4Ctrl = b4Ctrl;
        _pizzaB5Art = b5; _pizzaB5Ctrl = b5Ctrl;

        _pizzaB1EnabledTrig = b1Enabled;
        _pizzaB2EnabledTrig = b2Enabled;
        _pizzaB3EnabledTrig = b3Enabled;
        _pizzaB4EnabledTrig = b4Enabled;
        _pizzaB5EnabledTrig = b5Enabled;

      });
    } catch (e) {
      _showSnack('載入Pizza按鈕失敗：$e');
    }
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
                if (_showPhotos)
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
                            // ② 底層：縮小後的發光容器（只在高亮時顯示）
                            if (_highlightBorder)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(_cornerRadius),
                                      border: Border.all(color: const Color.fromARGB(0xff, 0x8a, 0xe9, 0x4a), width: _borderWidth),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0),
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

          //下半部：控制列（含「換照片」）
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // ElevatedButton(
                  //   onPressed: () => _dogWaveFire(),
                  //   child: const Text('跳躍'),
                  // ),
                  // // 這顆按鈕：切換前景照片
                  // FilledButton.icon(
                  //   onPressed: _nextPhoto,
                  //   icon: const Icon(Icons.image),
                  //   label: const Text('換照片'),
                  // ),
                  // 邊框高亮切換
                  // FilledButton.icon( // [NEW]
                  //   onPressed: () =>
                  //       setState(() => _highlightBorder = !_highlightBorder), // [NEW]
                  //   icon: const Icon(Icons.auto_awesome), // [NEW]
                  //   label: Text(_highlightBorder ? '關閉高亮' : '邊框變亮綠'), // [NEW]
                  // ),
                  // // [REC] 錄音 10 秒並送出
                  // FilledButton.icon(
                  //   onPressed: _isRecording ? null : _record10sAndUpload,
                  //   icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
                  //   label: Text(_isRecording ? '錄音中…' : '錄音 10 秒並送出'),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildOverlay() {
  final screenHeight = MediaQuery.of(context).size.height;

  return Stack(
    fit: StackFit.expand,
    children: [
      // 背景：Dog
      _dogReady
        ? Transform.translate(
            offset: Offset(0, -MediaQuery.of(context).size.height * 0.05), // 👈 上移 5% 螢幕高度
            child: rive.Rive(
              artboard: _dogArt!,
              fit: BoxFit.cover,
            ),
          )
        : const Center(child: CircularProgressIndicator()),
      // 前景：Pizza，下移 10% 高度
      _pizzaReady
        ? Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * 0.15), // 相對螢幕下移
            child: Transform.scale(
              scale: 0.65, // 👈 縮小為原來的 80%（1.0 = 原始大小）
              alignment: Alignment.center,
              child: rive.Rive(
                artboard: _pizzaArt!,
                fit: BoxFit.contain,
              ),
            ),
          )
        : const SizedBox.shrink(),
       // [REC] 錄音按鈕（疊在最上層）
      if (_recordButtonArt != null)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0), // 👈 調整位置
            child: GestureDetector(
              onTap: () {
                if (!_isRecording) {
                  _record10sAndUploadWithAnim();
                }
              },
              child: SizedBox(
                width: 90,
                height: 90,
                child: rive.Rive(
                  artboard: _recordButtonArt!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        )
      else
        const SizedBox.shrink(), // 若錄音按鈕未載入，則不顯示
      // [REC] 錄音按鈕（縮小版，疊

      // if (_recordButtonArt != null)
      //   Transform.translate(
      //       offset: Offset(0, MediaQuery.of(context).size.height * 0.35), // 相對螢幕下移
      //       child: Transform.scale(
      //         scale: 0.25, // 👈 縮小為原來的 80%（1.0 = 原始大小）
      //         alignment: Alignment.center,
      //         child: rive.Rive(
      //           artboard: _recordButtonArt!,
      //           fit: BoxFit.contain,
      //         ),
      //       ),
      //     )
      // else
      //   const SizedBox.shrink(),  // 若錄音按鈕未載入，則不顯示 
      // 下排按鈕：Pizza B1~B5
      if (_pizzaB1Art != null &&
          _pizzaB2Art != null &&
          _pizzaB3Art != null &&
          _pizzaB4Art != null &&
          _pizzaB5Art != null)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80), // 與錄音鈕保持距離
            child: SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniRiveBtn(
                    art: _pizzaB1Art!,
                    selfEnabled: _pizzaB1EnabledTrig,   // 可為 null
                    mainPizzaTrig: _pizzaB1BaseTrig,    // 觸發主 Pizza 的 b1trigger
                  ),
                  _miniRiveBtn(
                    art: _pizzaB2Art!,
                    selfEnabled: _pizzaB2EnabledTrig,
                    mainPizzaTrig: _pizzaB2BaseTrig,
                  ),
                  _miniRiveBtn(
                    art: _pizzaB3Art!,
                    selfEnabled: _pizzaB3EnabledTrig,
                    mainPizzaTrig: _pizzaB3BaseTrig,
                  ),
                  _miniRiveBtn(
                    art: _pizzaB4Art!,
                    selfEnabled: _pizzaB4EnabledTrig,
                    mainPizzaTrig: _pizzaB4BaseTrig,
                  ),
                  _miniRiveBtn(
                    art: _pizzaB5Art!,
                    selfEnabled: _pizzaB5EnabledTrig,
                    mainPizzaTrig: _pizzaB5BaseTrig,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

// 可點擊的小 Rive 按鈕：點擊時先觸發自己的 enabled（若有），再觸發主 Pizza 的對應 Trigger
Widget _miniRiveBtn({
  required rive.Artboard art,
  rive.SMITrigger? selfEnabled,   // 小按鈕自己的視覺回饋（optional）
  rive.SMITrigger? mainPizzaTrig, // 主 Pizza 上的對應 Trigger
}) {
  return GestureDetector(
    onTap: () {
      selfEnabled?.fire();   // 小按鈕自身的「enabled」效果（可省略）
      mainPizzaTrig?.fire(); // 關鍵：觸發主 Pizza 的動畫（b1/b2/...）
    },
    child: SizedBox(
      width: 60,
      height: 60,
      child: rive.Rive(
        artboard: art,
        fit: BoxFit.contain,
      ),
    ),
  );
}



  

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