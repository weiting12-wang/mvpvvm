import 'dart:io';

import 'package:flutter/material.dart';

import 'sign_in_with_apple.dart';
//import 'sign_in_with_google.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key});

  @override
  Widget build(BuildContext context) {
        // 暫時不顯示社交登入
    return const SizedBox.shrink();
    /*
    final isIOS = Platform.isIOS;
    return Row(
      children: [
        Expanded(
          child: SignInWithGoogle(),
        ),
        if (isIOS) const SizedBox(width: 16),
        if (isIOS)
          Expanded(
            child: SignInWithApple(),
          ),
      ],
    );*/
  }
}
