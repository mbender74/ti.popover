/**
 * ti.popover
 *
 * Created by Your Name
 * Copyright (c) 2021 Your Company. All rights reserved.
 */

#import "TiPopoverModule.h"
#import "TiPopoverProxy.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiPopoverModule


TiViewProxy *viewProxy;
TiViewProxy *parentProxy;
TiViewProxy *contentProxy;
UIViewController *popViewController;
UIVisualEffectView *blurEffectView;
UIView *darkenBackgroundView;
TiPopoverProxy *popoverProxy;


MAKE_SYSTEM_PROP(POPOVER_ARROW_DIRECTION_UP, UIPopoverArrowDirectionUp);
MAKE_SYSTEM_PROP(POPOVER_ARROW_DIRECTION_DOWN, UIPopoverArrowDirectionDown);
MAKE_SYSTEM_PROP(POPOVER_ARROW_DIRECTION_LEFT, UIPopoverArrowDirectionLeft);
MAKE_SYSTEM_PROP(POPOVER_ARROW_DIRECTION_RIGHT, UIPopoverArrowDirectionRight);
MAKE_SYSTEM_PROP(POPOVER_ARROW_DIRECTION_ANY, UIPopoverArrowDirectionAny);

MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL, UIBlurEffectStyleSystemUltraThinMaterial);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL, UIBlurEffectStyleSystemThinMaterial);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_MATERIAL, UIBlurEffectStyleSystemMaterial);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL, UIBlurEffectStyleSystemThickMaterial);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL, UIBlurEffectStyleSystemChromeMaterial);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_LIGHT, UIBlurEffectStyleSystemUltraThinMaterialLight);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_LIGHT, UIBlurEffectStyleSystemThinMaterialLight);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_LIGHT, UIBlurEffectStyleSystemMaterialLight);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_LIGHT, UIBlurEffectStyleSystemThickMaterialLight);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_LIGHT, UIBlurEffectStyleSystemChromeMaterialLight);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_DARK, UIBlurEffectStyleSystemUltraThinMaterialDark);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_DARK, UIBlurEffectStyleSystemThinMaterialDark);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_DARK, UIBlurEffectStyleSystemMaterialDark);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_DARK, UIBlurEffectStyleSystemThickMaterialDark);
MAKE_SYSTEM_PROP(BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_DARK, UIBlurEffectStyleSystemChromeMaterialDark);

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"09a963f0-c30f-40eb-957a-1ca6851c53fb";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"ti.popover";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}


- (id)createPopover:(id)args
{
    return [[TiPopoverProxy alloc] _initWithPageContext:[self executionContext] args:args];
 // [self throwException:@"this API is not available on non iPad devices" subreason:nil location:CODELOCATION];
}

- (NSString *)exampleProp
{
  // Example property getter. 
  // Call with "MyModule.exampleProp" or "MyModule.getExampleProp()"
  return @"Titanium rocks!";
}


@end
