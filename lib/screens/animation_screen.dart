import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

// Diputar tiap kali: (1) baru sukses login pake username/password, ATAU
// (2) tap MASUK dan ternyata sesi lama masih valid. Dua-duanya berakhir
// di sini dulu sebelum ke Dashboard — sama kayak alur di versi web.
class AnimationScreen extends StatefulWidget {
  final Account account;
  final ApiService api;
  const AnimationScreen({super.key, required this.account, required this.api});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/login-animation.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    final v = _controller.value;
    if (v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(account: widget.account, api: widget.api),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          // Tombol SKIP — sama kayak versi web, jaga-jaga videonya kepanjangan.
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: TextButton(
                onPressed: _goToDashboard,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SKIP'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
