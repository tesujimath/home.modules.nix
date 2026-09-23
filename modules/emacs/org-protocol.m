// A minimal org-protocol:// URL handler for macOS.
//
// GNU Emacs on macOS does not register itself as a handler for custom URL
// schemes, so browsers have nothing to hand an org-protocol:// URL to.  This
// is a tiny LSUIElement app which does nothing but declare the scheme and
// forward each URL to emacsclient, as the org-protocol.desktop entry does on
// Linux.  It plays the same role as Scrim (https://github.com/kickingvegas/scrim),
// but is buildable by Nix, unlike Scrim which is Mac App Store only.

#import <AppKit/AppKit.h>

@interface OrgProtocolDelegate : NSObject <NSApplicationDelegate>
@end

@implementation OrgProtocolDelegate

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
  for (NSURL *url in urls) {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@EMACSCLIENT];
    task.arguments = @[ @"--", url.absoluteString ];

    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
      NSLog(@"org-protocol: failed to run %s: %@", EMACSCLIENT, error);
    }
  }
}

@end

int main(void)
{
  @autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    // NSApplication.delegate is a weak reference under ARC, so the delegate
    // needs a strong reference of its own to survive the run loop
    OrgProtocolDelegate *delegate = [[OrgProtocolDelegate alloc] init];
    application.delegate = delegate;
    [application run];
  }

  return 0;
}
