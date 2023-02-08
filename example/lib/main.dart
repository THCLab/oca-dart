import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oca_dart/functions.dart';
import 'package:oca_dart/oca_dart.dart';
import 'package:oca_dart/widget_data.dart';

void main() async{
  final _ocaDartPlugin = OcaDart();
  WidgetData widgetData = await _ocaDartPlugin.initialSteps();
  runApp(MyApp(widgetData: widgetData,));
}

class MyApp extends StatefulWidget {
  final WidgetData widgetData;
  const MyApp({super.key, required this.widgetData});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _ocaDartPlugin = OcaDart();
  late WidgetData widgetData;

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
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: getWidgetFromJSON(widget.widgetData, context) ?? Container()
        ),
      ),
    );
  }
}
