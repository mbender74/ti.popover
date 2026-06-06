/**
 * ti.popover
 *
 * Popover for iOS (Titanium Module)
 * Custom popover implementation based on FSPopoverView architecture.
 * Draws its own arrow and border using UIBezierPath, positions itself
 * relative to the source view, and handles dismiss via tap gesture.
 */
#import <TitaniumKit/TiViewController.h>
#import <TitaniumKit/TiViewProxy.h>
#import <TitaniumKit/TiProxy.h>
#import <TitaniumKit/TitaniumKit.h>
#ifdef USE_TI_UINAVIGATIONWINDOW
#import "TiUINavigationWindowProxy.h"
#import "TiUINavigationWindowInternal.h"
#endif
#import "TiWindowProxy+Addons.h"
#import <UIKit/UIKit.h>
#import <TitaniumKit/TiViewTemplate.h>

// Arrow dimensions — defaults, can be overridden via JS properties.
#define TI_POPOVER_ARROW_BASE 30.0f
#define TI_POPOVER_ARROW_HEIGHT 15.0f
#define TI_POPOVER_CORNER_RADIUS 10.0f
#define TI_POPOVER_BORDER_WIDTH 0.0f
#define TI_POPOVER_SHADOW_RADIUS 5.0f
#define TI_POPOVER_SHADOW_OPACITY 0.3f

// Extended arrow direction constant values (used internally, exposed via module properties)
#define _POPOVER_ARROW_DIRECTION_UP_LEFT       100
#define _POPOVER_ARROW_DIRECTION_UP_RIGHT      101
#define _POPOVER_ARROW_DIRECTION_DOWN_LEFT     102
#define _POPOVER_ARROW_DIRECTION_DOWN_RIGHT    103
#define _POPOVER_ARROW_DIRECTION_LEFT_TOP      104
#define _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM   105
#define _POPOVER_ARROW_DIRECTION_RIGHT_TOP     106
#define _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM  107

@interface TiPopoverProxy : TiProxy <TiProxyObserver> {
  @private
  UIViewController *viewController;
  TiViewProxy *contentViewProxy;

  // Anchor view and rect
  TiViewProxy *popoverView;
  CGRect popoverRect;
  BOOL animated;
  UIPopoverArrowDirection directions;
  BOOL popoverInitialized;
  BOOL isDismissing;
  NSCondition *closingCondition;
  TiDimension poWidth;
  TiDimension poHeight;
  UIPopoverArrowDirection popoverArrowDirection;

  // Background / dim overlays (global, on key window)
  UIVisualEffectView *popoverBlurEffectView;
  UIView *popoverDarkenBackgroundView;

  // Popover drawing and positioning
  UIView *_containerView;
  UIView *_shadowView;              // shadow carrier (unmasked, behind popover)
  UIView *_popoverContainerView;   // clipped to popover shape via CAShapeLayer mask
  UIView *_backgroundView;          // background inside popover shape (solid color or blur)
  UIVisualEffectView *_popoverBodyBlurView; // blur effect inside popover shape
  UITapGestureRecognizer *_outsideTapGesture;
  CAShapeLayer *_borderLayer;

  // Appearance
  CGFloat _cornerRadius;
  CGSize _arrowSize;
  CGFloat _borderWidth;
  UIColor *_borderColor;
  CGFloat _shadowRadius;
  CGFloat _shadowOpacity;
  UIColor *_shadowColor;
  CGSize _shadowOffset;
  UIColor *_popoverBackgroundColor;
  BOOL _showsArrow;
  BOOL _showsDimBackground;
  BOOL _blurBackground;
  UIBlurEffectStyle _blurEffectStyle;
  NSInteger _transitionStyle; // 0=Scale, 1=Fade, 2=Translate, 3=None
  CGFloat _transitionDuration; // animation duration in seconds
  BOOL _dismissOnTapOutside;
  NSInteger _popoverBlurStyle; // -1 = no blur (solid color), otherwise UIBlurEffectStyle value

  // Layout
  CGSize popoverContentSize;
  UIEdgeInsets _containerSafeAreaInsets;
}

- (void)updatePopover:(NSNotification *)notification;

@end