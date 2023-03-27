
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:oca_dart/widget_data.dart';

import 'bridge_generated.dart';
import 'functions.dart';


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
    final bytes = await getZipFromHttp(digest);
    return bytes;
  }

  static Future<WidgetData> performInitialSteps(String path) async{
    final widgetData = initialSteps('x');
    return widgetData;
  }

  static Future<OcaBundle> loadOca({required String json, dynamic hint}) async {
    return await api.loadOca(json: json);
  }



}
