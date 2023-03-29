import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oca_dart/bridge_generated.dart';
import 'package:oca_dart/functions.dart';
import 'package:oca_dart/oca_dart.dart';
import 'package:oca_dart/widget_data.dart';

void main() async{
  //WidgetData widgetData = await OcaDartPlugin.performInitialSteps('x');
  //print(widgetData.registry.values);
  WidgetsFlutterBinding.ensureInitialized();
  final OcaBundle bundle = await OcaDartPlugin.loadOca(json: await rootBundle.loadString('assets/rightjson.json'));
  runApp(MyApp(/*widgetData: widgetData,*/ bundle: bundle ,));
}

class MyApp extends StatefulWidget {
  //final WidgetData widgetData;
  final OcaBundle bundle;
  const MyApp({super.key, /*required this.widgetData,*/ required this.bundle});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //late WidgetData widgetData;
  String widgetJson = "";

  @override
  void initState() {
    super.initState();
    testMethod();
  }

  Future<void> testMethod() async {
    print(widget.bundle);
    var captureBase = await widget.bundle.captureBase();
    var overlays = await widget.bundle.overlays();
    for( var overlay in overlays){
      var x = await overlay.field0;

      print(overlay.field0);
    }
    var attrs = await captureBase.attributes();
    print(OcaDartPlugin.getFormFromAttributes(attrs));
    var y = await OcaDartPlugin.getKeysMethodOcaMap(that: attrs);
    var z = await OcaDartPlugin.getMethodOcaMap(that: attrs, key: "status");
    print(y);
    print(z);
    var assigner = await attrs.get(key: 'assigner');
    print(assigner.runtimeType);
  }

  @override
  Widget build(BuildContext context) {

    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          //child: getWidgetFromJSON(widget.widgetData, context) ?? Container()
        ),
      ),
    );
  }
}
