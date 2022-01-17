/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2021 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 * 
 * WARNING: This is generated code. Modify at your own risk and without support.
 *
 *
 * CODE taken form Titaniim SDK
 */

#import "TiPopoverProxy.h"
#import <TitaniumKit/TiApp.h>
#import <TitaniumKit/TiUtils.h>
#import <TitaniumKit/TiWindowProxy.h>
#import <libkern/OSAtomic.h>

#ifdef USE_TI_UITABLEVIEW
#import "TiUITableViewRowProxy.h"
#endif

static NSCondition *tiPopOverCondition;
static BOOL tiCurrentlyDisplaying = NO;
TiPopoverProxy *currentTiPopover;

UIVisualEffectView *popoverBlurEffectView;
UIView *popoverDarkenBackgroundView;
CGSize TiPopoverContentSize;

@implementation TiPopoverProxy

static NSArray *popoverSequence;

#pragma mark Internal

- (NSArray *)keySequence
{
  if (popoverSequence == nil) {
      //popoverSequence = [[NSArray arrayWithObjects:@"contentView", @"width", @"height", nil] retain];
      popoverSequence = [[NSArray arrayWithObjects:@"contentView", nil] retain];
  }
  return popoverSequence;
}
#pragma mark Setup

- (id)init
{
  if (self = [super init]) {
    closingCondition = [[NSCondition alloc] init];
    directions = UIPopoverArrowDirectionUp;
    poWidth = TiDimensionUndefined;
    poHeight = TiDimensionUndefined;
  }
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceRotated:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
  return self;
}

- (void)dealloc
{
  if (currentTiPopover == self) {
    //This shouldn't happen because we clear it on hide.
    currentTiPopover = nil;
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [viewController.view removeObserver:self forKeyPath:@"safeAreaInsets"];
    RELEASE_TO_NIL(viewController);
    RELEASE_TO_NIL(popoverView);
    RELEASE_TO_NIL(closingCondition);
    RELEASE_TO_NIL(contentViewProxy);
    RELEASE_TO_NIL(popoverBlurEffectView);
    RELEASE_TO_NIL(popoverDarkenBackgroundView);
    [super dealloc];
}

#pragma mark Public API
- (NSString *)apiName
{
    return @"Ti.UI.Popover";
}

#pragma mark Public Constants

- (UIPopoverArrowDirection)arrowDirection
{
  return directions;
}

- (void)setArrowDirection:(id)args
{
  if (popoverInitialized) {
    DebugLog(@"[ERROR] Arrow Directions can only be set before showing the popover.") return;
  }

  ENSURE_SINGLE_ARG(args, NSNumber)
  UIPopoverArrowDirection theDirection = [TiUtils intValue:args];
  directions = theDirection;
    
}

- (void)setHeight:(id)value
{
    poHeight = TiDimensionUndefined;

}
- (void)setWidth:(id)value
{
    poWidth = TiDimensionUndefined;

}


- (void)setContentView:(id)value
{
  if (popoverInitialized) {
    DebugLog(@"[ERROR] Changing contentView when the popover is showing is not supported");
    return;
  }
  ENSURE_SINGLE_ARG(value, TiViewProxy);

  if (contentViewProxy != nil) {
      RELEASE_TO_NIL(contentViewProxy);
  }
        
  contentViewProxy = [(TiViewProxy *)value retain];

    if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
       // if([contentViewProxy valueForKey:@"window"]){
            if ([contentViewProxy layoutProperties]->width.type == TiDimensionTypeAutoSize) {
                [contentViewProxy layoutProperties]->width = TiDimensionUndefined;
                poWidth = TiDimensionUndefined;
            }
            else if ([contentViewProxy layoutProperties]->width.type == TiDimensionTypeAutoFill) {
                [contentViewProxy layoutProperties]->width = TiDimensionAutoFill;
                poWidth = TiDimensionUndefined;
            }
            else {
                poWidth = TiDimensionUndefined;
            }
                        
            
            if ([contentViewProxy layoutProperties]->height.type == TiDimensionTypeAutoSize) {
                [contentViewProxy layoutProperties]->height = TiDimensionUndefined;
                poHeight = TiDimensionUndefined;
            }
            else if ([contentViewProxy layoutProperties]->height.type == TiDimensionTypeAutoFill) {
                [contentViewProxy layoutProperties]->height = TiDimensionAutoFill;
                poHeight = TiDimensionUndefined;
            }
            else {
                poHeight = TiDimensionUndefined;
            }
      //  }
    }

  [self replaceValue:contentViewProxy forKey:@"contentView" notification:NO];
}



- (void)setPassthroughViews:(id)args
{
  ENSURE_TYPE(args, NSArray);
  NSArray *actualArgs = nil;
  if ([[args objectAtIndex:0] isKindOfClass:[NSArray class]]) {
    actualArgs = (NSArray *)[args objectAtIndex:0];
  } else {
    actualArgs = args;
  }
  for (TiViewProxy *proxy in actualArgs) {
    if (![proxy isKindOfClass:[TiViewProxy class]]) {
      [self throwException:[NSString stringWithFormat:@"Passed non-view object %@ as passthrough view", proxy]
                 subreason:nil
                  location:CODELOCATION];
    }
  }
  [self replaceValue:actualArgs forKey:@"passthroughViews" notification:NO];

  if (popoverInitialized) {
   // TiThreadPerformOnMainThread(
    //    ^{
          [self updatePassThroughViews];
    //    },
    //    NO);
  }
}

#pragma mark Public Methods

- (void)show:(id)args
{
  if (tiPopOverCondition == nil) {
    tiPopOverCondition = [[NSCondition alloc] init];
  }

  if (popoverInitialized) {
    DebugLog(@"Popover is already showing. Ignoring call") return;
  }

  if (contentViewProxy == nil) {
    DebugLog(@"[ERROR] Popover presentation without contentView property set is no longer supported. Ignoring call") return;
  }

  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
  [self rememberSelf];
  [self retain];

  [closingCondition lock];
  if (isDismissing) {
    [closingCondition wait];
  }
  [closingCondition unlock];
  [self updateContentSize];

    
    if ([TiUtils boolValue:@"blurBackground" properties:args def:NO] == YES){
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
           // popViewController.popoverPresentationController.backgroundColor = [UIColor clearColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:[TiUtils intValue:[args valueForKey:@"blurEffect"] def:UIBlurEffectStyleLight]];
            popoverBlurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            //always fill the view
            
            popoverBlurEffectView.alpha = 0.0;
            popoverBlurEffectView.frame = [[TiApp app] controller].view.bounds;
            popoverBlurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            [[[TiApp app] controller].view addSubview:popoverBlurEffectView]; //if you have more UIViews, use an insertSubview API to place it where needed
        } else {
           // self.view.backgroundColor = [UIColor clearColor];
        }
    }
    
    
    id backgroundColor = [args valueForKey:@"backgroundColor"];
     UIColor * backgroundColorValue = nil;
     if (backgroundColor != nil) {
         backgroundColorValue = [[TiUtils colorValue:backgroundColor] _color];
         
         popoverDarkenBackgroundView = [[UIView alloc] init];
         //always fill the view
         popoverDarkenBackgroundView.alpha = 0.0;
         popoverDarkenBackgroundView.backgroundColor = backgroundColorValue;
         popoverDarkenBackgroundView.frame = [[TiApp app] controller].view.bounds;
         popoverDarkenBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
         [[[TiApp app] controller].view addSubview:popoverDarkenBackgroundView]; //if you have more UIViews, use an insertSubview API to place it where needed

     }
    
    
  animated = [TiUtils boolValue:@"animated" properties:args def:YES];
    popoverView = [[args objectForKey:@"view"] retain];
  NSDictionary *rectProps = [args objectForKey:@"rect"];
  if (IS_NULL_OR_NIL(rectProps)) {
    popoverRect = CGRectZero;
  } else {
    popoverRect = [TiUtils rectValue:rectProps];
  }

  if (IS_NULL_OR_NIL(popoverView)) {
    DebugLog(@"[ERROR] Popover presentation without view property in the arguments is not supported. Ignoring call")
      RELEASE_TO_NIL(popoverView);
    return;
  }

  [tiPopOverCondition lock];
  if (tiCurrentlyDisplaying) {
    [currentTiPopover hide:nil];
    [tiPopOverCondition wait];
  }
  tiCurrentlyDisplaying = YES;
  [tiPopOverCondition unlock];
  popoverInitialized = YES;

TiThreadPerformOnMainThread(
      ^{
        [self initAndShowPopOver];
      },
      YES);
}

- (void)hide:(id)args
{
  if (!popoverInitialized) {
    DebugLog(@"Popover is not showing. Ignoring call") return;
  }

  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);

  [closingCondition lock];
  isDismissing = YES;
  [closingCondition unlock];

    dispatch_async(dispatch_get_main_queue(), ^{
          [self->contentViewProxy windowWillClose];
          if (popoverBlurEffectView != nil){
              [UIView animateWithDuration:0.225 animations:^{
                  popoverBlurEffectView.alpha = 0.0;
                  
              }];
          }
          if (popoverDarkenBackgroundView != nil){
              [UIView animateWithDuration:0.225 animations:^{
                  popoverDarkenBackgroundView.alpha = 0.0;
                
              }];
          }

          self->animated = [TiUtils boolValue:@"animated" properties:args def:NO];
          [[self viewController] dismissViewControllerAnimated:self->animated
                                                  completion:^{
              
                                                  if (popoverBlurEffectView != nil){
                                                      [popoverBlurEffectView removeFromSuperview];
                                                      popoverBlurEffectView = nil;
                                                  }
                                                  if (popoverDarkenBackgroundView != nil){
                                                      [popoverDarkenBackgroundView removeFromSuperview];
                                                      popoverDarkenBackgroundView = nil;
                                                  }
              [self fireEvent:@"closed" withObject:nil];
                                                    [self cleanup];
                                                  }];
    });
}

#pragma mark Internal Methods

- (void)cleanup
{
  [tiPopOverCondition lock];
  tiCurrentlyDisplaying = NO;
  if (currentTiPopover == self) {
    currentTiPopover = nil;
  }
  [tiPopOverCondition broadcast];
  [tiPopOverCondition unlock];

  if (!popoverInitialized) {
    [closingCondition lock];
    isDismissing = NO;
    [closingCondition signal];
    [closingCondition unlock];

    return;
  }
  [contentViewProxy setProxyObserver:nil];
  [contentViewProxy windowWillClose];

  popoverInitialized = NO;
 // [self fireEvent:@"hide" withObject:nil]; //Checking for listeners are done by fireEvent anyways.
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
  [contentViewProxy windowDidClose];

  if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
    UIView *topWindowView = [[[TiApp app] controller] topWindowProxyView];
    if ([topWindowView isKindOfClass:[TiUIView class]]) {
      TiViewProxy *theProxy = (TiViewProxy *)[(TiUIView *)topWindowView proxy];
      if ([theProxy conformsToProtocol:@protocol(TiWindowProtocol)]) {
        [(id<TiWindowProtocol>)theProxy gainFocus];
      }
    }
  }

  [self forgetSelf];
  [viewController.view removeObserver:self forKeyPath:@"safeAreaInsets"];
  RELEASE_TO_NIL(viewController);
  RELEASE_TO_NIL(popoverView);
  [self performSelector:@selector(release) withObject:nil afterDelay:0.5];
  [closingCondition lock];
  isDismissing = NO;
  [closingCondition signal];
  [closingCondition unlock];
}

- (void)initAndShowPopOver
{
  deviceRotated = NO;
  currentTiPopover = self;
  [contentViewProxy setProxyObserver:self];
  if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
    UIView *topWindowView = [[[TiApp app] controller] topWindowProxyView];
    if ([topWindowView isKindOfClass:[TiUIView class]]) {
      TiViewProxy *theProxy = (TiViewProxy *)[(TiUIView *)topWindowView proxy];
      if ([theProxy conformsToProtocol:@protocol(TiWindowProtocol)]) {
        [(id<TiWindowProtocol>)theProxy resignFocus];
      }
    }
      
      [(TiWindowProxy *)contentViewProxy setIsManaged:YES];
      [(TiWindowProxy *)contentViewProxy windowWillOpen];

      [(TiWindowProxy *)contentViewProxy open:nil];
      [(TiWindowProxy *)contentViewProxy gainFocus];
      [(TiWindowProxy *)contentViewProxy reposition];
      [(TiWindowProxy *)contentViewProxy layoutChildrenIfNeeded];

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [self updatePopoverNow];
      });

  } else {
      [contentViewProxy windowWillOpen];
      [contentViewProxy reposition];
      [contentViewProxy layoutChildrenIfNeeded];
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [self updatePopoverNow];
      });
      //[contentViewProxy windowDidOpen];
  }
}

- (void)updatePopover:(NSNotification *)notification;
{
  //This may be due to a possible race condition of rotating the iPad while another popover is coming up.
  if ((currentTiPopover != self)) {
    return;
  }
  [self performSelector:@selector(updatePopoverNow) withObject:nil afterDelay:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (CGSize)contentSize
{
#ifndef TI_USE_AUTOLAYOUT
  CGSize screenSize = [[UIScreen mainScreen] bounds].size;
  if (poWidth.type != TiDimensionTypeUndefined) {
          [contentViewProxy layoutProperties]->width.type = poWidth.type;
          [contentViewProxy layoutProperties]->width.value = poWidth.value;
          poWidth = TiDimensionUndefined;
  }

  if (poHeight.type != TiDimensionTypeUndefined) {
    [contentViewProxy layoutProperties]->height.type = poHeight.type;
    [contentViewProxy layoutProperties]->height.value = poHeight.value;
    poHeight = TiDimensionUndefined;
  }

 TiPopoverContentSize = SizeConstraintViewWithSizeAddingResizing([contentViewProxy layoutProperties], contentViewProxy, screenSize, NULL);
  return TiPopoverContentSize;
#else
  return CGSizeZero;
#endif
}


- (void)updateContentSize
{

  CGSize newSize = [self contentSize];
    
  [[self viewController] setPreferredContentSize:newSize];
  [contentViewProxy reposition];
}





- (void)updatePassThroughViews
{
  NSArray *theViewProxies = [self valueForKey:@"passthroughViews"];
  if (IS_NULL_OR_NIL(theViewProxies)) {
    return;
  }
  NSMutableArray *theViews = [NSMutableArray arrayWithCapacity:[theViewProxies count]];
  for (TiViewProxy *proxy in theViewProxies) {
    [theViews addObject:[proxy view]];
  }

  [[[self viewController] popoverPresentationController] setPassthroughViews:theViews];
}



- (void)updatePopoverNow
{

  // We're in the middle of playing cleanup while a hide() is happening.
  [closingCondition lock];
  if (isDismissing) {
    [closingCondition unlock];
    return;
  }
  [closingCondition unlock];

    [contentViewProxy view].alpha = 0.0;

    
    UIViewController *theController = [self viewController];
    [theController setModalPresentationStyle:UIModalPresentationPopover];
    theController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  //  [theController setPreferredContentSize:[contentViewProxy view].frame.size];
   //
    [theController popoverPresentationController].permittedArrowDirections = [self arrowDirection];
    [theController popoverPresentationController].delegate = self;
    [[TiApp app] controller].modalPresentationStyle = UIModalPresentationOverCurrentContext;

    if ([self valueForKey:@"backgroundColor"]){
        [[theController popoverPresentationController] setBackgroundColor:[[TiColor colorNamed:[self valueForKey:@"backgroundColor"]] _color]];
    }
    else {
        [theController popoverPresentationController].backgroundColor = [UIColor clearColor];
    }
               
    
    

    // [[TiApp app] showModalController:theController animated:animated];

    
    if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
        if (animated){
            if (popoverBlurEffectView != nil){
                [UIView animateWithDuration:0.15 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                    animations:^{
                        popoverBlurEffectView.alpha = 1.0;
                }
                completion:nil];
            }
            if (popoverDarkenBackgroundView != nil){
               
                [UIView animateWithDuration:0.15 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                    animations:^{
                    popoverDarkenBackgroundView.alpha = 1.0;
                }
                completion:nil];
            }
        }
        else {
            if (popoverBlurEffectView != nil){
                popoverBlurEffectView.alpha = 1.0;
            }
            if (popoverDarkenBackgroundView != nil){
                popoverDarkenBackgroundView.alpha = 1.0;
            }
        }
        [[[TiApp app] controller] presentViewController:theController animated:animated completion:nil];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (animated){
                    [UIView animateWithDuration:0.001 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                        animations:^{
                        [contentViewProxy view].alpha = 1.0;
                    }
                    completion:^(BOOL finished) {
                    }];
                }
                else {
                    [contentViewProxy view].alpha = 1.0;
                }
                [(TiWindowProxy *)contentViewProxy windowDidOpen];

            });
    }
    else {
        if (animated){
            if (popoverBlurEffectView != nil){
                [UIView animateWithDuration:0.225 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                    animations:^{
                        popoverBlurEffectView.alpha = 1.0;
                }
                completion:nil];
            }
            if (popoverDarkenBackgroundView != nil){
               
                [UIView animateWithDuration:0.225 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                    animations:^{
                    popoverDarkenBackgroundView.alpha = 1.0;
                }
                completion:nil];
            }
        }
        else {
            if (popoverBlurEffectView != nil){
                popoverBlurEffectView.alpha = 1.0;
            }
            if (popoverDarkenBackgroundView != nil){
                popoverDarkenBackgroundView.alpha = 1.0;
            }
        }

        [[[TiApp app] controller] presentViewController:theController animated:NO completion:nil];

        if (animated){
            [UIView animateWithDuration:0.001 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn
                animations:^{
                [contentViewProxy view].alpha = 1.0;
            }
            completion:^(BOOL finished) {
            }];
        }
        else {
            [contentViewProxy view].alpha = 1.0;
        }
        [contentViewProxy windowDidOpen];

    }
}



- (UIViewController *)viewController
{
  if (viewController == nil) {
    if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
      [(TiWindowProxy *)contentViewProxy setIsManaged:YES];
        viewController = [[(TiWindowProxy *)contentViewProxy hostingController] retain];
      [viewController.view addObserver:self forKeyPath:@"safeAreaInsets" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    } else {
      viewController = [[TiViewController alloc] initWithViewProxy:contentViewProxy];
      [viewController.view addObserver:self forKeyPath:@"safeAreaInsets" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
  }
  viewController.view.clipsToBounds = YES;
  return viewController;
}





- (void)updateContentViewWithSafeAreaInsets:(NSValue *)insetsValue
{
  TiThreadPerformOnMainThread(
      ^{

        UIViewController *viewController = [self viewController];
          self->contentViewProxy.view.frame = viewController.view.frame;
        UIEdgeInsets edgeInsets = [insetsValue UIEdgeInsetsValue];
        viewController.view.frame = CGRectMake(viewController.view.frame.origin.x + edgeInsets.left, viewController.view.frame.origin.y + edgeInsets.top, viewController.view.frame.size.width - edgeInsets.left - edgeInsets.right, viewController.view.frame.size.height - edgeInsets.top - edgeInsets.bottom);
      },
      NO);
 
}

#pragma mark Delegate methods



- (void)proxyDidRelayout:(id)sender
{
  if (sender == contentViewProxy) {
    if (viewController != nil) {
      CGSize newSize = [self contentSize];
        
        if (!CGSizeEqualToSize([viewController preferredContentSize], newSize)) {
                [self updateContentSize];
        }
        
      if (TiPopoverContentSize.width != newSize.width || TiPopoverContentSize.height != newSize.height){
        if (!CGSizeEqualToSize([viewController preferredContentSize], newSize)) {
          [self updateContentSize];
        }
      }
    }
  }
}






- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController: (UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{

  [self updatePassThroughViews];
  if (popoverView != nil) {
    if ([popoverView supportsNavBarPositioning] && [popoverView isUsingBarButtonItem]) {
      UIBarButtonItem *theItem = [popoverView barButtonItem];
      if (theItem != nil) {
        popoverPresentationController.barButtonItem = [popoverView barButtonItem];
        return;
      }
    }

    UIView *view = [popoverView view];
    if (view != nil && (view.window != nil)) {
      popoverPresentationController.permittedArrowDirections = [self arrowDirection];
      popoverPresentationController.sourceView = view;
      popoverPresentationController.sourceRect = (CGRectEqualToRect(CGRectZero, popoverRect) ? [view bounds] : popoverRect);
      return;
    }
  }

  //Fell through.
  UIViewController *presentingController = [[self viewController] presentingViewController];
  popoverPresentationController.permittedArrowDirections = [self arrowDirection];
  popoverPresentationController.sourceView = [presentingController view];
  popoverPresentationController.sourceRect = (CGRectEqualToRect(CGRectZero, popoverRect) ? CGRectMake(presentingController.view.bounds.size.width / 2, presentingController.view.bounds.size.height / 2, 1, 1) : popoverRect);
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
  if ([[self viewController] presentedViewController] != nil) {
    return NO;
  }
    if (popoverBlurEffectView != nil){
        [UIView animateWithDuration:0.225 animations:^{
            popoverBlurEffectView.alpha = 0.0;
        }];
    }
    if (popoverDarkenBackgroundView != nil){
        [UIView animateWithDuration:0.225 animations:^{
            popoverDarkenBackgroundView.alpha = 0.0;
        }];
    }
    [self fireEvent:@"hide" withObject:nil];

  [contentViewProxy windowWillClose];
  return YES;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if (popoverBlurEffectView != nil){
        [popoverBlurEffectView removeFromSuperview];
        popoverBlurEffectView = nil;
    }
    if (popoverDarkenBackgroundView != nil){
        [popoverDarkenBackgroundView removeFromSuperview];
        popoverDarkenBackgroundView = nil;
    }
  [self cleanup];
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view
{
  //This will never be called when using bar button item
  BOOL canUseDialogRect = !CGRectEqualToRect(CGRectZero, popoverRect);
  UIView *theSourceView = *view;

  if (!canUseDialogRect) {
    rect->origin = [theSourceView bounds].origin;
    rect->size = [theSourceView bounds].size;
  }

  popoverPresentationController.sourceRect = *rect;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
  if ([TiUtils isIOSVersionOrGreater:@"13.0"] && object == viewController.view && [keyPath isEqualToString:@"safeAreaInsets"]) {
    UIEdgeInsets newInsets = [[change objectForKey:@"new"] UIEdgeInsetsValue];
    UIEdgeInsets oldInsets = [[change objectForKey:@"old"] UIEdgeInsetsValue];
    NSValue *insetsValue = [NSValue valueWithUIEdgeInsets:newInsets];

    if (!UIEdgeInsetsEqualToEdgeInsets(oldInsets, newInsets)) {
      deviceRotated = NO;
      [self updateContentViewWithSafeAreaInsets:insetsValue];
    } else if (deviceRotated) {
      // [self viewController]  need a bit of time to set its frame while rotating
      deviceRotated = NO;
      [self performSelector:@selector(updateContentViewWithSafeAreaInsets:) withObject:insetsValue afterDelay:.05];
    }
  }
}

- (void)deviceRotated:(NSNotification *)sender
{
  deviceRotated = YES;
}

@end




@implementation TiPopoverBackgroundView

@synthesize arrowDirection = _arrowDirection;
@synthesize arrowOffset = _arrowOffset;

#define TOP_CONTENT_INSET s_ContentInset
#define LEFT_CONTENT_INSET s_ContentInset
#define BOTTOM_CONTENT_INSET s_ContentInset
#define RIGHT_CONTENT_INSET s_ContentInset

#define DEFAULT_CONTENT_INSET 9.0f
static CGFloat s_ContentInset = DEFAULT_CONTENT_INSET;

#define ArrowBase 30.0f
#define ArrowHeight 15.0f
#define BorderInset 10.0f

//+ (UIEdgeInsets)contentViewInsets
//{
//    return UIEdgeInsetsMake(TOP_CONTENT_INSET, LEFT_CONTENT_INSET, BOTTOM_CONTENT_INSET, RIGHT_CONTENT_INSET);
//}

+(UIEdgeInsets)contentViewInsets{
    return UIEdgeInsetsMake(BorderInset, BorderInset, BorderInset, BorderInset);
}

//+ (void)setContentInset:(CGFloat)contentInset
//{
//    s_ContentInset = contentInset;
//}

- (CGFloat) arrowOffset {
    return _arrowOffset;
}

- (void) setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
}

- (UIPopoverArrowDirection)arrowDirection {
    return _arrowDirection;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {

    _arrowDirection = arrowDirection;
}

+(CGFloat)arrowHeight{
    return ArrowHeight;
}

+(CGFloat)arrowBase{
    return ArrowBase;
}


//
-  (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat _height = self.frame.size.height;
    CGFloat _width = self.frame.size.width;
    CGFloat _left = 0.0;
    CGFloat _top = 0.0;
    CGFloat _coordinate = 0.0;
    CGAffineTransform _rotation = CGAffineTransformIdentity;

    switch (self.arrowDirection) {
        case UIPopoverArrowDirectionUp:
            _top += ArrowHeight;
            _height -= ArrowHeight;
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ArrowBase/2);
            break;


        case UIPopoverArrowDirectionDown:
            _height -= ArrowHeight;
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ArrowBase/2);
            _rotation = CGAffineTransformMakeRotation( M_PI );
            break;

        case UIPopoverArrowDirectionLeft:
            _left += ArrowBase;
            _width -= ArrowBase;
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ArrowHeight/2);
            _rotation = CGAffineTransformMakeRotation( -M_PI_2 );
            break;

        case UIPopoverArrowDirectionRight:
            _width -= ArrowBase;
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset)- (ArrowHeight/2);
            _rotation = CGAffineTransformMakeRotation( M_PI_2 );

            break;
        case UIPopoverArrowDirectionAny:
            break;
        case UIPopoverArrowDirectionUnknown:
            break;
    }
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {

        
//        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//        popoverBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//
//        [self addSubview:popoverBackgroundBlurView];
//        popoverBackgroundBlurView.frame = self.bounds;

    }

    return self;
}
@end
