# ti.popover Module

## Description

A fully custom iOS Popover implementation for Appcelerator Titanium. Draws its own arrow and border using `UIBezierPath`, positions itself relative to a source view, and handles dismiss via tap gesture.

Designed to mirror the [Titanium `Ti.UI.iPad.Popover`](https://titaniumsdk.com/api/titanium/ui/ipad/popover.html) API while adding extensive appearance customization — frosted glass blur effects, dim backgrounds, multiple transition styles, and per-popover visual tuning.

**Platform:** iOS only  
**Module ID:** `ti.popover`

---

## Quick Start

```javascript
var ti_popover = require("ti.popover");

// 1. Create the content view
var contentView = Ti.UI.createView({
    width: 250,
    height: 200,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Hello from Popover!',
    color: '#333',
    top: 10,
    left: 10,
    right: 10
}));

// 2. Create the popover
var popover = ti_popover.createPopover({
    contentView: contentView
});

// 3. Show it anchored to a button
var button = Ti.UI.createButton({
    title: 'Show Popover',
    top: 50,
    width: 200,
    height: 44
});

button.addEventListener('click', function() {
    popover.show({
        view: button
    });
});

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });
win.add(button);
win.open();
```

---

## API Reference

### Module-Level Factory

#### `ti_popover.createPopover(args)`

Creates a new Popover instance.

| Property     | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `contentView` | `Ti.UI.View` or `Ti.UI.Window` | **Required.** The view displayed inside the popover. |
| `arrowDirection` | `Number` | Arrow direction constant (see below). Default: `POPOVER_ARROW_DIRECTION_ANY` (auto-detect). |
| `cornerRadius` | `Number` | Corner radius in DIP. Default: `10`. |
| `arrowWidth` | `Number` | Arrow base width in DIP. Default: `30`. |
| `arrowHeight` | `Number` | Arrow height (tip-to-base) in DIP. Default: `15`. |
| `borderWidth` | `Number` | Border stroke width in DIP. Default: `0` (no border). |
| `borderColor` | `String` | Border color as hex string (e.g. `'#333333'`). Default: none. |
| `shadowRadius` | `Number` | Shadow blur radius in DIP. Default: `5`. |
| `shadowOpacity` | `Number` | Shadow opacity (0.0–1.0). Default: `0.3`. |
| `backgroundColor` | `String` | Popover body background color. Default: white (`#ffffff`). |
| `showsArrow` | `Boolean` | Whether to display the arrow. Default: `true`. |
| `showsDimBackground` | `Boolean` | Dim the background behind the popover. Default: `false`. |
| `blurBackground` | `Boolean` | Apply frosted glass blur to the background behind the popover. Default: `false`. |
| `blurEffect` | `Number` | Blur effect style for the background (see constants). Default: `Light`. |
| `transitionStyle` | `Number` / `String` | Animation style (see constants). Default: `scale`. |
| `dismissOnTapOutside` | `Boolean` | Auto-dismiss when tapping outside. Default: `true`. |
| `popoverBlurStyle` | `Number` | Frosted glass blur for the popover body itself. Default: `-1` (solid color). |
| `safeAreaInsets` | `Object` | Object with `top`, `left`, `bottom`, `right` (DIP). Default: `10` on all sides. |

---

### Instance Methods

#### `popover.show(args)`

Presents the popover anchored to a source view.

| Property          | Type       | Description                                                                  |
|-------------------|------------|------------------------------------------------------------------------------|
| `view`            | `Ti.UI.View` | **Required.** The source view the popover anchors to.                          |
| `rect`            | `Object`   | Offset relative to the source view's position (`{x, y}` or `{left, top}`). Optionally includes `width`/`height` to override the source view's anchor size. When only `x`/`y` are set, the source view's own width/height are preserved. |
| `animated`        | `Boolean`  | Animate the presentation. Default: `true`.                                    |
| `cornerRadius`    | `Number`   | Override corner radius for this presentation.                                  |
| `arrowWidth`      | `Number`   | Override arrow base width for this presentation.                               |
| `arrowHeight`     | `Number`   | Override arrow height for this presentation.                                   |
| `borderWidth`     | `Number`   | Override border width for this presentation.                                   |
| `borderColor`     | `String`   | Override border color for this presentation.                                   |
| `shadowRadius`    | `Number`   | Override shadow radius for this presentation.                                  |
| `shadowOpacity`   | `Number`   | Override shadow opacity for this presentation.                                 |
| `backgroundColor`  | `String`   | Override background color for this presentation.                               |
| `showsArrow`      | `Boolean`  | Override: show/hide arrow for this presentation.                               |
| `showsDimBackground` | `Boolean` | Override: dim background for this presentation.                                |
| `blurBackground`  | `Boolean`  | Override: blur background for this presentation.                               |
| `transitionStyle` | `Number` / `String` | Override transition for this presentation.                                  |
| `dismissOnTapOutside` | `Boolean` | Override: dismiss on outside tap for this presentation.                       |
| `popoverBlurStyle`| `Number`   | Override popover body blur for this presentation.                              |
| `safeAreaInsets`  | `Object`   | Override safe area insets for this presentation.                               |

> **Note:** All appearance properties that can be set at `createPopover` time can also be passed to `show()`. Values passed to `show()` override the creation-time values for that specific presentation.

#### `popover.hide(args)`

Dismisses the popover.

| Property        | Type           | Description                                               |
|-----------------|----------------|-----------------------------------------------------------|
| `animated`      | `Boolean`      | Animate the dismissal. Default: `false`.                   |
| `transitionStyle` | `Number` / `String` | Override transition for dismissal. If not passed, the presentation transition style is reused. |

---

### Instance Properties

Set these after `createPopover()` but **before** calling `show()`. Changing them while the popover is visible has no effect.

#### `popover.arrowDirection`

| Type    | Default                           |
|---------|-----------------------------------|
| `Number` | `ti_popover.POPOVER_ARROW_DIRECTION_ANY` |

Controls the arrow direction. If set to `POPOVER_ARROW_DIRECTION_ANY`, the module auto-detects the best direction based on available space around the source view. Setting an explicit direction forces the arrow to that side regardless of space.

#### `popover.contentView`

| Type              |
|-------------------|
| `Ti.UI.View` or `Ti.UI.Window` |

The view shown inside the popover. Width and height should be set on the content view itself (using DIP values).

#### `popover.popoverBlurStyle`

| Type     | Default |
|----------|---------|
| `Number` | `-1`    |

Sets a frosted glass (blur) effect on the popover body itself. Pass a blur effect style constant (e.g. `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_LIGHT`). Set to `-1` for solid color.

---

### Events

#### `'closed'`

Fired when the popover has finished dismissing and its views are cleaned up.

```javascript
popover.addEventListener('closed', function(e) {
    Ti.API.info('Popover was closed');
});
```

#### `'hide'`

Fired when the user taps outside the popover (triggers auto-dismiss). This fires **before** the hide animation begins.

```javascript
popover.addEventListener('hide', function(e) {
    Ti.API.info('User tapped outside — popover will dismiss');
});
```

---

### Constants

#### Arrow Direction — Standard

| Constant                                      | Description                                      |
|-----------------------------------------------|--------------------------------------------------|
| `ti_popover.POPOVER_ARROW_DIRECTION_UP`       | Arrow points up (popover appears **below** the source view). |
| `ti_popover.POPOVER_ARROW_DIRECTION_DOWN`     | Arrow points down (popover appears **above** the source view). |
| `ti_popover.POPOVER_ARROW_DIRECTION_LEFT`     | Arrow points left (popover appears to the **right** of the source view). |
| `ti_popover.POPOVER_ARROW_DIRECTION_RIGHT`    | Arrow points right (popover appears to the **left** of the source view). |
| `ti_popover.POPOVER_ARROW_DIRECTION_ANY`      | Auto-detect the best direction based on available screen space. |

> **Auto-detect priority:** Up > Down > Left > Right. The module checks each direction in order and picks the first one with sufficient space.

#### Arrow Direction — Extended (Corner-Anchored)

Extended directions position the arrow at a specific corner of the popover and anchor the popover there, extending away from the edge. The arrow sits at a safe distance from the rounded corner.

| Constant                                                    | Arrow Position | Popover Extends |
|-------------------------------------------------------------|---------------|------------------|
| `ti_popover.POPOVER_ARROW_DIRECTION_RIGHT_TOP`              | Right edge, top | Down |
| `ti_popover.POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM`           | Right edge, bottom | Up |
| `ti_popover.POPOVER_ARROW_DIRECTION_LEFT_TOP`               | Left edge, top | Down |
| `ti_popover.POPOVER_ARROW_DIRECTION_LEFT_BOTTOM`            | Left edge, bottom | Up |
| `ti_popover.POPOVER_ARROW_DIRECTION_UP_LEFT`                | Top edge, left | Right |
| `ti_popover.POPOVER_ARROW_DIRECTION_UP_RIGHT`               | Top edge, right | Left |
| `ti_popover.POPOVER_ARROW_DIRECTION_DOWN_LEFT`              | Bottom edge, left | Right |
| `ti_popover.POPOVER_ARROW_DIRECTION_DOWN_RIGHT`             | Bottom edge, right | Left |

> **Example:** `RIGHT_TOP` — the arrow is positioned at the upper-right corner of the popover, pointing right toward the source view. The popover body extends downward from the arrow.

```javascript
var popover = ti_popover.createPopover({
    contentView: contentView,
    arrowDirection: ti_popover.POPOVER_ARROW_DIRECTION_RIGHT_TOP
});
```

#### Transition Style

| Constant                                  | Value    | Description                                                  |
|-------------------------------------------|----------|--------------------------------------------------------------|
| `ti_popover.TRANSITION_STYLE_SCALE`       | `'scale'` / `0` | Spring-scale animation from the arrow point (default).    |
| `ti_popover.TRANSITION_STYLE_FADE`        | `'fade'` / `1`  | Simple fade-in/fade-out.                                   |
| `ti_popover.TRANSITION_STYLE_TRANSLATE`   | `'translate'` / `2` | Slide in from the arrow direction, slide out the same way. |
| `ti_popover.TRANSITION_STYLE_NONE`        | `'none'` / `3`  | No animation — instant show/hide.                          |

> Pass either the string or the numeric value to `transitionStyle`. The module accepts both.

#### Blur Effect Style — Background & Popover Body

These constants can be used for `blurEffect` (background blur behind popover) and `popoverBlurStyle` (frosted glass on popover body).

| Constant                                                        | Description                    |
|-----------------------------------------------------------------|--------------------------------|
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL`       | Ultra-thin material (default tint) |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL`             | Thin material                  |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL`                  | Standard material              |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL`            | Thick material                 |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL`           | Chrome material                |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_LIGHT` | Ultra-thin material (light tint) |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_LIGHT`       | Thin material (light tint)     |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_LIGHT`            | Standard material (light tint) |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_LIGHT`      | Thick material (light tint)    |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_LIGHT`     | Chrome material (light tint)   |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL_DARK`  | Ultra-thin material (dark tint) |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THIN_MATERIAL_DARK`        | Thin material (dark tint)      |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_DARK`             | Standard material (dark tint)  |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_THICK_MATERIAL_DARK`       | Thick material (dark tint)     |
| `ti_popover.BLUR_EFFECT_STYLE_SYSTEM_CHROME_MATERIAL_DARK`      | Chrome material (dark tint)    |

> **Important:** If the user has enabled *Reduce Transparency* in iOS Settings → Accessibility, blur effects are automatically disabled and the popover falls back to solid colors.

---

## Examples

### Basic Popover

A simple popover anchored to a button with default settings (white background, arrow, scale animation).

```javascript
var ti_popover = require("ti.popover");

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });

var contentView = Ti.UI.createView({
    width: 280,
    height: 180,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Hello World!',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333',
    top: 15,
    left: 15,
    right: 15
}));
contentView.add(Ti.UI.createLabel({
    text: 'This is a basic popover example.',
    font: { fontSize: 14 },
    color: '#666',
    top: 45,
    left: 15,
    right: 15
}));
contentView.add(Ti.UI.createButton({
    title: 'Close',
    bottom: 15,
    right: 15,
    width: 80,
    height: 32
}));

var popover = ti_popover.createPopover({
    contentView: contentView
});

var button = Ti.UI.createButton({
    title: 'Show Popover',
    width: 200,
    height: 44,
    top: 100
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});

contentView.children[2].addEventListener('click', function() {
    popover.hide({ animated: true });
});

win.add(button);
win.open();
```

### Frosted Glass Popover

A translucent popover with a blur effect on the body and a dimmed background.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 260,
    height: 200,
    backgroundColor: 'transparent' // transparent so the blur shows through
});
contentView.add(Ti.UI.createLabel({
    text: 'Frosted Glass',
    font: { fontSize: 20, fontWeight: 'bold' },
    color: '#ffffff',
    top: 15,
    left: 15
}));
contentView.add(Ti.UI.createLabel({
    text: 'The popover body has a frosted glass effect. Notice how it blurs the content behind it.',
    font: { fontSize: 14 },
    color: '#ffffff',
    top: 45,
    left: 15,
    right: 15
}));

var popover = ti_popover.createPopover({
    contentView: contentView,
    popoverBlurStyle: ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL_LIGHT,
    showsDimBackground: true,
    cornerRadius: 14,
    arrowWidth: 36,
    arrowHeight: 18
});

var button = Ti.UI.createButton({
    title: 'Frosted Glass Popover',
    style: Ti.UI.iPhone.SystemButtonStyle.BORDERED,
    top: 100,
    width: 250
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});

var win = Ti.UI.createWindow({ backgroundColor: '#a0d8ef' });
win.add(button);
win.open();
```

### Popover with Border and Shadow

A styled popover with a custom border, shadow, and rounded corners.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 300,
    height: 220,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Styled Popover',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#2c3e50',
    top: 15,
    left: 15,
    right: 15
}));
contentView.add(Ti.UI.createLabel({
    text: 'This popover has a colored border, shadow, and larger corner radius.',
    font: { fontSize: 14 },
    color: '#7f8c8d',
    top: 45,
    left: 15,
    right: 15
}));

var popover = ti_popover.createPopover({
    contentView: contentView,
    cornerRadius: 16,
    borderWidth: 2,
    borderColor: '#3498db',
    shadowRadius: 10,
    shadowOpacity: 0.4,
    arrowWidth: 40,
    arrowHeight: 20,
    transitionStyle: ti_popover.TRANSITION_STYLE_TRANSLATE
});

var button = Ti.UI.createButton({
    title: 'Styled Popover',
    top: 100,
    width: 200,
    height: 44
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});

var win = Ti.UI.createWindow({ backgroundColor: '#ecf0f1' });
win.add(button);
win.open();
```

### Arrow Direction Control

Force a specific arrow direction instead of auto-detection.

```javascript
var ti_popover = require("ti.popover");

function createPopover(title, arrowDir) {
    var contentView = Ti.UI.createView({
        width: 220,
        height: 120,
        backgroundColor: '#ffffff'
    });
    contentView.add(Ti.UI.createLabel({
        text: title,
        font: { fontSize: 16, fontWeight: 'bold' },
        color: '#333',
        top: 15,
        left: 15,
        right: 15
    }));
    contentView.add(Ti.UI.createLabel({
        text: 'Arrow points ' + title.toLowerCase(),
        font: { fontSize: 13 },
        color: '#888',
        top: 45,
        left: 15,
        right: 15
    }));

    var popover = ti_popover.createPopover({
        contentView: contentView,
        arrowDirection: arrowDir
    });
    return popover;
}

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });

var directions = [
    { label: 'Arrow UP',    dir: ti_popover.POPOVER_ARROW_DIRECTION_UP,    top: 300 },
    { label: 'Arrow DOWN',  dir: ti_popover.POPOVER_ARROW_DIRECTION_DOWN,  top: 40 },
    { label: 'Arrow LEFT',  dir: ti_popover.POPOVER_ARROW_DIRECTION_LEFT,  left: 250, top: 150 },
    { label: 'Arrow RIGHT', dir: ti_popover.POPOVER_ARROW_DIRECTION_RIGHT, left: 20,  top: 150 }
];

directions.forEach(function(item) {
    var popover = createPopover(item.label, item.dir);
    var button = Ti.UI.createButton({
        title: item.label,
        width: 120,
        height: 44,
        top: item.top,
        left: item.left || 120
    });
    button.addEventListener('click', function() {
        popover.show({ view: button });
    });
    win.add(button);
});

win.open();
```

### Extended Arrow Directions (Corner-Anchored)

Extended directions place the arrow at a specific corner of the popover, and the popover extends away from that corner.

```javascript
var ti_popover = require("ti.popover");

function createPopover(title, arrowDir) {
    var contentView = Ti.UI.createView({
        width: 200,
        height: 150,
        backgroundColor: '#ffffff'
    });
    contentView.add(Ti.UI.createLabel({
        text: title,
        font: { fontSize: 16, fontWeight: 'bold' },
        color: '#333',
        top: 15,
        left: 15,
        right: 15
    }));

    var popover = ti_popover.createPopover({
        contentView: contentView,
        arrowDirection: arrowDir,
        cornerRadius: 12
    });
    return popover;
}

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });

// RIGHT_TOP: Arrow at top-right, popover extends DOWN
var popover1 = createPopover('RIGHT_TOP', ti_popover.POPOVER_ARROW_DIRECTION_RIGHT_TOP);
var btn1 = Ti.UI.createButton({
    title: 'RIGHT_TOP',
    width: 160,
    height: 44,
    top: 80,
    left: 200
});
btn1.addEventListener('click', function() {
    popover1.show({ view: btn1 });
});
win.add(btn1);

// LEFT_TOP: Arrow at top-left, popover extends DOWN
var popover2 = createPopover('LEFT_TOP', ti_popover.POPOVER_ARROW_DIRECTION_LEFT_TOP);
var btn2 = Ti.UI.createButton({
    title: 'LEFT_TOP',
    width: 160,
    height: 44,
    top: 140,
    left: 20
});
btn2.addEventListener('click', function() {
    popover2.show({ view: btn2 });
});
win.add(btn2);

// RIGHT_BOTTOM: Arrow at bottom-right, popover extends UP
var popover3 = createPopover('RIGHT_BOTTOM', ti_popover.POPOVER_ARROW_DIRECTION_RIGHT_BOTTOM);
var btn3 = Ti.UI.createButton({
    title: 'RIGHT_BOTTOM',
    width: 160,
    height: 44,
    top: 400,
    left: 200
});
btn3.addEventListener('click', function() {
    popover3.show({ view: btn3 });
});
win.add(btn3);

// LEFT_BOTTOM: Arrow at bottom-left, popover extends UP
var popover4 = createPopover('LEFT_BOTTOM', ti_popover.POPOVER_ARROW_DIRECTION_LEFT_BOTTOM);
var btn4 = Ti.UI.createButton({
    title: 'LEFT_BOTTOM',
    width: 160,
    height: 44,
    top: 460,
    left: 20
});
btn4.addEventListener('click', function() {
    popover4.show({ view: btn4 });
});
win.add(btn4);

win.open();
```

### Transition Styles Comparison

Try each of the four transition styles.

```javascript
var ti_popover = require("ti.popover");

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });

var styles = [
    { label: 'Scale (Default)',   style: 'scale' },
    { label: 'Fade',              style: 'fade' },
    { label: 'Translate',         style: 'translate' },
    { label: 'None (Instant)',    style: 'none' }
];

styles.forEach(function(item, i) {
    var contentView = Ti.UI.createView({
        width: 240,
        height: 140,
        backgroundColor: '#ffffff'
    });
    contentView.add(Ti.UI.createLabel({
        text: item.label,
        font: { fontSize: 16, fontWeight: 'bold' },
        color: '#333',
        top: 15,
        left: 15,
        right: 15
    }));
    contentView.add(Ti.UI.createLabel({
        text: 'Transition: ' + item.style,
        font: { fontSize: 13 },
        color: '#888',
        top: 45,
        left: 15,
        right: 15
    }));

    var popover = ti_popover.createPopover({
        contentView: contentView,
        transitionStyle: item.style,
        cornerRadius: 12
    });

    var button = Ti.UI.createButton({
        title: item.label,
        width: 220,
        height: 44,
        top: 40 + i * 54,
        left: 25
    });
    button.addEventListener('click', function() {
        popover.show({ view: button });
    });
    win.add(button);
});

win.open();
```

### Popover with TableView

Show a scrollable table inside the popover.

```javascript
var ti_popover = require("ti.popover");

var data = [
    'Home', 'Profile', 'Settings', 'Notifications',
    'Help & Support', 'About', 'Log Out'
];

var tableView = Ti.UI.createTableView({
    data: data.map(function(item) {
        return { title: item, hasDetail: false };
    })
});

var contentView = Ti.UI.createView({
    width: 260,
    height: 280,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Menu',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333',
    top: 10,
    left: 15,
    right: 15,
    height: 30
}));
tableView.top = 40;
tableView.bottom = 10;
tableView.left = 0;
tableView.right = 0;
contentView.add(tableView);

var popover = ti_popover.createPopover({
    contentView: contentView,
    cornerRadius: 12,
    showsDimBackground: true,
    dismissOnTapOutside: true
});

tableView.addEventListener('click', function(e) {
    Ti.API.info('Selected: ' + e.row.title);
    popover.hide({ animated: true });
});

var menuButton = Ti.UI.createButton({
    systemButton: Ti.UI.iPhone.SystemButtonMenu,
    top: 80,
    width: 50,
    height: 50
});
menuButton.addEventListener('click', function() {
    popover.show({ view: menuButton });
});

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });
win.add(menuButton);
win.open();
```

### Background Blur (Behind Popover)

Apply a frosted glass blur to the area behind the popover.

```javascript
var ti_popover = require("ti.popover");

// Add some colorful content to the window so the blur is visible
var win = Ti.UI.createWindow({ backgroundColor: '#ffffff' });
for (var i = 0; i < 8; i++) {
    win.add(Ti.UI.createView({
        width: 80,
        height: 80,
        borderRadius: 12,
        backgroundColor: ['#e74c3c', '#3498db', '#2ecc71', '#f39c12',
                          '#9b59b6', '#1abc9c', '#e67e22', '#34495e'][i],
        top: 60 + Math.floor(i / 4) * 100,
        left: 50 + (i % 4) * 90
    }));
}

var contentView = Ti.UI.createView({
    width: 240,
    height: 150,
    backgroundColor: 'rgba(255,255,255,0.15)'
});
contentView.add(Ti.UI.createLabel({
    text: 'Background Blur',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#ffffff',
    top: 15,
    left: 15
}));
contentView.add(Ti.UI.createLabel({
    text: 'The colorful blocks behind this popover are blurred.',
    font: { fontSize: 13 },
    color: '#ffffff',
    top: 45,
    left: 15,
    right: 15
}));

var popover = ti_popover.createPopover({
    contentView: contentView,
    blurBackground: true,
    blurEffect: ti_popover.BLUR_EFFECT_STYLE_SYSTEM_MATERIAL,
    showsArrow: true,
    cornerRadius: 14
});

var button = Ti.UI.createButton({
    title: 'Show Blur',
    bottom: 60,
    width: 200,
    height: 44
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});
win.add(button);
win.open();
```

### Event Handling

Respond to popover lifecycle events.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 260,
    height: 160,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Event Demo',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333',
    top: 15,
    left: 15
}));

var logLabel = Ti.UI.createLabel({
    text: '',
    font: { fontSize: 13 },
    color: '#888',
    top: 45,
    left: 15,
    right: 15
});
contentView.add(logLabel);

var popover = ti_popover.createPopover({
    contentView: contentView
});

popover.addEventListener('hide', function(e) {
    Ti.API.info('[Event] hide — user tapped outside');
    logLabel.text = 'hide event fired!';
});

popover.addEventListener('closed', function(e) {
    Ti.API.info('[Event] closed — popover fully dismissed');
    logLabel.text = 'closed event fired!';
});

var button = Ti.UI.createButton({
    title: 'Events Demo',
    top: 100,
    width: 200,
    height: 44
});
button.addEventListener('click', function() {
    logLabel.text = 'Popover shown';
    popover.show({ view: button });
});

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });
win.add(button);
win.open();
```

### No Arrow, Fade-In Popover

A minimalist card-style popover without an arrow.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 300,
    height: 180,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Card Popover',
    font: { fontSize: 20, fontWeight: 'bold' },
    color: '#2c3e50',
    top: 20,
    left: 20,
    right: 20
}));
contentView.add(Ti.UI.createLabel({
    text: 'No arrow, smooth fade transition, large corner radius, and a subtle shadow.',
    font: { fontSize: 14 },
    color: '#7f8c8d',
    top: 55,
    left: 20,
    right: 20
}));
contentView.add(Ti.UI.createButton({
    title: 'Got it',
    bottom: 20,
    right: 20,
    width: 100,
    height: 36
}));

var popover = ti_popover.createPopover({
    contentView: contentView,
    showsArrow: false,
    cornerRadius: 16,
    shadowRadius: 15,
    shadowOpacity: 0.15,
    transitionStyle: ti_popover.TRANSITION_STYLE_FADE,
    dismissOnTapOutside: true
});

contentView.children[2].addEventListener('click', function() {
    popover.hide({ animated: true });
});

var button = Ti.UI.createButton({
    title: 'Card Popover',
    top: 100,
    width: 200,
    height: 44
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});

var win = Ti.UI.createWindow({ backgroundColor: '#ecf0f1' });
win.add(button);
win.open();
```

### Offset Rect on Source View

The `rect` property in `show()` is an offset relative to the source view's position. Use it to shift the anchor point without changing the source view reference.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 200,
    height: 120,
    backgroundColor: '#ffffff'
});
contentView.add(Ti.UI.createLabel({
    text: 'Offset Anchor',
    font: { fontSize: 14, fontWeight: 'bold' },
    color: '#333',
    top: 15,
    left: 15
}));
contentView.add(Ti.UI.createLabel({
    text: 'The rect shifts the anchor 50px right and 30px down from the button origin.',
    font: { fontSize: 12 },
    color: '#888',
    top: 40,
    left: 15,
    right: 15
}));

var popover = ti_popover.createPopover({
    contentView: contentView
});

var button = Ti.UI.createButton({
    title: 'Show Popover',
    width: 180,
    height: 44,
    top: 100
});
button.addEventListener('click', function() {
    popover.show({
        view: button,
        rect: { x: 50, y: 30 }  // offset from button origin
    });
});

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });
win.add(button);
win.open();
```

### Programmatically Dismiss with Animation

Control dismissal from within the popover content.

```javascript
var ti_popover = require("ti.popover");

var contentView = Ti.UI.createView({
    width: 260,
    height: 200,
    backgroundColor: '#ffffff'
});

var headerLabel = Ti.UI.createLabel({
    text: 'Dismissible Popover',
    font: { fontSize: 18, fontWeight: 'bold' },
    color: '#333',
    top: 15,
    left: 15,
    right: 15
});
contentView.add(headerLabel);

var bodyLabel = Ti.UI.createLabel({
    text: 'Tap any button below to dismiss this popover with a different animation style.',
    font: { fontSize: 13 },
    color: '#666',
    top: 45,
    left: 15,
    right: 15
});
contentView.add(bodyLabel);

var closeScale = Ti.UI.createButton({
    title: 'Close (Scale)',
    top: 100,
    left: 15,
    width: 105,
    height: 36
});
closeScale.addEventListener('click', function() {
    popover.hide({
        animated: true,
        transitionStyle: ti_popover.TRANSITION_STYLE_SCALE
    });
});
contentView.add(closeScale);

var closeFade = Ti.UI.createButton({
    title: 'Close (Fade)',
    top: 100,
    right: 15,
    width: 105,
    height: 36
});
closeFade.addEventListener('click', function() {
    popover.hide({
        animated: true,
        transitionStyle: ti_popover.TRANSITION_STYLE_FADE
    });
});
contentView.add(closeFade);

var closeInstant = Ti.UI.createButton({
    title: 'Close (Instant)',
    top: 145,
    left: 15,
    width: 240,
    height: 36
});
closeInstant.addEventListener('click', function() {
    popover.hide({ animated: false });
});
contentView.add(closeInstant);

var popover = ti_popover.createPopover({
    contentView: contentView,
    dismissOnTapOutside: true
});

var button = Ti.UI.createButton({
    title: 'Show',
    top: 100,
    width: 200,
    height: 44
});
button.addEventListener('click', function() {
    popover.show({ view: button });
});

var win = Ti.UI.createWindow({ backgroundColor: '#f5f5f5' });
win.add(button);
win.open();
```

---

## Important Notes

### Single Popover

Only one popover can be displayed at a time. If you call `show()` on a new popover while another is visible, the existing one is automatically hidden first.

### `contentView` Dimensions

Set `width` and `height` on the **content view** (using DIP values). Setting `width` and `height` directly on the popover is not supported — the popover derives its size from the content view.

### Changing Properties While Visible

Appearance properties (`cornerRadius`, `arrowWidth`, `borderColor`, etc.) can only be changed **before** the first `show()` call. Changing them while the popover is already displayed has no effect. To apply new settings, create a new popover instance.

### Reduce Transparency

If the user has enabled *Reduce Transparency* in **Settings → Accessibility → Display & Text Size**, all blur effects (`blurBackground` and `popoverBlurStyle`) are automatically disabled. The popover will use solid colors instead.

### Auto-Detection Priority

When `arrowDirection` is set to `POPOVER_ARROW_DIRECTION_ANY`, the module tries each direction in this order and picks the first one with enough space:

1. **UP** — popover below source, arrow pointing up
2. **DOWN** — popover above source, arrow pointing down
3. **LEFT** — popover to the right of source, arrow pointing left
4. **RIGHT** — popover to the left of source, arrow pointing right

### Safe Area Insets

The `safeAreaInsets` property (default: 10 DIP on all sides) prevents the popover from being positioned at the very edge of the screen. Increase these values if your popover overlaps with navigation bars, tab bars, or other UI elements at the screen edges.

### `rect` as Offset

When passed to `show()`, the `rect` property is interpreted as an **offset relative to the source view's position**. The `x`/`left` and `y`/`top` values are added to the source view's origin. If `width` and `height` are not set (or are zero), the source view's own dimensions are used for the anchor rect.

```javascript
// Shift anchor point 50px right and 20px down from the button
popover.show({
    view: button,
    rect: { x: 50, y: 20 }
});
```

### Device Rotation

When the device rotates while a popover is displayed, the popover automatically repositions itself to maintain the correct anchor point relative to the source view. The animation is smooth and the popover adapts to the new screen orientation.

### Edge Clamping with Fallback

If an extended (corner-anchored) direction would cause the popover to go off-screen, the module automatically falls back to standard centered positioning. For example, `RIGHT_TOP` near the top-right corner will become a centered `RIGHT` arrow instead of being clipped.

### Animation Anchor Points

For extended directions, the scale animation anchor point is set to the appropriate corner (e.g., `RIGHT_TOP` anchors at top-right). This ensures the popover scales from the arrow position rather than the center, providing a more natural visual effect.

---

## Architecture

The popover is **not** based on `UIPopoverPresentationController`. Instead, it is a fully custom implementation that:

- Draws the popover shape (rounded rect + arrow) using `UIBezierPath` and a `CAShapeLayer` mask
- Computes positioning relative to the source view's window coordinates
- Clips the popover to the key window with configurable safe area insets
- Handles outside taps via a `UITapGestureRecognizer` on the container view
- Animates presentation/dismissal with `UIView` animations (spring-scale, fade, translate)
- Applies blur via `UIVisualEffectView` for both the popover body and the background

This approach provides maximum visual control and consistent behavior across all iOS versions and device sizes (iPhone and iPad).

---

## Author

Created by Marc Bender  
Copyright (c) 2024. All rights reserved.

## License

MIT License
