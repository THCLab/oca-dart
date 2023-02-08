import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'oca_dart_method_channel.dart';

abstract class OcaDartPlatform extends PlatformInterface {
  /// Constructs a OcaDartPlatform.
  OcaDartPlatform() : super(token: _token);

  static final Object _token = Object();

  static OcaDartPlatform _instance = MethodChannelOcaDart();

  /// The default instance of [OcaDartPlatform] to use.
  ///
  /// Defaults to [MethodChannelOcaDart].
  static OcaDartPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OcaDartPlatform] when
  /// they register themselves.
  static set instance(OcaDartPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Uint8List> zipFromHttp(String digest) {
    throw UnimplementedError('getZipFromHttp() has not been implemented.');
  }
}
