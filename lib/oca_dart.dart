
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:oca_dart/widget_data.dart';

import 'bridge_generated.dart';
import 'functions.dart' as f;

///Main plugin class containing the methods to render the form from provided OCA
class OcaDartPlugin {
  static const base = 'ocadart';
  static final path = Platform.isWindows? '$base.dll' : 'lib$base.so';
  static late final dylib = Platform.isIOS
      ? DynamicLibrary.process()
      : Platform.isMacOS
      ? DynamicLibrary.executable()
      : DynamicLibrary.open(path);
  static late final api = OcaDartImpl(dylib);


  ///Returns bytes of zip file downloaded from colossi network repository under given digest.
  static Future<Uint8List> zipFromHttp(String digest) async{
    final bytes = await f.getZipFromHttp(digest);
    return bytes;
  }

  ///Returns bytes of JSON file downloaded from given url.
  static Future<Uint8List> getJsonFromHttp(String url) async{
    final bytes = await f.getJsonFromHttp(url);
    return bytes;
  }

  ///Returns the OcaBundle from the given json String.
  static Future<OcaBundle> loadOca({required String json, dynamic hint}) async {
    return await api.loadOca(json: json);
  }
  //
  // static Future<List<String>> getKeysMethodOcaMap(
  //     {required OcaMap that, dynamic hint}) async {
  //   return await api.getKeysMethodOcaMap(that: that);
  // }
  //
  // static Future<String?> getMethodOcaMap(
  //     {required OcaMap that, required String key, dynamic hint}) async {
  //   return await api.getMethodOcaMap(that: that, key: key);
  // }
  //
  // static Future<Map<String, dynamic>> getFormFromAttributes (Map<String, dynamic> map, JsonWidgetRegistry registry){
  //   return f.getFormFromAttributes(map, registry);
  // }

  ///Does all the necessary steps to create a form widget to render. This includes
  ///performing initial steps related to json_dynamic_widget, loading the OCA
  ///from json and preparing a form Widget by parsing overlays. Returns a `WidgetData` object,
  /// ready to be consumed by another function, `renderWidgetData`.
  static Future<WidgetData> getWidgetData (String json) async{
    return f.getWidgetData(json);
  }

  ///Returns a widget from provided `WidgetData` object. `getWidgetData` needs to be
  ///called first in order to obtain the object. Call `build` on the result of this
  ///function to build a widget containing form from the OCA.
  static Widget? renderWidgetData(WidgetData widgetData, BuildContext context){
    return f.renderWidgetData(widgetData, context);
  }

  ///Returns the map of the values collected from the form.
  static Map<String, dynamic> returnObtainedValues(){
    return f.returnObtainedValues();
  }

  ///Returns a stream to listen to. It is necessary to know, whether a form
  ///has been submitted.
  static Stream returnValidationStream(){
    return f.returnValidationStream();
  }

  ///Returns the ID of the OCA schema, basing on which the form or its result
  ///is rendered.
  static String returnSchemaId(WidgetData widgetData){
    return f.returnSchemaId(widgetData);
  }

  ///Returns a widget from provided Map object. `getFilledForm` needs to be
  ///called first in order to obtain the object. Builds a widget containing submitted form from the OCA.
  static Widget renderFilledForm (Map<String, dynamic> map, BuildContext context) {
    return f.renderFilledForm(map, context);
  }

  ///Similarly to preparing a form to fill, this function does all the necessary steps
  ///to create a submitted form widget. It mostly parses the overlays back and
  ///focuses on obtained values from the form to render.
  static Map<String, dynamic> getFilledForm(Map<String, dynamic> map, Map<String, dynamic> values){
    return f.getFilledForm(map, values);
  }





}
