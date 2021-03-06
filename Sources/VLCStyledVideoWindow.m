/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors: Pierre d'Herbemont
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCStyledVideoWindow.h"
#import "VLCStyledVideoWindowController.h"
#import "VLCStyledVideoWindowView.h"
#import "NSScreen_Additions.h"

//#define DEBUG_STYLED_WINDOW

static inline BOOL debugStyledWindow(void)
{
    return [VLCStyledVideoWindow debugStyledWindow];
}

@implementation VLCStyledVideoWindow
+ (BOOL)debugStyledWindow
{
#ifdef DEBUG_STYLED_WINDOW
    return YES;
#endif
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugStyledWindow"];    
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (!debugStyledWindow())
        aStyle = NSBorderlessWindowMask;
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (!self)
        return nil;
    
    [self setMovableByWindowBackground:YES];
    if (!debugStyledWindow()) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    [self setHasShadow:NO];
    [self setAcceptsMouseMovedEvents:YES];
    [self setIgnoresMouseEvents:NO];
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(NSInteger)otherWin
{
    [super orderWindow:place relativeTo:otherWin];

    // There is a bug in Cocoa here, our child windows
    // won't appear if we don't do this.
    // XXX - file a bug report.
    // XXX - we only support below child window
    for (NSWindow *child in [self childWindows])
        [child orderWindow:NSWindowBelow relativeTo:[self windowNumber]];
}

- (void)orderFront:(id)sender
{
    // Don't orderFront the window if the frame is not loaded and that we plan
    // to go fullscreen directly. Because we need to wait for the styled window
    // to be ready (see -[VLCStyledWindowView frameDidLoad]) we have to
    // ensure we won't go on screen prematuraly
    BOOL shouldGoFullscreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"StartPlaybackInFullscreen"];
    if (shouldGoFullscreen && ![[[self windowController] styledWindowView] hasLoadedAFirstFrame])
        return;

    [super orderFront:sender];
}

// Because we are borderless, a certain number of thing don't work out of the box.
// For instance the NSDocument patterns don't apply, we have to reimplement them.
- (void)performClose:(id)sender
{
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForWindow:self];
    [doc close];
}

- (void)performZoom:(id)sender
{
    [self zoom:nil];
    [NSApp updateWindowsItem:self];
}

- (void)performMiniaturize:(id)sender
{
    [self miniaturize:nil];
    [NSApp updateWindowsItem:self];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    SEL sel = [anItem action];
    if (sel == @selector(performClose:))
        return YES;
    if (sel == @selector(performZoom:))
        return YES;
    if (sel == @selector(performMiniaturize:))
        return YES;
    return [super validateUserInterfaceItem:anItem];
}

#ifdef SUPPORT_VIDEO_BELOW_CONTENT
- (void)setAlphaValue:(CGFloat)alpha
{
    [super setAlphaValue:alpha];
    if ([_delegate respondsToSelector:@selector(window:didChangeAlphaValue:)])
        [_delegate window:self didChangeAlphaValue:alpha];
}
#endif

#pragma mark -
#pragma mark Javascript bindings
/* Javascript bindings: We are not necessarily respecting Cocoa naming scheme convention. That's an exception */

- (void)performClose
{
    [self performClose:self];
}

- (void)zoom
{
    [self performZoom:nil];
}

- (void)miniaturize
{
    [self performMiniaturize:nil];
}

- (float)frameOriginX
{
    return [self frame].origin.x;
}

- (float)frameOriginY
{
    return [self frame].origin.y;
}

- (void)setFrameOrigin:(float)x :(float)y
{
    // Make sure we don't
    // FIXME: Potentially slow.
    NSScreen *screen = [self screen];
    if ([screen isMainScreen]) {
        NSRect rect = [[[self windowController] styledWindowView] representedWindowRect];
        if (!NSIsEmptyRect(rect)) {
            CGFloat screenHeight = [screen frame].size.height;
            CGFloat windowHeight = [self frame].size.height;
            
            if (screenHeight - y - windowHeight + rect.origin.y < 22 /* MenuBar height. FIXME: a define? */)
                y = screenHeight + rect.origin.y - (22 + windowHeight);                    
        }
    }
    [self setFrameOrigin:NSMakePoint(x, y)];
}

- (float)frameSizeHeight
{
    return [self frame].size.height;
}

- (float)frameSizeWidth
{
    return [self frame].size.width;
}

- (void)willStartLiveResize
{
    [[self contentView] viewWillStartLiveResize];
}

- (void)didEndLiveResize
{
    [[self contentView] viewDidEndLiveResize];
}

- (void)setFrame:(float)x :(float)y :(float)width :(float)height
{
    NSRect frame;
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.height = height;
    frame.size.width = width;
    [self setFrame:frame display:YES];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(performClose))
        return NO;
    if (sel == @selector(zoom))
        return NO;
    if (sel == @selector(miniaturize))
        return NO;
    if (sel == @selector(setFrameOrigin::))
        return NO;
    if (sel == @selector(frameOriginX))
        return NO;
    if (sel == @selector(frameOriginY))
        return NO;
    if (sel == @selector(setFrame::::))
        return NO;
    if (sel == @selector(frameSizeHeight))
        return NO;
    if (sel == @selector(frameSizeWidth))
        return NO;
    if (sel == @selector(willStartLiveResize))
        return NO;
    if (sel == @selector(didEndLiveResize))
        return NO;
    
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
