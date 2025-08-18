import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/constants.dart';
import 'environment/env.dart';
import 'extensions/build_context_extension.dart';
import 'features/common/ui/providers/app_theme_mode_provider.dart';
import 'features/common/ui/widgets/offline_container.dart';
import 'routing/router.dart';
import 'utils/provider_observer.dart';
import 'utils/device_info_service.dart';

Future<void> initPlatformState() async {
  try {
    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(
      Platform.isIOS ? Env.revenueCatAppStore : Env.revenueCatPlayStore,
    );
    await Purchases.configure(configuration);
  } on PlatformException catch (e) {
    debugPrint('${Constants.tag} [initPlatformState] Error: ${e.message}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /// 🆕 Device Info - 最早初始化
  await _initializeDeviceInfo();
  /// Firebase
  // await Firebase.initializeApp(
  //     // options: DefaultFirebaseOptions.currentPlatform,
  //     );
  // await FirebaseAnalytics.instance.logAppOpen();
  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  /// Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  /// Mobile ads
  // MobileAds.instance.initialize();

  /// RevenueCat
  await initPlatformState();

  /// Localization
  await EasyLocalization.ensureInitialized();

  /// Google Font
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  runApp(
    ProviderScope(
      observers: [AppObserver()],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: const MainApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

final supabaseAuthListenerProvider = Provider<void>((ref) {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    final session = data.session;
    
    debugPrint('[Supabase] Auth Event: $event, User: ${session?.user?.email}');
    
    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session != null) {
          debugPrint('[Supabase] Magic Link 登入成功：${session.user?.email}');
          router.go('/main');
        }
        break;
        
      case AuthChangeEvent.passwordRecovery:
        if (session != null) {
          debugPrint('[Supabase] Password Recovery 事件觸發');
          debugPrint('[Supabase] Access Token: ${session.accessToken.substring(0, 20)}...');
          router.go('/reset-password');
        }
        break;
        
      case AuthChangeEvent.signedOut:
        debugPrint('[Supabase] 使用者登出');
        router.go('/welcome');
        break;
        
      default:
        debugPrint('[Supabase] 其他 Auth 事件: $event');
        break;
    }
  });
});



class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 啟動登入狀態監聽
    ref.watch(supabaseAuthListenerProvider);

    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      theme: context.lightTheme,
      darkTheme: context.darkTheme,
      themeMode: themeMode.value,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OfflineContainer(child: child);
      },
    );
  }
}

// 🆕 新增這個函數 (放在檔案最後，MainApp class 之後)
Future<void> _initializeDeviceInfo() async {
  try {
    debugPrint('${Constants.tag} Initializing device info...');
    final deviceService = DeviceInfoService.instance;
    await deviceService.collectAndStoreDeviceInfo();
    
    // 📊 Log 設備資訊 (僅 Debug 模式)
    if (kDebugMode) {
      final deviceInfo = deviceService.cachedDeviceInfo;
      debugPrint('${Constants.tag} ✅ Device Info Collected:');
      debugPrint('${Constants.tag} - UUID: ${deviceInfo?['device_uuid']}');
      debugPrint('${Constants.tag} - Model: ${deviceInfo?['device_model']}');
      debugPrint('${Constants.tag} - Platform: ${deviceInfo?['platform']}');
      debugPrint('${Constants.tag} - OS Version: ${deviceInfo?['os_version']}');
      debugPrint('${Constants.tag} - App Version: ${deviceInfo?['app_version']}');
    }
  } catch (e) {
    debugPrint('${Constants.tag} ❌ Failed to initialize device info: $e');
    // 不要讓設備資訊收集失敗影響 App 啟動
  }
}
