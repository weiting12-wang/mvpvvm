import 'package:flutter/material.dart';
import '../model/rive_loader.dart';

class RivePlayerScreen extends StatelessWidget {
  final String title;
  final String assetPath;
  final String? artboard;
  final String? stateMachineName;
  final String? animation;

  const RivePlayerScreen({
    super.key,
    required this.title,
    required this.assetPath,
    this.artboard,
    this.stateMachineName,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: RivePlayer(
          assetPath: assetPath,
          artboard: artboard,
          stateMachineName: stateMachineName,
          animation: animation,
        ),
      ),
    );
  }
}
