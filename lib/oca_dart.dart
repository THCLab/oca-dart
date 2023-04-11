
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:oca_dart/widget_data.dart';

import 'bridge_generated.dart';
import 'functions.dart' as f;


class OcaDartPlugin {
  static const base = 'ocadart';
  static final path = Platform.isWindows? '$base.dll' : 'lib$base.so';
  static late final dylib = Platform.isIOS
      ? DynamicLibrary.process()
      : Platform.isMacOS
      ? DynamicLibrary.executable()
      : DynamicLibrary.open(path);
  static late final api = OcaDartImpl(dylib);


  static Future<Uint8List> zipFromHttp(String digest) async{
    final bytes = await f.getZipFromHttp(digest);
    return bytes;
  }

  static Future<Uint8List> getJsonFromHttp(String url) async{
    final bytes = await f.getJsonFromHttp(url);
    return bytes;
  }

  static Future<WidgetData> performInitialSteps() async{
    final widgetData = f.initialSteps();
    return widgetData;
  }

  static Future<OcaBundle> loadOca({required String json, dynamic hint}) async {
    return await api.loadOca(json: json);
  }

  static Future<List<String>> getKeysMethodOcaMap(
      {required OcaMap that, dynamic hint}) async {
    return await api.getKeysMethodOcaMap(that: that);
  }

  static Future<String?> getMethodOcaMap(
      {required OcaMap that, required String key, dynamic hint}) async {
    return await api.getMethodOcaMap(that: that, key: key);
  }

  static Future<Map<String, dynamic>> getFormFromAttributes (Map<String, dynamic> map, JsonWidgetRegistry registry){
    return f.getFormFromAttributes(map, registry);
  }

  static Map<String, dynamic> returnObtainedValues(){
    return f.returnObtainedValues();
  }

  static Widget getWidgetFromJson(WidgetData data, BuildContext context){
    return f.getWidgetFromJSON(data, context);
  }

  static Stream returnValidationStream(){
    return f.returnValidationStream();
  }

  static String returnSchemaId(WidgetData widgetData){
    return f.returnSchemaId(widgetData);
  }

  static Widget getSubmittedWidgetFromJSON (Map<String, dynamic> map, BuildContext context) {
    return f.getSubmittedWidgetFromJSON(map, context);
  }

  static Map<String, dynamic> renderFilledForm(Map<String, dynamic> map, Map<String, String> values){
    return f.renderFilledForm(map, values);
  }



}
