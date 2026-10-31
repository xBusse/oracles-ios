// UIKit glue for the iOS app: the ROM picker, the Documents folder and haptics. Built with ARC.
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "platform/ios_glue.h"

// The topmost view controller of SDL's window, which is what a picker must be presented from.
static UIViewController *top_controller(void) {
  UIWindow *window = nil;
  int count = 0;
  SDL_Window **windows = SDL_GetWindows(&count);
  if (windows && count > 0)
    window = (__bridge UIWindow *)SDL_GetPointerProperty(SDL_GetWindowProperties(windows[0]),
                                                         SDL_PROP_WINDOW_UIKIT_WINDOW_POINTER, NULL);
  SDL_free(windows);
  if (!window) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (![scene isKindOfClass:UIWindowScene.class]) continue;
      for (UIWindow *w in ((UIWindowScene *)scene).windows)
        if (w.isKeyWindow) { window = w; break; }
      if (window) break;
    }
  }
  UIViewController *vc = window.rootViewController;
  while (vc.presentedViewController) vc = vc.presentedViewController;
  return vc;
}

@interface OraclesPickerDelegate : NSObject <UIDocumentPickerDelegate>
@property(nonatomic) SDL_DialogFileCallback callback;
@property(nonatomic) void *userdata;
@property(nonatomic) BOOL done;
@end

@implementation OraclesPickerDelegate
- (void)finish:(NSURL *)url {
  if (self.done) return;
  self.done = YES;
  if (!url) { self.callback(self.userdata, NULL, -1); return; }
  // asCopy:YES puts the file in our sandbox, but a security scope may still apply
  BOOL scoped = [url startAccessingSecurityScopedResource];
  const char *path = url.fileSystemRepresentation;
  const char *const list[] = {path, NULL};
  self.callback(self.userdata, list, -1);
  if (scoped) [url stopAccessingSecurityScopedResource];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
  [self finish:urls.firstObject];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
  [self finish:nil];
}
@end

static OraclesPickerDelegate *picker_delegate;   // UIDocumentPicker holds its delegate weakly

void ios_show_open_file_dialog(SDL_DialogFileCallback cb, void *userdata) {
  @autoreleasepool {
    UIViewController *top = top_controller();
    if (!top) { cb(userdata, NULL, -1); return; }
    picker_delegate = [OraclesPickerDelegate new];
    picker_delegate.callback = cb;
    picker_delegate.userdata = userdata;
    // .gbc/.gb have no system type, so offer any file; extract() explains a wrong pick
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ UTTypeItem ] asCopy:YES];
    picker.delegate = picker_delegate;
    picker.allowsMultipleSelection = NO;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [top presentViewController:picker animated:YES completion:nil];
  }
}

bool ios_documents_dir(char *out, size_t size) {
  @autoreleasepool {
    NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    if (!docs) return false;
    int n = snprintf(out, size, "%s/", docs.fileSystemRepresentation);
    return n > 0 && (size_t)n < size;
  }
}

static UIImpactFeedbackGenerator *haptic_gen;   // touched on the main thread only

void ios_haptic_tick(void) {
  void (^tap)(void) = ^{
    if (!haptic_gen) haptic_gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic_gen impactOccurred];
    [haptic_gen prepare];
  };
  if (NSThread.isMainThread) tap();
  else dispatch_async(dispatch_get_main_queue(), tap);
}
