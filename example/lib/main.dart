import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oca_dart/oca_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _ocaDartPlugin = OcaDart();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }
  
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _ocaDartPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
    print(await _ocaDartPlugin.getZipFromHttp('EVRvOZAqbhpFJFoVc5TdPuJ49NbE0wtaSVVNZFPtt9B8'));
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
