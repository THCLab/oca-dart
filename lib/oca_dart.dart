
import 'dart:typed_data';

import 'oca_dart_platform_interface.dart';

class OcaDart {
  Future<String?> getPlatformVersion() {
    return OcaDartPlatform.instance.getPlatformVersion();
  }

  Future<Uint8List> getZipFromHttp(String digest) async {
    return OcaDartPlatform.instance.zipFromHttp(digest);
  }
}
