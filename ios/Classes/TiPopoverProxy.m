/**
 * ti.popover
 *
 * Custom popover implementation based on FSPopoverView architecture.
 * Draws its own arrow and border using UIBezierPath, positions itself
 * relative to the source view, and handles dismiss via tap gesture.
 *
 * Original code taken from Titanium SDK (TiUIiPadPopoverProxy).
 */

#import "TiPopoverProxy.h"
#import <TitaniumKit/TiApp.h>
#import <TitaniumKit/TiUtils.h>
#import <TitaniumKit/TiWindowProxy.h>

#ifdef USE_TI_UITABLEVIEW
#import "TiUITableViewRowProxy.h"
#endif

static NSCondition *tiPopOverCondition;
static BOOL tiCurrentlyDisplaying = NO;
static TiPopoverProxy *currentTiPopover;

@implementation TiPopoverProxy

static NSArray *popoverSequence;

#pragma mark - Internal

- (NSArray *)keySequence
{
  if (popoverSequence == nil) {
      popoverSequence = [[NSArray arrayWithObjects:@"contentView", nil] retain];
  }
  return popoverSequence;
}

#pragma mark - Setup

- (id)init
{
  if (self = [super init]) {
    closingCondition = [[NSCondition alloc] init];
    directions = UIPopoverArrowDirectionAny;
    poWidth = TiDimensionUndefined;
    poHeight = TiDimensionUndefined;
    _cornerRadius = TI_POPOVER_CORNER_RADIUS;
    _arrowSize = CGSizeMake(TI_POPOVER_ARROW_BASE, TI_POPOVER_ARROW_HEIGHT);
    _borderWidth = TI_POPOVER_BORDER_WIDTH;
    _shadowRadius = TI_POPOVER_SHADOW_RADIUS;
    _shadowOpacity = TI_POPOVER_SHADOW_OPACITY;
    _shadowColor = [[UIColor blackColor] retain];
    _shadowOffset = CGSizeMake(0, 0);
    _borderColor = nil;
    _popoverBackgroundColor = nil;
    _showsArrow = YES;
    _showsDimBackground = NO;
    _blurBackground = NO;
    _blurEffectStyle = UIBlurEffectStyleLight;
    _transitionStyle = 0; // Scale
    _transitionDuration = 0; // 0 = use default
    _dismissOnTapOutside = YES;
    _popoverBlurStyle = -1; // -1 = solid color background (no blur on popover body)
    _containerSafeAreaInsets = UIEdgeInsetsMake(10, 10, 10, 10);
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
    currentTiPopover = nil;
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE_TO_NIL(viewController);
  RELEASE_TO_NIL(popoverView);
  RELEASE_TO_NIL(closingCondition);
  RELEASE_TO_NIL(contentViewProxy);
  RELEASE_TO_NIL(popoverBlurEffectView);
  RELEASE_TO_NIL(_popoverBodyBlurView);
  RELEASE_TO_NIL(popoverDarkenBackgroundView);
  RELEASE_TO_NIL(_borderLayer);
  RELEASE_TO_NIL(_shadowView);
  [_borderColor release];
  [_shadowColor release];
  [_popoverBackgroundColor release];
  [super dealloc];
}

#pragma mark - Public API

- (NSString *)apiName
{
    return @"Ti.UI.Popover";
}

#pragma mark - Public Constants

- (UIPopoverArrowDirection)arrowDirection
{
  return directions;
}

- (void)setArrowDirection:(id)args
{
  if (popoverInitialized) {
    DebugLog(@"[ERROR] Arrow Directions can only be set before showing the popover.");
    return;
  }
  ENSURE_SINGLE_ARG(args, NSNumber)
  UIPopoverArrowDirection theDirection = [TiUtils intValue:args];
  directions = theDirection;
}

- (void)setHeight:(id)value
{
    DebugLog(@"[WARN] height is set via contentView properties, not directly on the popover");
    poHeight = TiDimensionUndefined;
}

- (void)setWidth:(id)value
{
    DebugLog(@"[WARN] width is set via contentView properties, not directly on the popover");
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
  }

  [self replaceValue:contentViewProxy forKey:@"contentView" notification:NO];
}

- (void)setPopoverBlurStyle:(id)args
{
  ENSURE_SINGLE_ARG(args, NSNumber);
  _popoverBlurStyle = [TiUtils intValue:args];
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
}

- (void)setShadowColor:(id)value
{
  ENSURE_SINGLE_ARG(value, NSObject);
  [_shadowColor release];
  _shadowColor = [[[TiUtils colorValue:value] _color] retain];
  [self replaceValue:value forKey:@"shadowColor" notification:NO];
}

- (void)setShadowRadius:(id)value
{
  ENSURE_SINGLE_ARG(value, NSNumber);
  _shadowRadius = [TiUtils floatValue:value];
  [self replaceValue:value forKey:@"shadowRadius" notification:NO];
}

- (void)setShadowOpacity:(id)value
{
  ENSURE_SINGLE_ARG(value, NSNumber);
  _shadowOpacity = [TiUtils floatValue:value];
  [self replaceValue:value forKey:@"shadowOpacity" notification:NO];
}

- (void)setShadowOffset:(id)value
{
  ENSURE_SINGLE_ARG(value, NSDictionary);
  _shadowOffset = CGSizeMake(
    [TiUtils floatValue:@"x" properties:value def:0],
    [TiUtils floatValue:@"y" properties:value def:0]
  );
  [self replaceValue:value forKey:@"shadowOffset" notification:NO];
}

#pragma mark - Content Size

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

  popoverContentSize = SizeConstraintViewWithSizeAddingResizing([contentViewProxy layoutProperties], contentViewProxy, screenSize, NULL);

  // Add margin insets when explicit dimensions AND margins are both set
  LayoutConstraint *cp = [contentViewProxy layoutProperties];
  CGFloat extraWidth = 0;
  CGFloat extraHeight = 0;

  if (cp->width.type == TiDimensionTypeDip) {
    if (!TiDimensionIsUndefined(cp->left) && TiDimensionIsDip(cp->left)) {
      extraWidth += TiDimensionCalculateValue(cp->left, screenSize.width);
    }
    if (!TiDimensionIsUndefined(cp->right) && TiDimensionIsDip(cp->right)) {
      extraWidth += TiDimensionCalculateValue(cp->right, screenSize.width);
    }
  }

  if (cp->height.type == TiDimensionTypeDip) {
    if (!TiDimensionIsUndefined(cp->top) && TiDimensionIsDip(cp->top)) {
      extraHeight += TiDimensionCalculateValue(cp->top, screenSize.height);
    }
    if (!TiDimensionIsUndefined(cp->bottom) && TiDimensionIsDip(cp->bottom)) {
      extraHeight += TiDimensionCalculateValue(cp->bottom, screenSize.height);
    }
  }

  popoverContentSize.width += extraWidth;
  popoverContentSize.height += extraHeight;

  return popoverContentSize;
#else
  return CGSizeZero;
#endif
}

- (void)updateContentSize
{
  CGSize newSize = [self contentSize];
  popoverContentSize = newSize;
  [contentViewProxy reposition];
}

#pragma mark - Arrow Direction Auto-Detection

- (UIPopoverArrowDirection)autoArrowDirectionForContentSize:(CGSize)contentSize
                                                 sourceRect:(CGRect)sourceRect
                                                containerRect:(CGRect)containerRect
{
  // If user set a specific arrowDirection (not ANY), respect it.
  if (directions != UIPopoverArrowDirectionAny && directions != UIPopoverArrowDirectionUnknown) {
    return directions;
  }

  CGFloat arrowHeight = _arrowSize.height;
  CGRect expandedRect = CGRectInset(sourceRect, -arrowHeight, -arrowHeight);

  // Space below sourceRect → Arrow UP (popover appears below source)
  CGSize bottomSpace = CGSizeMake(containerRect.size.width, MAX(0, CGRectGetMaxY(containerRect) - CGRectGetMaxY(expandedRect)));
  // Space above sourceRect → Arrow DOWN (popover appears above source)
  CGSize topSpace = CGSizeMake(containerRect.size.width, MAX(0, expandedRect.origin.y - containerRect.origin.y));
  // Space to the right of sourceRect → Arrow LEFT (popover appears to the right)
  CGSize rightSpace = CGSizeMake(MAX(0, CGRectGetMaxX(containerRect) - CGRectGetMaxX(expandedRect)), containerRect.size.height);
  // Space to the left of sourceRect → Arrow RIGHT (popover appears to the left)
  CGSize leftSpace = CGSizeMake(MAX(0, expandedRect.origin.x - containerRect.origin.x), containerRect.size.height);

  CGSize verticalContentSize = CGSizeMake(MAX(contentSize.width, _cornerRadius * 2),
                                          MAX(contentSize.height, _cornerRadius * 2 + arrowHeight));
  CGSize horizontalContentSize = CGSizeMake(MAX(contentSize.width, _cornerRadius * 2 + arrowHeight),
                                             MAX(contentSize.height, _cornerRadius * 2));

  // Priority: up > down > left > right
  if (bottomSpace.height >= verticalContentSize.height && bottomSpace.width >= verticalContentSize.width) {
    return UIPopoverArrowDirectionUp;
  }
  if (topSpace.height >= verticalContentSize.height && topSpace.width >= verticalContentSize.width) {
    return UIPopoverArrowDirectionDown;
  }
  if (rightSpace.width >= horizontalContentSize.width) {
    return UIPopoverArrowDirectionLeft;
  }
  if (leftSpace.width >= horizontalContentSize.width) {
    return UIPopoverArrowDirectionRight;
  }

  return UIPopoverArrowDirectionUp;
}

static NSInteger transitionStyleFromValue(id value);

static CGFloat flatValue(CGFloat value);

// Extract the base UIPopoverArrowDirection from extended direction constants
// e.g. _POPOVER_ARROW_DIRECTION_RIGHT_TOP -> UIPopoverArrowDirectionRight
static UIPopoverArrowDirection baseArrowDirection(UIPopoverArrowDirection dir) {
  switch (dir) {
    case _POPOVER_ARROW_DIRECTION_UP_LEFT:
    case _POPOVER_ARROW_DIRECTION_UP_RIGHT:
      return UIPopoverArrowDirectionUp;
    case _POPOVER_ARROW_DIRECTION_DOWN_LEFT:
    case _POPOVER_ARROW_DIRECTION_DOWN_RIGHT:
      return UIPopoverArrowDirectionDown;
    case _POPOVER_ARROW_DIRECTION_LEFT_TOP:
    case _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM:
      return UIPopoverArrowDirectionLeft;
    case _POPOVER_ARROW_DIRECTION_RIGHT_TOP:
    case _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM:
      return UIPopoverArrowDirectionRight;
    default:
      return dir;
  }
}

- (UIBezierPath *)popoverPathWithRect:(CGRect)popoverRect
                            arrowPoint:(CGPoint)arrowPoint
                         arrowDirection:(UIPopoverArrowDirection)direction
                          contentRect:(CGRect)contentRect
{
  CGFloat cr = _cornerRadius;
  CGFloat aw = _arrowSize.width;
  CGFloat ah = _arrowSize.height;
  CGFloat flat = 1.0 / [[UIScreen mainScreen] scale];

  UIBezierPath *path = [UIBezierPath bezierPath];

  if (!_showsArrow) {
    return [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:cr];
  }

  switch (direction) {
    case UIPopoverArrowDirectionUp: {
      // Arrow at top, content below
      CGPoint arrowLeft = CGPointMake(flatValue(arrowPoint.x - aw / 2), flatValue(contentRect.origin.y));
      CGPoint arrowRight = CGPointMake(flatValue(arrowPoint.x + aw / 2), flatValue(contentRect.origin.y));
      CGPoint arrowTip = CGPointMake(flatValue(arrowPoint.x), flatValue(arrowPoint.y));

      [path moveToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMinY(contentRect)))];
      // Line to arrow left
      [path addLineToPoint:arrowLeft];
      // Arrow curve to tip
      [path addCurveToPoint:arrowTip controlPoint1:CGPointMake(flatValue(arrowLeft.x + aw / 4), flatValue(contentRect.origin.y)) controlPoint2:CGPointMake(flatValue(arrowTip.x - aw / 6), flatValue(arrowTip.y))];
      // Arrow curve from tip to right
      [path addCurveToPoint:arrowRight controlPoint1:CGPointMake(flatValue(arrowTip.x + aw / 6), flatValue(arrowTip.y)) controlPoint2:CGPointMake(flatValue(arrowRight.x - aw / 4), flatValue(contentRect.origin.y))];
      // Top right corner
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(contentRect.origin.y))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(contentRect.origin.y + cr)) radius:cr startAngle:M_PI * 1.5 endAngle:0 clockwise:YES];
      // Right side down
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(CGRectGetMaxY(contentRect) - cr))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
      // Bottom
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect)))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
      // Left side up
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(contentRect.origin.y + cr))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(contentRect.origin.y + cr)) radius:cr startAngle:M_PI endAngle:M_PI * 1.5 clockwise:YES];
      [path closePath];
      break;
    }
    case UIPopoverArrowDirectionDown: {
      // Arrow at bottom, content above
      CGPoint arrowLeft = CGPointMake(flatValue(arrowPoint.x - aw / 2), flatValue(CGRectGetMaxY(contentRect)));
      CGPoint arrowRight = CGPointMake(flatValue(arrowPoint.x + aw / 2), flatValue(CGRectGetMaxY(contentRect)));
      CGPoint arrowTip = CGPointMake(flatValue(arrowPoint.x), flatValue(arrowPoint.y));

      [path moveToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(CGRectGetMinY(contentRect) + cr))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI endAngle:M_PI * 1.5 clockwise:YES];
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect)))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI * 1.5 endAngle:0 clockwise:YES];
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(CGRectGetMaxY(contentRect) - cr))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
      // Arrow right to tip to left
      [path addLineToPoint:arrowRight];
      [path addCurveToPoint:arrowTip controlPoint1:CGPointMake(flatValue(arrowRight.x - aw / 4), flatValue(CGRectGetMaxY(contentRect))) controlPoint2:CGPointMake(flatValue(arrowTip.x + aw / 6), flatValue(arrowTip.y))];
      [path addCurveToPoint:arrowLeft controlPoint1:CGPointMake(flatValue(arrowTip.x - aw / 6), flatValue(arrowTip.y)) controlPoint2:CGPointMake(flatValue(arrowLeft.x + aw / 4), flatValue(CGRectGetMaxY(contentRect)))];
      // Bottom left corner
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect)))];
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
      [path closePath];
      break;
    }
    case UIPopoverArrowDirectionLeft: {
      // Arrow on left side pointing left; content to the right.
      // Rotated equivalent of UP arrow: arrowBase on left edge, tip points left.
      // aw = arrow base width (vertical), ah = arrow height (horizontal).
      CGPoint arrowTop = CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(arrowPoint.y - aw / 2));
      CGPoint arrowBottom = CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(arrowPoint.y + aw / 2));
      CGPoint arrowTip = CGPointMake(flatValue(arrowPoint.x), flatValue(arrowPoint.y));

      [path moveToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(CGRectGetMinY(contentRect) + cr))];
      // Top-left corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI endAngle:M_PI * 1.5 clockwise:YES];
      // Top edge
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect)))];
      // Top-right corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI * 1.5 endAngle:0 clockwise:YES];
      // Right side down
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(CGRectGetMaxY(contentRect) - cr))];
      // Bottom-right corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
      // Bottom edge
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect)))];
      // Bottom-left corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
      // Left side up to arrow bottom
      [path addLineToPoint:arrowBottom];
      // Arrow: arrowBottom → tip → arrowTop (rotated 90° from UP: aw/6 offset on y-axis, not x-axis)
      [path addCurveToPoint:arrowTip controlPoint1:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(arrowBottom.y - aw / 4)) controlPoint2:CGPointMake(flatValue(arrowTip.x), flatValue(arrowTip.y + aw / 6))];
      [path addCurveToPoint:arrowTop controlPoint1:CGPointMake(flatValue(arrowTip.x), flatValue(arrowTip.y - aw / 6)) controlPoint2:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(arrowTop.y + aw / 4))];
      // Left side up from arrow top to start
      [path closePath];
      break;
    }
    case UIPopoverArrowDirectionRight: {
      // Arrow on right side pointing right; content to the left.
      // Rotated equivalent of UP arrow: arrowBase on right edge, tip points right.
      CGPoint arrowTop = CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(arrowPoint.y - aw / 2));
      CGPoint arrowBottom = CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(arrowPoint.y + aw / 2));
      CGPoint arrowTip = CGPointMake(flatValue(arrowPoint.x), flatValue(arrowPoint.y));

      [path moveToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect)), flatValue(CGRectGetMinY(contentRect) + cr))];
      // Top-left corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI endAngle:M_PI * 1.5 clockwise:YES];
      // Top edge
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect)))];
      // Top-right corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMinY(contentRect) + cr)) radius:cr startAngle:M_PI * 1.5 endAngle:0 clockwise:YES];
      // Right side down to arrow top
      [path addLineToPoint:arrowTop];
      // Arrow: arrowTop → tip → arrowBottom (rotated 90° from UP: aw/6 offset on y-axis, not x-axis)
      [path addCurveToPoint:arrowTip controlPoint1:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(arrowTop.y + aw / 4)) controlPoint2:CGPointMake(flatValue(arrowTip.x), flatValue(arrowTip.y - aw / 6))];
      [path addCurveToPoint:arrowBottom controlPoint1:CGPointMake(flatValue(arrowTip.x), flatValue(arrowTip.y + aw / 6)) controlPoint2:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(arrowBottom.y - aw / 4))];
      // Right side down from arrow bottom to bottom-right corner
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMaxX(contentRect)), flatValue(CGRectGetMaxY(contentRect) - cr))];
      // Bottom-right corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMaxX(contentRect) - cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
      // Bottom edge
      [path addLineToPoint:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect)))];
      // Bottom-left corner
      [path addArcWithCenter:CGPointMake(flatValue(CGRectGetMinX(contentRect) + cr), flatValue(CGRectGetMaxY(contentRect) - cr)) radius:cr startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
      // Left side up
      [path closePath];
      break;
    }
    default: {
      // Fallback: simple rounded rect
      [path appendPath:[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:cr]];
      break;
    }
  }
  return path;
}

static NSInteger transitionStyleFromValue(id value)
{
  if (IS_NULL_OR_NIL(value)) return -1;
  if ([value isKindOfClass:[NSString class]]) {
    NSString *s = (NSString *)value;
    if ([s isEqualToString:@"scale"]) return 0;
    if ([s isEqualToString:@"fade"]) return 1;
    if ([s isEqualToString:@"translate"]) return 2;
    if ([s isEqualToString:@"none"]) return 3;
  }
  if ([value isKindOfClass:[NSNumber class]]) {
    return [value integerValue];
  }
  return 0;
}

static CGFloat flatValue(CGFloat value) {
  CGFloat scale = [[UIScreen mainScreen] scale];
  return ceil(value * scale) / scale;
}

#pragma mark - Show

- (void)show:(id)args
{

  if (tiPopOverCondition == nil) {
    tiPopOverCondition = [[NSCondition alloc] init];
  }

  if (popoverInitialized) {
    DebugLog(@"Popover is already showing. Ignoring call");
    return;
  }

  if (contentViewProxy == nil) {
    DebugLog(@"[ERROR] Popover presentation without contentView property set is no longer supported. Ignoring call");
    return;
  }

  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
  [self rememberSelf];
  [self retain];

  [closingCondition lock];
  if (isDismissing) {
    [closingCondition wait];
  }
  [closingCondition unlock];

  animated = [TiUtils boolValue:@"animated" properties:args def:YES];

  popoverView = [[args objectForKey:@"view"] retain];
  NSDictionary *rectProps = [args objectForKey:@"rect"];
  if (IS_NULL_OR_NIL(rectProps)) {
    popoverRect = CGRectZero;
  } else {
    popoverRect = [TiUtils rectValue:rectProps];
  }

  if (IS_NULL_OR_NIL(popoverView)) {
    DebugLog(@"[ERROR] Popover presentation without view property in the arguments is not supported. Ignoring call");
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

  // Parse appearance properties
  id cornerRadiusVal = [args valueForKey:@"cornerRadius"];
  if (cornerRadiusVal) _cornerRadius = [TiUtils floatValue:cornerRadiusVal];

  id arrowWidthVal = [args valueForKey:@"arrowWidth"];
  id arrowHeightVal = [args valueForKey:@"arrowHeight"];
  if (arrowWidthVal) _arrowSize.width = [TiUtils floatValue:arrowWidthVal];
  if (arrowHeightVal) _arrowSize.height = [TiUtils floatValue:arrowHeightVal];

  id borderWidthVal = [args valueForKey:@"borderWidth"];
  if (borderWidthVal) _borderWidth = [TiUtils floatValue:borderWidthVal];

  id borderColorVal = [args valueForKey:@"borderColor"];
  if (borderColorVal) {
    [_borderColor release];
    _borderColor = [[[TiUtils colorValue:borderColorVal] _color] retain];
  }

  id shadowRadiusVal = [args valueForKey:@"shadowRadius"];
  if (shadowRadiusVal) _shadowRadius = [TiUtils floatValue:shadowRadiusVal];

  id shadowColorVal = [args valueForKey:@"shadowColor"];
  if (shadowColorVal) {
    [_shadowColor release];
    _shadowColor = [[[TiUtils colorValue:shadowColorVal] _color] retain];
  }

  id shadowOpacityVal = [args valueForKey:@"shadowOpacity"];
  if (shadowOpacityVal) _shadowOpacity = [TiUtils floatValue:shadowOpacityVal];

  id shadowOffsetVal = [args valueForKey:@"shadowOffset"];
  if (shadowOffsetVal) {
    NSDictionary *offsetDict = shadowOffsetVal;
    _shadowOffset = CGSizeMake(
      [TiUtils floatValue:@"x" properties:offsetDict def:0],
      [TiUtils floatValue:@"y" properties:offsetDict def:0]
    );
  }

  _showsArrow = [TiUtils boolValue:@"showsArrow" properties:args def:YES];
  _showsDimBackground = [TiUtils boolValue:@"showsDimBackground" properties:args def:NO];
  _blurBackground = [TiUtils boolValue:@"blurBackground" properties:args def:NO];
  _blurEffectStyle = [TiUtils intValue:@"blurEffect" properties:args def:UIBlurEffectStyleLight];

  id bgColorVal = [args valueForKey:@"backgroundColor"];
  if (bgColorVal) {
    [_popoverBackgroundColor release];
    _popoverBackgroundColor = [[[TiUtils colorValue:bgColorVal] _color] retain];
  }

  _transitionStyle = transitionStyleFromValue([args valueForKey:@"transitionStyle"]);
  if (_transitionStyle < 0) _transitionStyle = 0;

  id durationVal = [args valueForKey:@"transitionDuration"];
  if (durationVal) {
    _transitionDuration = [durationVal doubleValue];
    if (_transitionDuration < 0) _transitionDuration = 0;
  }

  _dismissOnTapOutside = [TiUtils boolValue:@"dismissOnTapOutside" properties:args def:YES];

  id popoverBlurVal = [args valueForKey:@"popoverBlurStyle"];
  if (popoverBlurVal) {
    _popoverBlurStyle = [TiUtils intValue:popoverBlurVal];
  }
  // If not passed in show: args, keep the value set via createPopover property (or default -1 from init)

  NSDictionary *safeAreaDict = [args valueForKey:@"safeAreaInsets"];
  if (safeAreaDict && [safeAreaDict isKindOfClass:[NSDictionary class]]) {
    _containerSafeAreaInsets = UIEdgeInsetsMake(
        [TiUtils floatValue:@"top" properties:safeAreaDict def:10],
        [TiUtils floatValue:@"left" properties:safeAreaDict def:10],
        [TiUtils floatValue:@"bottom" properties:safeAreaDict def:10],
        [TiUtils floatValue:@"right" properties:safeAreaDict def:10]
    );
  }

  TiThreadPerformOnMainThread(
      ^{
        [self presentPopover];
      },
   NO);
}

- (void)presentPopover
{
  currentTiPopover = self;
  [contentViewProxy setProxyObserver:self];

  // Get source view and its frame in window coordinates
  UIView *sourceView = nil;
  if ([popoverView isKindOfClass:[TiViewProxy class]]) {
    sourceView = [(TiViewProxy *)popoverView valueForKey:@"view"];
  } else if ([popoverView isKindOfClass:[TiProxy class]]) {
    sourceView = [(TiProxy *)popoverView valueForKey:@"view"];
  }

  if (!sourceView || !sourceView.superview) {
    DebugLog(@"[ERROR] Cannot find source view for popover. Ignoring call");
    [self cleanup];
    return;
  }

  CGRect sourceRectInWindow = [sourceView.superview convertRect:sourceView.frame toView:nil];
  if (!CGRectEqualToRect(CGRectZero, popoverRect)) {
    // rect is an offset relative to the source view's position
    // Apply the rect's origin as an offset to the button's window-frame
    CGRect offsetRect = sourceRectInWindow;
    offsetRect.origin.x += popoverRect.origin.x;
    offsetRect.origin.y += popoverRect.origin.y;
    // Use rect's width/height if explicitly set (non-zero)
    if (popoverRect.size.width > 0) {
      offsetRect.size.width = popoverRect.size.width;
    }
    if (popoverRect.size.height > 0) {
      offsetRect.size.height = popoverRect.size.height;
    }
    sourceRectInWindow = offsetRect;
  }

  // Get the key window as our container (scene-aware, iOS 13+)
  UIView *keyWindow = nil;
  for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
    for (UIWindow *w in scene.windows) {
      if (w.isKeyWindow) {
        keyWindow = w;
        break;
      }
    }
    if (keyWindow) break;
  }
  if (!keyWindow) {
    keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
  }
  CGRect containerRect = keyWindow.bounds;

  // Compute content size
  [self updateContentSize];
  CGSize contentSize = popoverContentSize;

  // Ensure minimum content size
  contentSize.width = MAX(contentSize.width, _cornerRadius * 2);
  contentSize.height = MAX(contentSize.height, _cornerRadius * 2);

  // Determine arrow direction
  popoverArrowDirection = [self autoArrowDirectionForContentSize:contentSize
                                                      sourceRect:sourceRectInWindow
                                                   containerRect:containerRect];

  // Get the base direction (handles extended directions like RIGHT_TOP)
  UIPopoverArrowDirection baseDirection = baseArrowDirection(popoverArrowDirection);

  // Compute total popover size (content + arrow)
  CGFloat arrowExt = _showsArrow ? _arrowSize.height : 0;
  CGSize popoverSize;
  switch (baseDirection) {
    case UIPopoverArrowDirectionUp:
    case UIPopoverArrowDirectionDown:
      popoverSize = CGSizeMake(contentSize.width, contentSize.height + arrowExt);
      break;
    case UIPopoverArrowDirectionLeft:
    case UIPopoverArrowDirectionRight:
      popoverSize = CGSizeMake(contentSize.width + arrowExt, contentSize.height);
      break;
    default:
      popoverSize = CGSizeMake(contentSize.width, contentSize.height + arrowExt);
      break;
  }

  // Compute arrow point (where the arrow tip touches the source rect)
  CGPoint arrowPoint;
  switch (baseDirection) {
    case UIPopoverArrowDirectionUp:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMaxY(sourceRectInWindow));
      break;
    case UIPopoverArrowDirectionDown:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMinY(sourceRectInWindow));
      break;
    case UIPopoverArrowDirectionLeft:
      arrowPoint = CGPointMake(CGRectGetMaxX(sourceRectInWindow), CGRectGetMidY(sourceRectInWindow));
      break;
    case UIPopoverArrowDirectionRight:
      arrowPoint = CGPointMake(CGRectGetMinX(sourceRectInWindow), CGRectGetMidY(sourceRectInWindow));
      break;
    default:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMaxY(sourceRectInWindow));
      break;
  }

  // Compute popover origin: standard=centered, extended=corner-anchored
  CGFloat arrowEdgeOffset = _cornerRadius + _arrowSize.width / 2 + 5.0;
  CGPoint popoverOrigin;
  switch (popoverArrowDirection) {
    case UIPopoverArrowDirectionUp:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y);
      break;
    case UIPopoverArrowDirectionDown:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y - popoverSize.height);
      break;
    case UIPopoverArrowDirectionLeft:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - popoverSize.height / 2);
      break;
    case UIPopoverArrowDirectionRight:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - popoverSize.height / 2);
      break;
    case _POPOVER_ARROW_DIRECTION_RIGHT_TOP:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - arrowEdgeOffset);
      break;
    case _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - (popoverSize.height - arrowEdgeOffset));
      break;
    case _POPOVER_ARROW_DIRECTION_LEFT_TOP:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - arrowEdgeOffset);
      break;
    case _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - (popoverSize.height - arrowEdgeOffset));
      break;
    case _POPOVER_ARROW_DIRECTION_UP_LEFT:
      popoverOrigin = CGPointMake(arrowPoint.x - arrowEdgeOffset, arrowPoint.y);
      break;
    case _POPOVER_ARROW_DIRECTION_UP_RIGHT:
      popoverOrigin = CGPointMake(arrowPoint.x - (popoverSize.width - arrowEdgeOffset), arrowPoint.y);
      break;
    case _POPOVER_ARROW_DIRECTION_DOWN_LEFT:
      popoverOrigin = CGPointMake(arrowPoint.x - arrowEdgeOffset, arrowPoint.y - popoverSize.height);
      break;
    case _POPOVER_ARROW_DIRECTION_DOWN_RIGHT:
      popoverOrigin = CGPointMake(arrowPoint.x - (popoverSize.width - arrowEdgeOffset), arrowPoint.y - popoverSize.height);
      break;
    default:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y);
      break;
  }

  // Clamp within container
  UIEdgeInsets safeInsets = _containerSafeAreaInsets;
  CGRect safeContainerRect = UIEdgeInsetsInsetRect(containerRect, safeInsets);

  // Extended: fall back to centered if clamped significantly
  if (popoverArrowDirection > UIPopoverArrowDirectionAny) {
    CGFloat cx = popoverOrigin.x, cy = popoverOrigin.y;
    cx = MAX(cx, safeContainerRect.origin.x);
    cy = MAX(cy, safeContainerRect.origin.y);
    cx = MIN(cx, CGRectGetMaxX(safeContainerRect) - popoverSize.width);
    cy = MIN(cy, CGRectGetMaxY(safeContainerRect) - popoverSize.height);
    if (fabs(cx - popoverOrigin.x) > 10 || fabs(cy - popoverOrigin.y) > 10) {
      switch (baseDirection) {
        case UIPopoverArrowDirectionUp: popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y); break;
        case UIPopoverArrowDirectionDown: popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y - popoverSize.height); break;
        case UIPopoverArrowDirectionLeft: popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - popoverSize.height / 2); break;
        case UIPopoverArrowDirectionRight: popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - popoverSize.height / 2); break;
        default: break;
      }
    }
  }

  popoverOrigin.x = MAX(popoverOrigin.x, safeContainerRect.origin.x);
  popoverOrigin.y = MAX(popoverOrigin.y, safeContainerRect.origin.y);
  popoverOrigin.x = MIN(popoverOrigin.x, CGRectGetMaxX(safeContainerRect) - popoverSize.width);
  popoverOrigin.y = MIN(popoverOrigin.y, CGRectGetMaxY(safeContainerRect) - popoverSize.height);

  CGRect finalPopoverRect = {popoverOrigin, popoverSize};

  // Compute content rect (inside popover, offset by arrow)
  CGFloat arrowOffset = _showsArrow ? _arrowSize.height : 0;
  CGRect contentRect;
  switch (baseDirection) {
    case UIPopoverArrowDirectionUp:
      contentRect = CGRectMake(0, arrowOffset, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionDown:
      contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionLeft:
      contentRect = CGRectMake(arrowOffset, 0, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionRight:
      contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
      break;
    default:
      contentRect = CGRectMake(0, arrowOffset, contentSize.width, contentSize.height);
      break;
  }

  // Convert arrow point to popover-local coordinates
  CGPoint arrowPointInPopover = CGPointMake(arrowPoint.x - popoverOrigin.x, arrowPoint.y - popoverOrigin.y);

  // Clamp arrow point to prevent overlapping corners
  // Only clamp the cross-axis coordinate (x for vertical arrows, y for horizontal)
  if (_showsArrow) {
    CGFloat minX = _cornerRadius + _arrowSize.width / 2;
    CGFloat maxX = popoverSize.width - minX;
    CGFloat minY = _cornerRadius + _arrowSize.width / 2;
    CGFloat maxY = popoverSize.height - minY;
    switch (baseDirection) {
      case UIPopoverArrowDirectionUp:
      case UIPopoverArrowDirectionDown:
        // For vertical arrows, only clamp x (horizontal position)
        arrowPointInPopover.x = MAX(minX, MIN(arrowPointInPopover.x, maxX));
        break;
      case UIPopoverArrowDirectionLeft:
      case UIPopoverArrowDirectionRight:
        // For horizontal arrows, only clamp y (vertical position)
        arrowPointInPopover.y = MAX(minY, MIN(arrowPointInPopover.y, maxY));
        break;
      default:
        arrowPointInPopover.x = MAX(minX, MIN(arrowPointInPopover.x, maxX));
        break;
    }
  }


  // Create container view (full screen, for hit testing)
  _containerView = [[UIView alloc] initWithFrame:keyWindow.bounds];
  _containerView.backgroundColor = [UIColor clearColor];
  _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _containerView.accessibilityViewIsModal = YES;

  // Dim background
  if (_showsDimBackground) {
    popoverDarkenBackgroundView = [[UIView alloc] initWithFrame:keyWindow.bounds];
    popoverDarkenBackgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    popoverDarkenBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    popoverDarkenBackgroundView.alpha = 0.0;
    [_containerView addSubview:popoverDarkenBackgroundView];
  }

  // Blur background
  if (_blurBackground && !UIAccessibilityIsReduceTransparencyEnabled()) {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:_blurEffectStyle];
    popoverBlurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    popoverBlurEffectView.alpha = 0.0;
    popoverBlurEffectView.frame = keyWindow.bounds;
    popoverBlurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_containerView addSubview:popoverBlurEffectView];
  }

  // Generate bezier path for the popover shape
  UIBezierPath *popoverPath = [self popoverPathWithRect:finalPopoverRect
                                             arrowPoint:arrowPointInPopover
                                         arrowDirection:baseDirection
                                            contentRect:contentRect];

  // Shadow carrier — unmasked container that holds the clipped popover
  _shadowView = [[UIView alloc] initWithFrame:finalPopoverRect];
  _shadowView.backgroundColor = [UIColor clearColor];
  if (_shadowOpacity > 0 && _shadowRadius > 0) {
    _shadowView.layer.shadowColor = _shadowColor.CGColor;
    _shadowView.layer.shadowRadius = _shadowRadius;
    _shadowView.layer.shadowOpacity = _shadowOpacity;
    _shadowView.layer.shadowOffset = _shadowOffset;
    _shadowView.layer.shadowPath = popoverPath.CGPath;
  }
  [_containerView addSubview:_shadowView];

  // Create popover container view (clipped to shape) — sits inside shadow carrier
  _popoverContainerView = [[UIView alloc] initWithFrame:_shadowView.bounds];
  _popoverContainerView.backgroundColor = [UIColor clearColor];
  _popoverContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [_shadowView addSubview:_popoverContainerView];

  // Apply mask
  CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
  maskLayer.path = popoverPath.CGPath;
  _popoverContainerView.layer.mask = maskLayer;
  [maskLayer release];

  // Background view inside popover
  if (_popoverBlurStyle >= 0) {
      // Frosted glass / blur effect for popover body.
      // UIVisualEffectView blurs whatever is BEHIND it in the hierarchy,
      // so no opaque background view must sit between it and the window.
      UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:(UIBlurEffectStyle)_popoverBlurStyle];
      _popoverBodyBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
      _popoverBodyBlurView.frame = _popoverContainerView.bounds;
      _popoverBodyBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      [_popoverContainerView addSubview:_popoverBodyBlurView];

      // Optional tint overlay on top of blur for custom color tinting
      if (_popoverBackgroundColor) {
          _backgroundView = [[UIView alloc] initWithFrame:_popoverContainerView.bounds];
          _backgroundView.backgroundColor = _popoverBackgroundColor;
          _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
          [_popoverContainerView addSubview:_backgroundView];
      }
  } else {
      // Solid color background
      UIColor *bgColor = _popoverBackgroundColor ?: [UIColor whiteColor];
      _backgroundView = [[UIView alloc] initWithFrame:_popoverContainerView.bounds];
      _backgroundView.backgroundColor = bgColor;
      _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      [_popoverContainerView addSubview:_backgroundView];
  }

  // Content view inside popover
  if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
    [(TiWindowProxy *)contentViewProxy setIsManaged:YES];
    [(TiWindowProxy *)contentViewProxy windowWillOpen];
    [(TiWindowProxy *)contentViewProxy open:nil];
    [(TiWindowProxy *)contentViewProxy gainFocus];
    [(TiWindowProxy *)contentViewProxy reposition];
    [(TiWindowProxy *)contentViewProxy layoutChildrenIfNeeded];
  } else {
    [contentViewProxy windowWillOpen];
    [contentViewProxy reposition];
  }

  // Position content view within the popover
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  LayoutConstraint *cp = [contentViewProxy layoutProperties];
  CGSize screenSize = [[UIScreen mainScreen] bounds].size;
#ifndef TI_USE_AUTOLAYOUT
  if (TiDimensionIsDip(cp->left)) {
    contentInsets.left += TiDimensionCalculateValue(cp->left, screenSize.width);
  }
  if (TiDimensionIsDip(cp->top)) {
    contentInsets.top += TiDimensionCalculateValue(cp->top, screenSize.height);
  }
  if (TiDimensionIsDip(cp->right)) {
    contentInsets.right += TiDimensionCalculateValue(cp->right, screenSize.width);
  }
  if (TiDimensionIsDip(cp->bottom)) {
    contentInsets.bottom += TiDimensionCalculateValue(cp->bottom, screenSize.height);
  }
#endif

  // Add arrow offset in the arrow direction
  if (_showsArrow) {
    switch (baseDirection) {
      case UIPopoverArrowDirectionUp:
        contentInsets.top += _arrowSize.height;
        break;
      case UIPopoverArrowDirectionDown:
        contentInsets.bottom += _arrowSize.height;
        break;
      case UIPopoverArrowDirectionLeft:
        contentInsets.left += _arrowSize.height;
        break;
      case UIPopoverArrowDirectionRight:
        contentInsets.right += _arrowSize.height;
        break;
      default:
        contentInsets.top += _arrowSize.height;
        break;
    }
  }

  CGRect contentFrame = CGRectMake(
      contentInsets.left,
      contentInsets.top,
      _popoverContainerView.bounds.size.width - contentInsets.left - contentInsets.right,
      _popoverContainerView.bounds.size.height - contentInsets.top - contentInsets.bottom
  );
  [contentViewProxy view].frame = contentFrame;
  [_popoverContainerView addSubview:[contentViewProxy view]];

  // Border — add as a stroke-only shape layer
  if (_borderWidth > 0 && _borderColor) {
    [_borderLayer release];
    _borderLayer = [[CAShapeLayer alloc] init];
    _borderLayer.path = popoverPath.CGPath;
    _borderLayer.fillColor = nil;
    _borderLayer.strokeColor = _borderColor.CGColor;
    _borderLayer.lineWidth = _borderWidth;
    [_popoverContainerView.layer addSublayer:_borderLayer];
  }

  // Outside tap gesture
  _outsideTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(outsideTap:)];
  _outsideTapGesture.cancelsTouchesInView = NO;
  [_containerView addGestureRecognizer:_outsideTapGesture];

  // Add container to key window
  [keyWindow addSubview:_containerView];

  // Animate presentation — animate the shadow carrier so shadow moves with content
  if (animated) {
    if (_showsArrow && _transitionStyle == 0) {
      // Scale transition with anchor at arrow point
      CGPoint anchorPoint = [self anchorPointForArrowDirection:popoverArrowDirection arrowPoint:arrowPointInPopover popoverSize:popoverSize];
      CGPoint oldOrigin = _shadowView.frame.origin;
      _shadowView.layer.anchorPoint = anchorPoint;
      _shadowView.layer.position = CGPointMake(
          oldOrigin.x + anchorPoint.x * _shadowView.bounds.size.width,
          oldOrigin.y + anchorPoint.y * _shadowView.bounds.size.height
      );
      _shadowView.alpha = 0.0;
      _shadowView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } else if (_transitionStyle == 1) {
      // Fade transition
      _shadowView.alpha = 0.0;
    } else if (_transitionStyle == 2) {
      // Translate transition
      _shadowView.alpha = 0.0;
      CGPoint offset = [self translateOffsetForArrowDirection:popoverArrowDirection];
      _shadowView.transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
    }
    // transitionStyle == 3 (None): no initial setup needed

    // Dim / blur background fade-in
    if (popoverDarkenBackgroundView) {
      [UIView animateWithDuration:[self backgroundAnimationDuration] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self->popoverDarkenBackgroundView.alpha = 1.0;
      } completion:nil];
    }
    if (popoverBlurEffectView) {
      [UIView animateWithDuration:[self backgroundAnimationDuration] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        popoverBlurEffectView.alpha = 1.0;
      } completion:nil];
    }

    // Popover animation
    void (^animations)(void) = ^{
      self->_shadowView.alpha = 1.0;
      self->_shadowView.transform = CGAffineTransformIdentity;
    };

    if (_transitionStyle == 0 && _showsArrow) {
      [UIView animateWithDuration:[self animationDurationForTransition] delay:0 usingSpringWithDamping:0.68 initialSpringVelocity:0.5 options:0 animations:animations completion:^(BOOL finished) {
        [contentViewProxy windowDidOpen];
      }];
    } else {
      [UIView animateWithDuration:[self animationDurationForTransition] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:animations completion:^(BOOL finished) {
        [contentViewProxy windowDidOpen];
      }];
    }
  } else {
    _shadowView.alpha = 1.0;
    if (popoverDarkenBackgroundView) {
      popoverDarkenBackgroundView.alpha = 1.0;
    }
    if (popoverBlurEffectView) {
      popoverBlurEffectView.alpha = 1.0;
    }
    [contentViewProxy windowDidOpen];
  }
}

// Returns the animation duration to use: custom if set, otherwise default based on transition style
- (CGFloat)animationDurationForTransition
{
  if (_transitionDuration > 0) {
    return _transitionDuration;
  }
  // Default durations based on transition type
  switch (_transitionStyle) {
    case 0: // Scale (spring)
      return 0.38;
    case 1: // Fade
      return 0.25;
    case 2: // Translate
      return 0.25;
    case 3: // None
      return 0.0;
    default:
      return 0.25;
  }
}

// Returns the background animation duration (shorter than main popover)
- (CGFloat)backgroundAnimationDuration
{
  if (_transitionDuration > 0) {
    return _transitionDuration * 0.75; // background animates slightly faster
  }
  return 0.18;
}

- (CGPoint)anchorPointForArrowDirection:(UIPopoverArrowDirection)direction arrowPoint:(CGPoint)arrowPoint popoverSize:(CGSize)popoverSize
{
  if (!_showsArrow) return CGPointMake(0.5, 0.5);
  switch (direction) {
    case _POPOVER_ARROW_DIRECTION_RIGHT_TOP: return CGPointMake(1, 0);
    case _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM: return CGPointMake(1, 1);
    case _POPOVER_ARROW_DIRECTION_LEFT_TOP: return CGPointMake(0, 0);
    case _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM: return CGPointMake(0, 1);
    case _POPOVER_ARROW_DIRECTION_UP_LEFT: return CGPointMake(0, 0);
    case _POPOVER_ARROW_DIRECTION_UP_RIGHT: return CGPointMake(1, 0);
    case _POPOVER_ARROW_DIRECTION_DOWN_LEFT: return CGPointMake(0, 1);
    case _POPOVER_ARROW_DIRECTION_DOWN_RIGHT: return CGPointMake(1, 1);
    default: break;
  }
  switch (direction) {
    case UIPopoverArrowDirectionUp: return CGPointMake(arrowPoint.x / popoverSize.width, 0);
    case UIPopoverArrowDirectionDown: return CGPointMake(arrowPoint.x / popoverSize.width, 1);
    case UIPopoverArrowDirectionLeft: return CGPointMake(0, arrowPoint.y / popoverSize.height);
    case UIPopoverArrowDirectionRight: return CGPointMake(1, arrowPoint.y / popoverSize.height);
    default: return CGPointMake(0.5, 0);
  }
}

- (CGPoint)translateOffsetForArrowDirection:(UIPopoverArrowDirection)direction
{
  CGFloat offset = 20.0;
  switch (direction) {
    case _POPOVER_ARROW_DIRECTION_RIGHT_TOP: case _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM:
      return CGPointMake(offset, 0);
    case _POPOVER_ARROW_DIRECTION_LEFT_TOP: case _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM:
      return CGPointMake(-offset, 0);
    case _POPOVER_ARROW_DIRECTION_UP_LEFT: case _POPOVER_ARROW_DIRECTION_UP_RIGHT:
      return CGPointMake(0, -offset);
    case _POPOVER_ARROW_DIRECTION_DOWN_LEFT: case _POPOVER_ARROW_DIRECTION_DOWN_RIGHT:
      return CGPointMake(0, offset);
    default: break;
  }
  switch (direction) {
    case UIPopoverArrowDirectionUp: return CGPointMake(0, -offset);
    case UIPopoverArrowDirectionDown: return CGPointMake(0, offset);
    case UIPopoverArrowDirectionLeft: return CGPointMake(-offset, 0);
    case UIPopoverArrowDirectionRight: return CGPointMake(offset, 0);
    default: return CGPointMake(0, -offset);
  }
}

#pragma mark - Hide

- (void)hide:(id)args
{
  if (!popoverInitialized) {
    DebugLog(@"Popover is not showing. Ignoring call");
    return;
  }

  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
  BOOL isAnimated = [TiUtils boolValue:@"animated" properties:args def:NO];
  NSInteger hideTransitionStyle = transitionStyleFromValue([args valueForKey:@"transitionStyle"]);
  // If transitionStyle is explicitly passed to hide:, use it; otherwise use the one from show:
  if (hideTransitionStyle >= 0) {
      _transitionStyle = hideTransitionStyle;
  }

  // Override transition duration if passed to hide()
  id hideDurationVal = [args valueForKey:@"transitionDuration"];
  if (hideDurationVal) {
    CGFloat hideDuration = [hideDurationVal doubleValue];
    if (hideDuration > 0) {
      _transitionDuration = hideDuration;
    }
  }
  [self fireEvent:@"hide" withObject:nil];

  [closingCondition lock];
  isDismissing = YES;
  [closingCondition unlock];

  TiThreadPerformOnMainThread(
      ^{
          [self->contentViewProxy windowWillClose];

          if (isAnimated) {
              if (self->popoverBlurEffectView != nil) {
                  [UIView animateWithDuration:[self backgroundAnimationDuration] animations:^{
                      self->popoverBlurEffectView.alpha = 0.0;
                  }];
              }
              if (self->popoverDarkenBackgroundView != nil) {
                  [UIView animateWithDuration:[self backgroundAnimationDuration] animations:^{
                      self->popoverDarkenBackgroundView.alpha = 0.0;
                  }];
              }

              void (^dismissAnimations)(void) = ^{
                  self->_shadowView.alpha = 0.0;
                  switch (self->_transitionStyle) {
                      case 0: // Scale
                          self->_shadowView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                          break;
                      case 1: // Fade — already handled by alpha
                          break;
                      case 2: { // Translate
                          CGPoint offset = [self translateOffsetForArrowDirection:baseArrowDirection(self->popoverArrowDirection)];
                          self->_shadowView.transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
                          break;
                      }
                      case 3: // None
                          break;
                      default:
                          self->_shadowView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                          break;
                  }
              };

              [UIView animateWithDuration:[self animationDurationForTransition] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:dismissAnimations completion:^(BOOL finished) {
                  [self dismissAndCleanup];
              }];
          } else {
              if (self->popoverBlurEffectView) {
                  [self->popoverBlurEffectView removeFromSuperview];
                  self->popoverBlurEffectView = nil;
              }
              if (self->popoverDarkenBackgroundView) {
                  [self->popoverDarkenBackgroundView removeFromSuperview];
                  self->popoverDarkenBackgroundView = nil;
              }
              [self dismissAndCleanup];
          }
      },
   NO);
}

- (void)dismissAndCleanup
{
  if (popoverBlurEffectView) {
      [popoverBlurEffectView removeFromSuperview];
      popoverBlurEffectView = nil;
  }
  if (popoverDarkenBackgroundView) {
      [popoverDarkenBackgroundView removeFromSuperview];
      popoverDarkenBackgroundView = nil;
  }
  [self fireEvent:@"closed" withObject:nil];
  [self cleanup];
}

- (void)outsideTap:(UITapGestureRecognizer *)gesture
{
  if (!_dismissOnTapOutside) {
    return;
  }
  CGPoint location = [gesture locationInView:_popoverContainerView];
  if (![_popoverContainerView pointInside:location withEvent:nil]) {
    [self fireEvent:@"hide" withObject:nil];
    [self hide:@{@"animated": @YES}];
  }
}

#pragma mark - Cleanup

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

  // Remove views
  [_outsideTapGesture.view removeGestureRecognizer:_outsideTapGesture];
  [_outsideTapGesture release];
  _outsideTapGesture = nil;

  [_popoverContainerView removeFromSuperview];
  [_popoverContainerView release];
  _popoverContainerView = nil;

  [_backgroundView release];
  _backgroundView = nil;

  [_popoverBodyBlurView removeFromSuperview];
  [_popoverBodyBlurView release];
  _popoverBodyBlurView = nil;

  [_borderLayer removeFromSuperlayer];
  [_borderLayer release];
  _borderLayer = nil;

  [_shadowView removeFromSuperview];
  [_shadowView release];
  _shadowView = nil;

  [_containerView removeFromSuperview];
  [_containerView release];
  _containerView = nil;

  popoverInitialized = NO;
  popoverArrowDirection = UIPopoverArrowDirectionUnknown;

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
  RELEASE_TO_NIL(viewController);
  RELEASE_TO_NIL(popoverView);
  [self autorelease];
  [closingCondition lock];
  isDismissing = NO;
  [closingCondition signal];
  [closingCondition unlock];
}

#pragma mark - View Controller (still needed for content hosting)

- (UIViewController *)viewController
{
  if (viewController == nil) {
    if ([contentViewProxy isKindOfClass:[TiWindowProxy class]]) {
      [(TiWindowProxy *)contentViewProxy setIsManaged:YES];
      viewController = [[(TiWindowProxy *)contentViewProxy hostingController] retain];
    } else {
      viewController = [[TiViewController alloc] initWithViewProxy:contentViewProxy];
    }
  }
  return viewController;
}

#pragma mark - Proxy Observer

- (void)proxyDidRelayout:(id)sender
{
  if (sender == contentViewProxy && popoverInitialized) {
    // TODO: Reposition popover when content size changes
  }
}

#pragma mark - Device Rotation

- (void)deviceRotated:(NSNotification *)sender
{
  if (!popoverInitialized) return;
  TiThreadPerformOnMainThread(^{ [self repositionPopover]; }, NO);
}

- (void)updatePopover:(NSNotification *)notification
{
  if (!popoverInitialized) return;
  TiThreadPerformOnMainThread(^{ [self repositionPopover]; }, NO);
}

- (void)repositionPopover
{
  UIView *keyWindow = nil;
  for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
    for (UIWindow *w in scene.windows) {
      if (w.isKeyWindow) {
        keyWindow = w;
        break;
      }
    }
    if (keyWindow) break;
  }
  if (!keyWindow) {
    keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
  }
  CGRect containerRect = keyWindow.bounds;

  UIView *sourceView = nil;
  if ([popoverView isKindOfClass:[TiViewProxy class]])
    sourceView = [(TiViewProxy *)popoverView valueForKey:@"view"];
  else if ([popoverView isKindOfClass:[TiProxy class]])
    sourceView = [(TiProxy *)popoverView valueForKey:@"view"];
  if (!sourceView || !sourceView.superview) return;

  CGRect sourceRectInWindow = [sourceView.superview convertRect:sourceView.frame toView:nil];
  if (!CGRectEqualToRect(CGRectZero, popoverRect)) {
    // rect is a relative offset (v2.0.0 behavior)
    CGRect offsetRect = sourceRectInWindow;
    offsetRect.origin.x += popoverRect.origin.x;
    offsetRect.origin.y += popoverRect.origin.y;
    if (popoverRect.size.width > 0) {
      offsetRect.size.width = popoverRect.size.width;
    }
    if (popoverRect.size.height > 0) {
      offsetRect.size.height = popoverRect.size.height;
    }
    sourceRectInWindow = offsetRect;
  }

  // Recalculate content size in case layout changed
  [self updateContentSize];
  CGSize contentSize = popoverContentSize;
  contentSize.width = MAX(contentSize.width, _cornerRadius * 2);
  contentSize.height = MAX(contentSize.height, _cornerRadius * 2);

  CGFloat arrowExt = _showsArrow ? _arrowSize.height : 0;
  UIPopoverArrowDirection baseDir = baseArrowDirection(popoverArrowDirection);
  CGSize popoverSize;
  switch (baseDir) {
    case UIPopoverArrowDirectionUp: case UIPopoverArrowDirectionDown:
      popoverSize = CGSizeMake(contentSize.width, contentSize.height + arrowExt); break;
    case UIPopoverArrowDirectionLeft: case UIPopoverArrowDirectionRight:
      popoverSize = CGSizeMake(contentSize.width + arrowExt, contentSize.height); break;
    default:
      popoverSize = CGSizeMake(contentSize.width, contentSize.height + arrowExt); break;
  }

  CGPoint arrowPoint;
  switch (baseDir) {
    case UIPopoverArrowDirectionUp:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMaxY(sourceRectInWindow)); break;
    case UIPopoverArrowDirectionDown:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMinY(sourceRectInWindow)); break;
    case UIPopoverArrowDirectionLeft:
      arrowPoint = CGPointMake(CGRectGetMaxX(sourceRectInWindow), CGRectGetMidY(sourceRectInWindow)); break;
    case UIPopoverArrowDirectionRight:
      arrowPoint = CGPointMake(CGRectGetMinX(sourceRectInWindow), CGRectGetMidY(sourceRectInWindow)); break;
    default:
      arrowPoint = CGPointMake(CGRectGetMidX(sourceRectInWindow), CGRectGetMaxY(sourceRectInWindow)); break;
  }

  CGFloat arrowEdgeOffset = _cornerRadius + _arrowSize.width / 2 + 5.0;
  CGPoint popoverOrigin;
  switch (popoverArrowDirection) {
    case UIPopoverArrowDirectionUp:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y); break;
    case UIPopoverArrowDirectionDown:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y - popoverSize.height); break;
    case UIPopoverArrowDirectionLeft:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - popoverSize.height / 2); break;
    case UIPopoverArrowDirectionRight:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - popoverSize.height / 2); break;
    case _POPOVER_ARROW_DIRECTION_RIGHT_TOP:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - arrowEdgeOffset); break;
    case _POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width, arrowPoint.y - (popoverSize.height - arrowEdgeOffset)); break;
    case _POPOVER_ARROW_DIRECTION_LEFT_TOP:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - arrowEdgeOffset); break;
    case _POPOVER_ARROW_DIRECTION_LEFT_BOTTOM:
      popoverOrigin = CGPointMake(arrowPoint.x, arrowPoint.y - (popoverSize.height - arrowEdgeOffset)); break;
    case _POPOVER_ARROW_DIRECTION_UP_LEFT:
      popoverOrigin = CGPointMake(arrowPoint.x - arrowEdgeOffset, arrowPoint.y); break;
    case _POPOVER_ARROW_DIRECTION_UP_RIGHT:
      popoverOrigin = CGPointMake(arrowPoint.x - (popoverSize.width - arrowEdgeOffset), arrowPoint.y); break;
    case _POPOVER_ARROW_DIRECTION_DOWN_LEFT:
      popoverOrigin = CGPointMake(arrowPoint.x - arrowEdgeOffset, arrowPoint.y - popoverSize.height); break;
    case _POPOVER_ARROW_DIRECTION_DOWN_RIGHT:
      popoverOrigin = CGPointMake(arrowPoint.x - (popoverSize.width - arrowEdgeOffset), arrowPoint.y - popoverSize.height); break;
    default:
      popoverOrigin = CGPointMake(arrowPoint.x - popoverSize.width / 2, arrowPoint.y); break;
  }

  UIEdgeInsets safeInsets = _containerSafeAreaInsets;
  CGRect safeContainerRect = UIEdgeInsetsInsetRect(containerRect, safeInsets);
  popoverOrigin.x = MAX(popoverOrigin.x, safeContainerRect.origin.x);
  popoverOrigin.y = MAX(popoverOrigin.y, safeContainerRect.origin.y);
  popoverOrigin.x = MIN(popoverOrigin.x, CGRectGetMaxX(safeContainerRect) - popoverSize.width);
  popoverOrigin.y = MIN(popoverOrigin.y, CGRectGetMaxY(safeContainerRect) - popoverSize.height);

  // Recalculate contentRect and arrowPointInPopover for mask update
  CGFloat arrowOffset = _showsArrow ? _arrowSize.height : 0;
  CGRect contentRect;
  switch (baseDir) {
    case UIPopoverArrowDirectionUp:
      contentRect = CGRectMake(0, arrowOffset, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionDown:
      contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionLeft:
      contentRect = CGRectMake(arrowOffset, 0, contentSize.width, contentSize.height);
      break;
    case UIPopoverArrowDirectionRight:
      contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
      break;
    default:
      contentRect = CGRectMake(0, arrowOffset, contentSize.width, contentSize.height);
      break;
  }

  CGPoint arrowPointInPopover = CGPointMake(arrowPoint.x - popoverOrigin.x, arrowPoint.y - popoverOrigin.y);
  if (_showsArrow) {
    CGFloat minX = _cornerRadius + _arrowSize.width / 2;
    CGFloat maxX = popoverSize.width - minX;
    CGFloat minY = _cornerRadius + _arrowSize.width / 2;
    CGFloat maxY = popoverSize.height - minY;
    switch (baseDir) {
      case UIPopoverArrowDirectionUp:
      case UIPopoverArrowDirectionDown:
        arrowPointInPopover.x = MAX(minX, MIN(arrowPointInPopover.x, maxX));
        break;
      case UIPopoverArrowDirectionLeft:
      case UIPopoverArrowDirectionRight:
        arrowPointInPopover.y = MAX(minY, MIN(arrowPointInPopover.y, maxY));
        break;
      default:
        arrowPointInPopover.x = MAX(minX, MIN(arrowPointInPopover.x, maxX));
        break;
    }
  }

  // Reset anchor point / transform that may have been altered by scale animation
  _shadowView.transform = CGAffineTransformIdentity;
  _shadowView.layer.anchorPoint = CGPointMake(0.5, 0.5);
  _shadowView.layer.position = CGPointMake(
      _shadowView.frame.origin.x + _shadowView.bounds.size.width / 2,
      _shadowView.frame.origin.y + _shadowView.bounds.size.height / 2
  );

  [UIView animateWithDuration:0.25 animations:^{
    _shadowView.bounds = CGRectMake(0, 0, popoverSize.width, popoverSize.height);
    _shadowView.center = CGPointMake(popoverOrigin.x + popoverSize.width / 2,
                                    popoverOrigin.y + popoverSize.height / 2);

    // Update subviews to match new bounds (popoverContainerView auto-resizes with shadowView)
    _backgroundView.frame = _popoverContainerView.bounds;
    if (_popoverBodyBlurView) {
      _popoverBodyBlurView.frame = _popoverContainerView.bounds;
    }

    // Update content frame
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    LayoutConstraint *cp = [contentViewProxy layoutProperties];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
#ifndef TI_USE_AUTOLAYOUT
    if (TiDimensionIsDip(cp->left)) {
      contentInsets.left += TiDimensionCalculateValue(cp->left, screenSize.width);
    }
    if (TiDimensionIsDip(cp->top)) {
      contentInsets.top += TiDimensionCalculateValue(cp->top, screenSize.height);
    }
    if (TiDimensionIsDip(cp->right)) {
      contentInsets.right += TiDimensionCalculateValue(cp->right, screenSize.width);
    }
    if (TiDimensionIsDip(cp->bottom)) {
      contentInsets.bottom += TiDimensionCalculateValue(cp->bottom, screenSize.height);
    }
#endif
    if (_showsArrow) {
      switch (baseDir) {
        case UIPopoverArrowDirectionUp:
          contentInsets.top += _arrowSize.height;
          break;
        case UIPopoverArrowDirectionDown:
          contentInsets.bottom += _arrowSize.height;
          break;
        case UIPopoverArrowDirectionLeft:
          contentInsets.left += _arrowSize.height;
          break;
        case UIPopoverArrowDirectionRight:
          contentInsets.right += _arrowSize.height;
          break;
        default:
          contentInsets.top += _arrowSize.height;
          break;
      }
    }
    [contentViewProxy view].frame = CGRectMake(
        contentInsets.left,
        contentInsets.top,
        _popoverContainerView.bounds.size.width - contentInsets.left - contentInsets.right,
        _popoverContainerView.bounds.size.height - contentInsets.top - contentInsets.bottom
    );

    // Update mask path
    UIBezierPath *newPath = [self popoverPathWithRect:_popoverContainerView.bounds
                                           arrowPoint:arrowPointInPopover
                                       arrowDirection:baseDir
                                          contentRect:contentRect];
    CAShapeLayer *maskLayer = (CAShapeLayer *)_popoverContainerView.layer.mask;
    if (maskLayer) {
      maskLayer.path = newPath.CGPath;
    }

    // Update border path
    if (_borderLayer) {
      _borderLayer.path = newPath.CGPath;
    }

    // Update shadow path on carrier
    if (_shadowView) {
      _shadowView.layer.shadowPath = newPath.CGPath;
    }
  }];
}

@end