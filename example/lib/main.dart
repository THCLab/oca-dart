import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oca_dart/bridge_generated.dart';
import 'package:oca_dart/functions.dart';
import 'package:oca_dart/oca_dart.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:oca_dart/widget_data.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  WidgetData widgetData = await OcaDartPlugin.getWidgetData(await rootBundle.loadString('assets/rightjson.json'));
  runApp(MyApp(widgetData: widgetData));
}

class MyApp extends StatefulWidget {
  final WidgetData widgetData;
  const MyApp({super.key, required this.widgetData, /*required this.bundle*/ /*, required this.registry*/});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: OcaDartPlugin.renderWidgetData(widget.widgetData, context)
        ),
      ),
    );
  }
}

