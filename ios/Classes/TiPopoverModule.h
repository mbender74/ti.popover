/**
 * ti.popover
 *
 * Created by Your Name
 * Copyright (c) 2021 Your Company. All rights reserved.
 */

#import "TiModule.h"
#import <TitaniumKit/TiApp.h>

@interface TiPopoverModule : TiModule {

}

@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_UP;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_DOWN;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_LEFT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_RIGHT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_ANY;

// Extended arrow direction constants — base direction + position modifier
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_UP_LEFT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_UP_RIGHT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_DOWN_LEFT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_DOWN_RIGHT;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_LEFT_TOP;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_LEFT_BOTTOM;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_RIGHT_TOP;
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM;

@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_MATERIAL;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_DARK;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_DARK;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_DARK;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_DARK;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_DARK;

@property (nonatomic, readonly) NSString *TRANSITION_STYLE_SCALE;
@property (nonatomic, readonly) NSString *TRANSITION_STYLE_FADE;
@property (nonatomic, readonly) NSString *TRANSITION_STYLE_TRANSLATE;
@property (nonatomic, readonly) NSString *TRANSITION_STYLE_NONE;

- (id)createPopover:(id)args;

@end
