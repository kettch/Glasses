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

/* This is a view that is the content for VLCStyledVideoWindow.
 * VLCStyledVideoWindow is a borderless window that just display,
 * this view.
 *
 * This view is a subclass of WebView, and its goal is to display
 * a window that is entirely html/css/js based.
 *
 * This makes the window easily styleable, so is its content.
 * Hence VLCStyledVideoWindowView supports multiple style.
 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface VLCStyledVideoWindowView : WebView
{
    BOOL _isFrameLoaded;
    BOOL _isChangingPositionOnFrame;
    NSTrackingArea *_contentTracking;
    float _viewedPosition;
    BOOL _wasPlayingBeforeChangingPosition;
    BOOL _isUserChangingPosition;
}
- (void)setup;

- (void)setKeyWindow:(BOOL)isKeyWindow;
- (void)setMainWindow:(BOOL)isMainWindow;
- (void)setWindowTitle:(NSString *)title;

@property (copy) NSString *ellapsedTime;
@end
