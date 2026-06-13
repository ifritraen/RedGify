import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityMonitor extends StatefulWidget {
  final Widget child;

  const InactivityMonitor({super.key, required this.child});

  // Global flag updated by the Reels player to specify if any video is currently playing.
  static bool isAnyVideoPlaying = false;

  @override
  State<InactivityMonitor> createState() => _InactivityMonitorState();
}

class _InactivityMonitorState extends State<InactivityMonitor> {
  Timer? _inactivityTimer;

  // Inactivity timeout duration: 10 minutes
  static const Duration _timeoutDuration = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _onInactivityTimeout);
  }

  void _onInactivityTimeout() {
    // If a video is playing, do not close the app
    if (InactivityMonitor.isAnyVideoPlaying) {
      // Re-schedule timer check
      _resetInactivityTimer();
      return;
    }

    // App is inactive and video is paused: close the app
    _exitApp();
  }

  void _exitApp() {
    SystemNavigator.pop();
    // Immediate fallback exit
    Future.delayed(const Duration(milliseconds: 500), () {
      exit(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      child: widget.child,
    );
  }
}
