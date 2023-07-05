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
  WidgetData widgetData = await OcaDartPlugin.getWidgetData(await rootBundle.loadString('assets/version03new.json'), "Idabiugeaiuy8728637gea9aghewe");
  runApp(MaterialApp(home: MyApp(widgetData: widgetData)));
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
    return Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: OcaDartPlugin.renderWidgetData(widget.widgetData, context)
              ),
              TextButton(
                onPressed: () async{
                  print(widget.widgetData.jsonData);
                  var theMap = OcaDartPlugin.getFilledForm(jsonDecode(await rootBundle.loadString('assets/version03.json')), OcaDartPlugin.returnObtainedValues());
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SubmittedData(submittedForm: theMap)));
                },
                child: Text("render")
              )
            ],
          ),
        ),
    );
  }
}

class SubmittedData extends StatefulWidget {
  final Map<String, dynamic> submittedForm;
  const SubmittedData({Key? key, required this.submittedForm}) : super(key: key);

  @override
  State<SubmittedData> createState() => _SubmittedDataState();
}

class _SubmittedDataState extends State<SubmittedData> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
                child: OcaDartPlugin.renderFilledForm(widget.submittedForm, context)
            ),
          ],
        ),
      ),
    );
  }
}


