import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/authentication/ui/otp_screen.dart';
import '../features/authentication/ui/sign_in_screen.dart';
import '../features/authentication/ui/welcome_screen.dart';
import '../features/authentication/ui/forgot_password_screen.dart'; // 🆕
import '../features/authentication/ui/reset_password_screen.dart';  // 🆕
import '../features/main/ui/main_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/premium/ui/premium_screen.dart';
import '../features/profile/model/profile.dart';
import '../features/profile/ui/account_info_screen.dart';
import '../features/profile/ui/appearances_screen.dart';
import '../features/profile/ui/languages_screen.dart';
import '../features/onboarding/ui/birthday_input_screen.dart';
import 'routes.dart';


enum SlideDirection {
  right,
  left,
  up,
  down,
}

extension GoRouterStateExtension on GoRouterState {
  SlideRouteTransition slidePage(
    Widget child, {
    SlideDirection direction = SlideDirection.left,
  }) {
    return SlideRouteTransition(
      key: pageKey,
      child: child,
      direction: direction,
    );
  }
}

class SlideRouteTransition extends CustomTransitionPage<void> {
  SlideRouteTransition({
    required super.key,
    required super.child,
    SlideDirection direction = SlideDirection.left,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            Offset begin;
            switch (direction) {
              case SlideDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }
            final tween = Tween(begin: begin, end: Offset.zero);
            final offsetAnimation = tween.animate(curve);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => state.slidePage(const SplashScreen()),
    ),
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) => state.slidePage(const WelcomeScreen()),
    ),
    GoRoute(
      path: Routes.login,
      pageBuilder: (context, state) => state.slidePage(const SignInScreen()),
    ),
    GoRoute(
        path: Routes.otp,
        pageBuilder: (context, state) {
          final map = state.extra as Map?;
          return state.slidePage(
            OtpScreen(
              email: map?['email'],
              isRegister: map?['isRegister'],
              password: map?['password'], // ✅ 把 password 一起傳進去
            ),
          );
        }),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) =>
          state.slidePage(const OnboardingScreen()),
    ),
    GoRoute(
      path: Routes.main,
      pageBuilder: (context, state) => state.slidePage(const MainScreen()),
    ),
    GoRoute(
      path: Routes.accountInformation,
      pageBuilder: (context, state) {
        final profile = state.extra as Profile;
        return state.slidePage(AccountInfoScreen(originalProfile: profile));
      },
    ),
    GoRoute(
      path: Routes.appearances,
      pageBuilder: (context, state) =>
          state.slidePage(const AppearancesScreen()),
    ),
    GoRoute(
      path: Routes.languages,
      pageBuilder: (context, state) => state.slidePage(const LanguagesScreen()),
    ),
    GoRoute(
      path: Routes.premium,
      pageBuilder: (context, state) => state.slidePage(
        const PremiumScreen(),
        direction: SlideDirection.up,
      ),
    ),
    GoRoute(
      path: Routes.birthdayInput,
      pageBuilder: (context, state) => state.slidePage(const BirthdayInputScreen()
      ),
    ),
    // 🆕 新增忘記密碼頁面路由
    GoRoute(
      path: Routes.forgotPassword,
      pageBuilder: (context, state) {
        final map = state.extra as Map<String, dynamic>?;
        return state.slidePage(
          ForgotPasswordScreen(
            prefillEmail: map?['email'] as String?, // 預填 email
          ),
        );
      },
    ),

// 🆕 修復重設密碼頁面路由 (Deep Link)
    GoRoute(
      path: Routes.resetPassword,
      pageBuilder: (context, state) {
        // 🆕 更好的參數解析邏輯
        String? token;
        String? accessToken;
        
        // 從 query parameters 取得
        token = state.uri.queryParameters['token'];
        accessToken = state.uri.queryParameters['access_token'];
        
        // 🆕 如果從 main.dart 傳來的 URL 格式，直接解析
        if (accessToken == null) {
          // 檢查是否是從 main.dart 的跳轉
          final uri = state.uri;
          if (uri.query.contains('access_token=')) {
            final params = Uri.splitQueryString(uri.query);
            accessToken = params['access_token'];
          }
        }
        
        // 🆕 如果還是沒有，嘗試從當前 Supabase session 取得
        if (accessToken == null) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            accessToken = session.accessToken;
            token = 'supabase_session'; // 標記這是從 session 取得的
          }
        }
        
        debugPrint('[Router] Reset Password Route');
        debugPrint('[Router] - token: $token');
        debugPrint('[Router] - accessToken: ${accessToken?.substring(0, 20)}...');
        debugPrint('[Router] - Full URI: ${state.uri}');
            
        return state.slidePage(
          ResetPasswordScreen(
            token: token,
            accessToken: accessToken,
          ),
        );
      },
    ), 
  ],
);
