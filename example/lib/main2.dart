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

import 'cinemaWidget.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  var registry = JsonWidgetRegistry();

  registry.registerFunctions({
    'addDynamically': ({args, required registry}) => () {
      if(registry.getValue("items").length < args?[1]){
        args?[0]();
      }
      print(registry.values);
    },
    'removeDynamically': ({args, required registry}) => () {
      if(registry.getValue("items").length > 1){
        args?[0]();
      }
      print(registry.values);
    },
  });


  var navigatorKey = GlobalKey<NavigatorState>();
  var templateData = await getTemplateData('assets/arraytest.json');
  runApp(MyApp(registry: registry, navigatorKey: navigatorKey,mapData: templateData,));
}

Future<Map<dynamic, dynamic>> getTemplateData(String path) async{
  final String templateString = await rootBundle.loadString(path);
  var templateData = await json.decode(templateString);
  return templateData;
}

class MyApp extends StatelessWidget {
  final registry;
  final navigatorKey;
  final mapData;

  const MyApp({Key? key, required this.registry, required this.navigatorKey, required this.mapData}) : super(key: key);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => MyHomePage(registry: registry, jsonData: mapData,),
      },
      navigatorKey: navigatorKey,
      //home:MyHomePage(registry: registry, jsonData: mapData,),
    );
  }

}

class MyHomePage extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final JsonWidgetRegistry registry;
  const MyHomePage({required this.jsonData, required this.registry, Key? key,}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late var _data;
  late var _registry;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry;
    _data = JsonWidgetData.fromDynamic(widget.jsonData, registry: _registry);
  }

  @override
  Widget build(BuildContext context) {
    _registry.setValue('myContext', context);
    print(_registry.getValue('myContext'));
    return Scaffold(
      appBar: AppBar(
        title: const Text("My App"),
      ),
      body: Center(
        child: CinemaWidget(registry: _registry, jsonData: widget.jsonData,),
      ),
    );
  }
}