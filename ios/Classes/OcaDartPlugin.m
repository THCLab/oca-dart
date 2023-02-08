#import "OcaDartPlugin.h"
#if __has_include(<oca_dart/oca_dart-Swift.h>)
#import <oca_dart/oca_dart-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "oca_dart-Swift.h"
#endif

@implementation OcaDartPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOcaDartPlugin registerWithRegistrar:registrar];
}
@end
