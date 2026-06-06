# Release Notes — ti.popover v2.0.1

**Release Date:** 2026-06-06  
**Platform:** iOS  
**Module ID:** `ti.popover`

---

## 🎉 What's New

Version 2.0.1 is a maintenance release that fixes shadow animation synchronization and eliminates duplicate events.

---

## 🐛 Bug Fixes

### Shadow Animation Sync

The shadow now animates in perfect sync with the popover content across all transition styles (scale, fade, translate). Previously the shadow would appear instantly or lag behind the popover animation.

**Fix:** Shadow is now applied to an unmasked `_shadowView` that contains the masked popover container, preventing clipping and ensuring the shadow transforms together with the content.

### Duplicate `hide` Event on Outside Tap

Tapping outside the popover to dismiss no longer fires the `hide` event twice.

---

## ✨ New Features (since v2.0.0)

### Shadow Color (`shadowColor`)

Customize the shadow color with any hex string:

```javascript
var popover = ti_popover.createPopover({
    contentView: contentView,
    shadowColor: '#ff0000'  // Red shadow
});
```

### Shadow Offset (`shadowOffset`)

Offset the shadow independently from the popover:

```javascript
var popover = ti_popover.createPopover({
    contentView: contentView,
    shadowOffset: { x: 0, y: 6 }
});
```

### Extended Arrow Directions (Corner-Anchored)

8 arrow direction constants position the arrow at a specific corner with the popover extending away from that edge:

- `ARROW_DIRECTION_RIGHT_TOP` — Arrow at top-right, popover extends down
- `ARROW_DIRECTION_RIGHT_BOTTOM` — Arrow at bottom-right, popover extends up
- `ARROW_DIRECTION_LEFT_TOP` — Arrow at top-left, popover extends down
- `ARROW_DIRECTION_LEFT_BOTTOM` — Arrow at bottom-left, popover extends up
- `ARROW_DIRECTION_UP_LEFT` — Arrow at top-left, popover extends right
- `ARROW_DIRECTION_UP_RIGHT` — Arrow at top-right, popover extends left
- `ARROW_DIRECTION_DOWN_LEFT` — Arrow at bottom-left, popover extends right
- `ARROW_DIRECTION_DOWN_RIGHT` — Arrow at bottom-right, popover extends left

```javascript
var popover = ti_popover.createPopover({
    contentView: contentView,
    arrowDirection: ti_popover.ARROW_DIRECTION_RIGHT_TOP
});
```

### Custom Animation Duration (`transitionDuration`)

Full control over animation speed with values from `0.0` to `1.0` seconds:

```javascript
// Set at creation time
var popover = ti_popover.createPopover({
    contentView: contentView,
    transitionDuration: 0.3  // 300ms
});

// Override for show()
popover.show({
    view: button,
    transitionDuration: 0.5  // 500ms presentation
});

// Override for hide()
popover.hide({
    animated: true,
    transitionDuration: 0.2  // 200ms dismissal
});
```

When not set (or `0`), sensible defaults are used:
- **Scale (spring):** 0.38s
- **Fade / Translate:** 0.25s

### Device Rotation Support

The popover automatically repositions itself when the device rotates, maintaining the correct anchor point relative to the source view with smooth animation.

### Edge Clamping with Smart Fallback

If a corner-anchored direction would cause the popover to go off-screen, the module automatically falls back to standard centered positioning to prevent clipping.

### `rect` as View-Relative Offset

The `rect` property in `show()` is now interpreted as an **offset relative to the source view's position**, allowing precise control over anchor positioning without absolute coordinates.

```javascript
// Shift anchor point 50px right and 20px down from the source view
popover.show({
    view: button,
    rect: { x: 50, y: 20 }
});
```

---

## 🔧 Improvements

- **Scale animation anchor point** — Fixed for extended directions; popover now scales from the arrow position (corner) instead of center
- **Translate animation offset** — Extended directions use the correct directional offset
- **keyWindow deprecation fix** — Updated to use `connectedScenes` iteration for iOS 17+ compatibility
- **Clamping logic** — Improved edge detection with 10px threshold before falling back to centered positioning
- **Background animation timing** — Background/blur animations use 75% of main animation duration for polished feel

---

## 🧹 Cleanup

- All `NSLog` debug statements removed/commented out
- Unused helper functions removed (`arrowPositionOffsetForDirection`)
- Code quality improvements throughout the codebase

---

## 📚 Documentation

- **Complete rewrite** of `documentation/index.md` with comprehensive API reference
- **10 detailed examples** covering all features and use cases
- **New `example/app.js`** — Full demo app with all features
- Updated `README.md` with installation guide, API reference, and feature overview

---

## ⚠️ Breaking Changes

### `rect` Behavior Changed

In v1.x, the `rect` property in `show()` was interpreted as absolute parent-coordinates. In v2.0.0, it is now a **view-relative offset**.

**v1.x (absolute):**
```javascript
// Position at exact coordinates in parent view
popover.show({ view: button, rect: { x: 100, y: 200, width: 50, height: 50 } });
```

**v2.0.0+ (relative offset):**
```javascript
// Offset 50px right and 20px down from button's position
popover.show({ view: button, rect: { x: 50, y: 20 } });
```

---

## 📦 API Reference

### Constants

**Arrow Directions (Standard):**
`ARROW_DIRECTION_UP`, `ARROW_DIRECTION_DOWN`, `ARROW_DIRECTION_LEFT`, `ARROW_DIRECTION_RIGHT`, `ARROW_DIRECTION_ANY`, `ARROW_DIRECTION_UNKNOWN`

**Arrow Directions (Extended):**
`ARROW_DIRECTION_RIGHT_TOP`, `ARROW_DIRECTION_RIGHT_BOTTOM`, `ARROW_DIRECTION_LEFT_TOP`, `ARROW_DIRECTION_LEFT_BOTTOM`, `ARROW_DIRECTION_UP_LEFT`, `ARROW_DIRECTION_UP_RIGHT`, `ARROW_DIRECTION_DOWN_LEFT`, `ARROW_DIRECTION_DOWN_RIGHT`

**Transition Styles:**
`TRANSITION_STYLE_SCALE`, `TRANSITION_STYLE_FADE`, `TRANSITION_STYLE_TRANSLATE`, `TRANSITION_STYLE_NONE`

**Blur Styles:**
`BLUR_STYLE_LIGHT`, `BLUR_STYLE_DARK`, `BLUR_STYLE_EXTRA_LIGHT`

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `transitionDuration` | `Number` | `0` (auto) | Animation duration in seconds (0.0–1.0) |
| `shadowColor` | `String` | `'#000000'` | Shadow color (hex string) |
| `shadowOffset` | `Object` | `{x:0, y:0}` | Shadow offset `{x, y}` in DIP |

### Methods

- `createPopover(options)` — Create popover instance
- `show(options)` — Present popover with optional `transitionDuration` override
- `hide(options)` — Dismiss popover with optional `transitionDuration` override

---

## 🚀 Upgrade Guide

Upgrading from v1.x to v2.0.1:

1. Update `tiapp.xml`: `<module version="2.0.1">ti.popover</module>`
2. Review `rect` usage in `show()` calls — change from absolute to relative coordinates
3. Optional: Use new extended arrow directions for corner-anchored popovers
4. Optional: Customize animation speed with `transitionDuration`

---

## 👨‍💻 Author

Created by Marc Bender  
Copyright (c) 2026. All rights reserved.

## 📜 License

MIT License
