#import<Cordova/CDVPlugin.h>
#import<MediaPlayer/MediaPlayer.h>
#import<AVFoundation/AVFoundation.h>

@interface EasyMediaPicker : CDVPlugin <MPMediaPickerControllerDelegate> {
  NSString* callbackId;
}

- (void) pick:(CDVInvokedUrlCommand*)command;

@end