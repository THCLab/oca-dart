import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oca_dart/widget_data.dart';

import 'functions.dart';
import 'oca_dart_platform_interface.dart';

/// An implementation of [OcaDartPlatform] that uses method channels.
class MethodChannelOcaDart extends OcaDartPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('oca_dart');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Uint8List> zipFromHttp(String digest) async{
    final bytes = await getZipFromHttp(digest);
    return bytes;
  }

  @override
  Future<WidgetData> performInitialSteps(String path) async{
    final widgetData = initialSteps('x');
    return widgetData;
  }
}
