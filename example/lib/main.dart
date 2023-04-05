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
  WidgetData firstWidgetData = await OcaDartPlugin.performInitialSteps();
  final OcaBundle bundle = await OcaDartPlugin.loadOca(json: await rootBundle.loadString('assets/rightjson.json'));
  final String ocaBundle = await bundle.toJson();
  final ocaMap = jsonDecode(ocaBundle);

  var jsonData = await OcaDartPlugin.getFormFromAttributes(ocaMap, firstWidgetData.registry);
  WidgetData widgetData = WidgetData(registry: firstWidgetData.registry, jsonData: jsonData);
  runApp(MyApp(widgetData: widgetData,bundle: bundle));
}

class MyApp extends StatefulWidget {
  final WidgetData widgetData;
  //final JsonWidgetRegistry registry;
  final OcaBundle bundle;
  const MyApp({super.key, required this.widgetData, required this.bundle /*, required this.registry*/});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //late WidgetData widgetData;
  String widgetJson = "";
  Map<String, dynamic> jsonMap = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.widgetData.registry.values);
    var w = JsonWidgetData.fromDynamic(widget.widgetData.jsonData["elements"][0], registry: widget.widgetData.registry);
    print(w);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: w?.build(context: context),
          //child: getWidgetFromJSON(widget.widgetData, context) ?? Container()
        ),
      ),
    );
  }
}

