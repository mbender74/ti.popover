/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2021 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 * 
 * WARNING: This is generated code. Modify at your own risk and without support.
 */

#import <TitaniumKit/TiViewController.h>
#import <TitaniumKit/TiViewProxy.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPopoverBackgroundView.h>


//The iPadPopoverProxy should be seen more as like a window or such, because
//The popover controller will contain the viewController, which has the view.
//If the view had the logic, you get some nasty dependency loops.
@interface TiPopoverProxy : TiProxy <UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, TiProxyObserver> {
  @private
  UIViewController *viewController;
  TiViewProxy *contentViewProxy;

  //We need to hold onto this information for whenever the status bar rotates.
  TiViewProxy *popoverView;
  CGRect popoverRect;
  BOOL animated;
  UIPopoverArrowDirection directions;
  BOOL popoverInitialized;
  BOOL isDismissing;
  NSCondition *closingCondition;
  TiDimension poWidth;
  TiDimension poHeight;
  BOOL deviceRotated;
}

- (void)updatePopover:(NSNotification *)notification;

@end


@interface TiPopoverBackgroundView : UIPopoverBackgroundView
{
    UIVisualEffectView   *popoverBackgroundBlurView;
}

@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;
/**
 Adjust content inset (~ border width)

 @param contentInset The content inset
 */
//+ (void)setContentInset:(CGFloat)contentInset;
+ (UIEdgeInsets)contentViewInsets;
+ (CGFloat)arrowHeight;
+ (CGFloat)arrowBase;


@end
