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
@property (nonatomic, readonly) NSNumber *POPOVER_ARROW_DIRECTION_UNKNOWN;

@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_EXTRA_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_LIGHT;
@property (nonatomic, readonly) NSNumber *BLUR_EFFECT_STYLE_DARK;



- (id)createPopover:(id)args;

@end
