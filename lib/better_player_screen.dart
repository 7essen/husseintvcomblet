import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';

class BetterPlayerScreen extends StatefulWidget {
  final String streamUrl;

  BetterPlayerScreen({required this.streamUrl});

  @override
  _BetterPlayerScreenState createState() => _BetterPlayerScreenState();
}

class _BetterPlayerScreenState extends State<BetterPlayerScreen> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: true,
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.streamUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("بث مباشر"),
      ),
      body: Center(
        child: BetterPlayer(
          controller: _betterPlayerController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }
}
