
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

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

  static Future<WidgetData> performInitialSteps(String path) async{
    final widgetData = f.initialSteps('x');
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

  static Future<String> getFormFromAttributes (OcaMap map){
    // String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "label":"scsv1", "children": [{"type":"column", "label":"column1", "children":[]}]}] }';
    // Map<String, dynamic> jsonMap = json.decode(jsonOverlay);
    // print(jsonMap['elements'][0]['children'][0]);
    return f.getFormFromAttributes(map);
  }



}
