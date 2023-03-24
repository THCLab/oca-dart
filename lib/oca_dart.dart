
import 'dart:typed_data';

import 'package:oca_dart/widget_data.dart';

import 'oca_dart_platform_interface.dart';

class OcaDart {
  Future<String?> getPlatformVersion() {
    return OcaDartPlatform.instance.getPlatformVersion();
  }

  Future<WidgetData> initialSteps() {
    return OcaDartPlatform.instance.performInitialSteps('x');
  }


}
