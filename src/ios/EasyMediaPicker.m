#import"EasyMediaPicker.h"

@implementation EasyMediaPicker

- (void) pick:(CDVInvokedUrlCommand*)command
{
  callbackId = command.callbackId;

  MPMediaPickerController* mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];

  mediaPicker.delegate = self;
  mediaPicker.allowsPickingMultipleItems = YES;
  mediaPicker.showsCloudItems = NO;

  [self.viewController presentViewController:mediaPicker animated:YES completion:nil];
}

- (void) mediaPicker:(MPMediaPickerController*)mediaPicker didPickMediaItems:(MPMediaItemCollection*)mediaItemCollection
{  
  if (mediaItemCollection) {
    NSMutableArray* mediaList = [[NSMutableArray alloc] init];
    NSArray* selectedItems = [mediaItemCollection items];

    // 非同期処理カウント用
    int count = [selectedItems count];
    __block int completed = 0;

    // Documentディレクトリのパスを取得
    NSArray* documentDirArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentDir = [documentDirArray objectAtIndex:0];


    for (MPMediaItem* item in selectedItems) {
      NSString* title = [item valueForProperty:MPMediaItemPropertyTitle];
      NSString* albumTitle = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
      NSString* artist = [item valueForProperty:MPMediaItemPropertyArtist];
      
      // File Manager
      NSFileManager* fileManager = [NSFileManager defaultManager];

      // 作成するディレクトリ
      NSString* path = [documentDir stringByAppendingPathComponent:artist];
      path = [path stringByAppendingPathComponent:albumTitle];

      // ディレクトリの作成
      BOOL result = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

      if (result) {
        // 出力するパス
        NSString* filename = [NSString stringWithFormat:@"%@.m4a",title];
        NSString* outputfilepath = [path stringByAppendingPathComponent:filename];

        if (![fileManager fileExistsAtPath:outputfilepath]) {
          // アセットの作成
          NSURL* url = [item valueForProperty:MPMediaItemPropertyAssetURL];
          if (!url) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This song is protected and cannot be accessed."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            break;
          }
          AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];

          // Exportの準備
          AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
          exporter.outputFileType = @"com.apple.m4a-audio";
          NSURL* exporturl = [NSURL fileURLWithPath:outputfilepath];
          exporter.outputURL = exporturl;

          // Exportの実行
          [exporter exportAsynchronouslyWithCompletionHandler:^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
              NSMutableDictionary* mediaInfo = [[NSMutableDictionary alloc] init];

              [mediaInfo setObject:title forKey:@"title"];
              [mediaInfo setObject:albumTitle forKey:@"albumTitle"];
              [mediaInfo setObject:artist forKey:@"artist"];
              [mediaInfo setObject:outputfilepath forKey:@"path"];
              
              [mediaList addObject:mediaInfo];
            }
            completed++;
          }];
        }
        else { 
          NSMutableDictionary* mediaInfo = [[NSMutableDictionary alloc] init];
          
          [mediaInfo setObject:title forKey:@"title"];
          [mediaInfo setObject:albumTitle forKey:@"albumTitle"];
          [mediaInfo setObject:artist forKey:@"artist"];
          [mediaInfo setObject:outputfilepath forKey:@"path"];
          
          [mediaList addObject:mediaInfo];

          completed++; 
        }
      }
      else { completed++; }

      if (completed == count) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:mediaList];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
      }
    }

    if (completed != count) {
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"ExportSession was not complted"];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
  }
  
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) mediaPickerDidCancel:(MPMediaPickerController*)mediaPicker
{
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Selection cancelled"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end