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
  //WidgetData widgetData = await OcaDartPlugin.performInitialSteps();
  //print(widgetData.registry.values);
  // WidgetsFlutterBinding.ensureInitialized();
  // var registry = JsonWidgetRegistry();
  // var navigatorKey = GlobalKey<NavigatorState>();
  // registry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  // registry.registerFunction('returnLabel', ({args, required registry}) {
  //   //print("${args![0]}-${args[1]}");
  //   ////print(registry.values);
  //   //print(registry.debugLabel);
  //   return registry.getValue("${args![0]}-${args[1]}");
  // } );
  // registry.registerFunction('returnLanguages', ({args, required registry}) {
  //   return registry.getValue("languages");
  // } );
  // registry.registerFunction('returnValues', ({args, required registry}) {
  //   Map<String, dynamic> values = {};
  //   Map<String, dynamic> registryValues = registry.values;
  //   for(String key in registryValues.keys){
  //     print(key);
  //     if(key.startsWith("edit")){
  //       values[registryValues[key]] = registryValues[key];
  //     }
  //   }
  //   registry.setValue("obtainedValues", values);
  //   print(registry.getValue("obtainedValues"));
  // } );
  // registry.registerFunctions({
  //   show_date_picker_fun.key: show_date_picker_fun.body,
  //   show_time_picker_fun.key: show_time_picker_fun.body,
  //   show_file_picker_fun.key: show_file_picker_fun.body,
  //   'validateForm': ({args, required registry}) => () {
  //     print(registry.values);
  //     final BuildContext context = registry.getValue(args![0]);
  //     final valid = Form.of(context).validate();
  //     registry.setValue('form_validation', valid);
  //     if(valid){
  //       registry.navigatorKey?.currentState!.pushNamed('/second');
  //       //Navigator.pushNamed(navigatorKey.currentContext!, '/second');
  //     }
  //   },
  // });
  // registry.registerFunction('nooped', ({args, required registry}) {
  //   print(registry.getValue("language"));
  // } );
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
    //testMethod();
  }

  Future<void> testMethod() async {
    //print(widget.bundle);
    var captureBase = await widget.bundle.captureBase();
    var overlays = await widget.bundle.overlays();
    for(OcaOverlay overlay in overlays){
      var x = await overlay.field0;
      //var p = overlay[""];

      //print(overlay.field0);
    }
    var attrs = await captureBase.attributes();
    //print(await OcaDartPlugin.getFormFromAttributes(attrs));
    var y = await OcaDartPlugin.getKeysMethodOcaMap(that: attrs);
    var z = await OcaDartPlugin.getMethodOcaMap(that: attrs, key: "status");
    print(y);
    print(z);

    var assigner = await attrs.get(key: 'assigner');
    print(assigner.runtimeType);
    //jsonMap = await OcaDartPlugin.getFormFromAttributes(attrs);
    //return await OcaDartPlugin.getFormFromAttributes(attrs);
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

