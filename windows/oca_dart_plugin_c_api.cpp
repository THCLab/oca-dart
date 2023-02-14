#include "include/oca_dart/oca_dart_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "oca_dart_plugin.h"

void OcaDartPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  oca_dart::OcaDartPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
