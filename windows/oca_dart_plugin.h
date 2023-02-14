#ifndef FLUTTER_PLUGIN_OCA_DART_PLUGIN_H_
#define FLUTTER_PLUGIN_OCA_DART_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace oca_dart {

class OcaDartPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  OcaDartPlugin();

  virtual ~OcaDartPlugin();

  // Disallow copy and assign.
  OcaDartPlugin(const OcaDartPlugin&) = delete;
  OcaDartPlugin& operator=(const OcaDartPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace oca_dart

#endif  // FLUTTER_PLUGIN_OCA_DART_PLUGIN_H_
