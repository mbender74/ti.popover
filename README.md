# ti.popover

## Description

Popover for iOS (Titanium Module) + more .... see in the example

same API like:
https://titaniumsdk.com/api/titanium/ui/ipad/popover.html


<img src="./example1.png" alt="Example (iOS)" width="300" />
<img src="./example2.png" alt="Example (iOS)" width="300" />



## Usage

	var TiPopover = require('ti.popover');

	var popover = TiPopover.createPopover({
	    arrowDirection:TiPopover.POPOVER_ARROW_DIRECTION_DOWN,
	    backgroundColor:'rgba(195,198,204,0.4)',
	    contentView:SOME_VIEW
	  });


	 popover.show({ 
          view: REFERENCE_VIEW,
          backgroundColor: 'rgba(0,0,0,0.2)',
          blurBackground: true,
          blurEffect: TiPopover.BLUR_EFFECT_STYLE_LIGHT,
          animated: true
        });	
