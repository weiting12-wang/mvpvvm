import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// 專責載入/顯示 Rive，保持 UI 層乾淨
class RivePlayer extends StatelessWidget {
  final String assetPath;            // e.g. assets/rive/dog_blink.riv
  final String? artboard;            // 可選
  final String? stateMachineName;    // 可選
  final String? animation;           // 若是 SimpleAnimation

  const RivePlayer({
    super.key,
    required this.assetPath,
    this.artboard,
    this.stateMachineName,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // 若提供 stateMachineName，使用 StateMachine；否則走 simple animation（若有）
    return RiveAnimation.asset(
      assetPath,
      artboard: artboard,
      stateMachines: stateMachineName != null ? [stateMachineName!] : const [],
      animations: (stateMachineName == null && animation != null) ? [animation!] : const [],
      fit: BoxFit.contain,
    );
  }
}
