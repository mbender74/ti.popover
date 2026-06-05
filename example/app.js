/**
 * ti.popover - Comprehensive Example
 *
 * Demonstrates all features: standard/extended arrow directions,
 * appearance customization, transitions, rect offsets, and more.
 */
var ti_popover = require('ti.popover');

var win = Ti.UI.createWindow({
    backgroundColor: '#f5f5f5'
});

var headerLabel = Ti.UI.createLabel({
    text: 'ti.popover Examples',
    font: { fontSize: 22, fontWeight: 'bold' },
    color: '#333',
    top: 50,
    left: 20,
    right: 20,
    textAlign: 'center'
});
win.add(headerLabel);

var btnY = 110;
var btnSpacing = 55;

function createButton(title) {
    var btn = Ti.UI.createButton({
        title: title,
        top: btnY,
        left: 20,
        right: 20,
        height: 40,
        style: Ti.UI.iPhone.SystemButtonStyle.BORDERED
    });
    win.add(btn);
    btnY += btnSpacing;
    return btn;
}

// --- 1. Basic Popover ---
var btnBasic = createButton('1. Basic Popover (arrow down)');
btnBasic.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 250,
        height: 180,
        backgroundColor: '#ffffff',
        borderRadius: 10
    });
    content.add(Ti.UI.createLabel({
        text: 'Hello from Popover!',
        color: '#333',
        font: { fontSize: 18 },
        top: 15,
        left: 15,
        right: 15
    }));
    content.add(Ti.UI.createLabel({
        text: 'This is a basic popover with arrow pointing down.',
        color: '#666',
        font: { fontSize: 14 },
        top: 50,
        left: 15,
        right: 15
    }));
    content.add(Ti.UI.createButton({
        title: 'Dismiss',
        top: 130,
        left: 15,
        right: 15,
        height: 35
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: ti_popover.ARROW_DIRECTION_DOWN,
        cornerRadius: 10
    });

    popover.show({ view: btnBasic });
});

// --- 2. Arrow Directions ---
var btnDirections = createButton('2. Arrow Directions (cycle)');
var directionIndex = 0;
var directions = [
    { label: 'UP', value: ti_popover.ARROW_DIRECTION_UP },
    { label: 'DOWN', value: ti_popover.ARROW_DIRECTION_DOWN },
    { label: 'LEFT', value: ti_popover.ARROW_DIRECTION_LEFT },
    { label: 'RIGHT', value: ti_popover.ARROW_DIRECTION_RIGHT }
];

btnDirections.addEventListener('click', function() {
    var dir = directions[directionIndex % directions.length];
    directionIndex++;

    var content = Ti.UI.createView({
        width: 200,
        height: 120,
        backgroundColor: '#e3f2fd'
    });
    content.add(Ti.UI.createLabel({
        text: 'Arrow: ' + dir.label,
        color: '#1565c0',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Tap outside to dismiss',
        color: '#64b5f6',
        font: { fontSize: 12 },
        bottom: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: dir.value,
        cornerRadius: 8
    });

    popover.show({ view: btnDirections });
});

// --- 3. Extended Directions (Corner Anchored) ---
var btnExtended = createButton('3. Extended Directions (cycle)');
var extendedIndex = 0;
var extendedDirs = [
    { label: 'RIGHT_TOP', value: ti_popover.ARROW_DIRECTION_RIGHT_TOP },
    { label: 'RIGHT_BOTTOM', value: ti_popover.ARROW_DIRECTION_RIGHT_BOTTOM },
    { label: 'LEFT_TOP', value: ti_popover.ARROW_DIRECTION_LEFT_TOP },
    { label: 'LEFT_BOTTOM', value: ti_popover.ARROW_DIRECTION_LEFT_BOTTOM },
    { label: 'UP_LEFT', value: ti_popover.ARROW_DIRECTION_UP_LEFT },
    { label: 'UP_RIGHT', value: ti_popover.ARROW_DIRECTION_UP_RIGHT },
    { label: 'DOWN_LEFT', value: ti_popover.ARROW_DIRECTION_DOWN_LEFT },
    { label: 'DOWN_RIGHT', value: ti_popover.ARROW_DIRECTION_DOWN_RIGHT }
];

btnExtended.addEventListener('click', function() {
    var dir = extendedDirs[extendedIndex % extendedDirs.length];
    extendedIndex++;

    var content = Ti.UI.createView({
        width: 220,
        height: 150,
        backgroundColor: '#fff3e0'
    });
    content.add(Ti.UI.createLabel({
        text: dir.label,
        color: '#e65100',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Corner-anchored arrow\nPopover extends away from corner',
        color: '#ff9800',
        font: { fontSize: 13 },
        top: 45,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: dir.value,
        cornerRadius: 10
    });

    popover.show({ view: btnExtended });
});

// --- 4. Appearance: Blur + Dim Background ---
var btnBlur = createButton('4. Frosted Glass + Dim');
btnBlur.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 260,
        height: 200,
        backgroundColor: 'rgba(255,255,255,0.8)'
    });
    content.add(Ti.UI.createLabel({
        text: 'Frosted Glass Effect',
        color: '#333',
        font: { fontSize: 18, fontWeight: 'bold' },
        top: 15,
        left: 15,
        right: 15,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Blur background with dim overlay and shadow.',
        color: '#666',
        font: { fontSize: 14 },
        top: 50,
        left: 15,
        right: 15,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        blurBackground: true,
        blurStyle: ti_popover.BLUR_STYLE_DARK,
        showsDimBackground: true,
        dimBackgroundColor: 'rgba(0,0,0,0.3)',
        shadowColor: '#000000',
        shadowOpacity: 0.3,
        shadowRadius: 15,
        cornerRadius: 12
    });

    popover.show({ view: btnBlur });
});

// --- 5. Transitions ---
var btnTransition = createButton('5. Transitions (cycle)');
var transIndex = 0;
var transitions = [
    { label: 'Scale', value: ti_popover.TRANSITION_STYLE_SCALE },
    { label: 'Fade', value: ti_popover.TRANSITION_STYLE_FADE },
    { label: 'Translate', value: ti_popover.TRANSITION_STYLE_TRANSLATE },
    { label: 'None', value: ti_popover.TRANSITION_STYLE_NONE }
];

btnTransition.addEventListener('click', function() {
    var trans = transitions[transIndex % transitions.length];
    transIndex++;

    var content = Ti.UI.createView({
        width: 200,
        height: 130,
        backgroundColor: '#e8f5e9'
    });
    content.add(Ti.UI.createLabel({
        text: trans.label + ' Transition',
        color: '#2e7d32',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Dismiss on outside tap: YES',
        color: '#66bb6a',
        font: { fontSize: 13 },
        top: 45,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        transitionStyle: trans.value,
        dismissOnTapOutside: true,
        cornerRadius: 8
    });

    popover.show({ view: btnTransition, animated: true });
});

// --- 6. Rect Offset ---
var btnOffset = createButton('6. Rect Offset (custom anchor)');
btnOffset.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 180,
        height: 120,
        backgroundColor: '#f3e5f5'
    });
    content.add(Ti.UI.createLabel({
        text: 'Offset Anchor',
        color: '#7b1fa2',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Arrow positioned at custom rect offset from source view.',
        color: '#ab47bc',
        font: { fontSize: 12 },
        top: 40,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: ti_popover.ARROW_DIRECTION_UP,
        cornerRadius: 8
    });

    popover.show({
        view: btnOffset,
        rect: { x: 50, y: -20, width: 30, height: 30 }
    });
});

// --- 7. Border + Shadow ---
var btnBorder = createButton('7. Border + Shadow');
btnBorder.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 240,
        height: 160,
        backgroundColor: '#ffffff'
    });
    content.add(Ti.UI.createLabel({
        text: 'Styled Popover',
        color: '#1a237e',
        font: { fontSize: 18, fontWeight: 'bold' },
        top: 15,
        left: 15,
        right: 15,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Blue border with shadow effect.',
        color: '#5c6bc0',
        font: { fontSize: 14 },
        top: 50,
        left: 15,
        right: 15,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        borderWidth: 2,
        borderColor: '#3f51b5',
        shadowColor: '#3f51b5',
        shadowOpacity: 0.4,
        shadowRadius: 12,
        cornerRadius: 12
    });

    popover.show({ view: btnBorder });
});

// --- 8. Hide With Transition ---
var btnHide = createButton('8. Show & Fade Hide');
var hidePopover = null;

btnHide.addEventListener('click', function() {
    if (hidePopover && hidePopover.isValid) {
        hidePopover.hide({ animated: true, transitionStyle: ti_popover.TRANSITION_STYLE_FADE });
        return;
    }

    var content = Ti.UI.createView({
        width: 220,
        height: 150,
        backgroundColor: '#fce4ec'
    });
    content.add(Ti.UI.createLabel({
        text: 'Tap button again',
        color: '#c62828',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'to dismiss with fade animation.',
        color: '#e57373',
        font: { fontSize: 13 },
        top: 45,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'dismissOnTapOutside: false',
        color: '#ef9a9a',
        font: { fontSize: 11 },
        top: 80,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    hidePopover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: ti_popover.ARROW_DIRECTION_DOWN,
        dismissOnTapOutside: false,
        cornerRadius: 8
    });

    hidePopover.show({ view: btnHide });
});

// --- 9. No Arrow ---
var btnNoArrow = createButton('9. No Arrow');
btnNoArrow.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 200,
        height: 140,
        backgroundColor: '#e0f2f1'
    });
    content.add(Ti.UI.createLabel({
        text: 'Arrow Hidden',
        color: '#00695c',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'showsArrow: false\nLooks like a card/dialog.',
        color: '#4db6ac',
        font: { fontSize: 13 },
        top: 45,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        showsArrow: false,
        shadowColor: '#000000',
        shadowOpacity: 0.2,
        shadowRadius: 10,
        cornerRadius: 10
    });

    popover.show({ view: btnNoArrow });
});

// --- 10. Event Listeners ---
var btnEvents = createButton('10. Event Listeners');
btnEvents.addEventListener('click', function() {
    var content = Ti.UI.createView({
        width: 240,
        height: 180,
        backgroundColor: '#fffde7'
    });
    content.add(Ti.UI.createLabel({
        text: 'Event Demo',
        color: '#f57f17',
        font: { fontSize: 16, fontWeight: 'bold' },
        top: 10,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));
    content.add(Ti.UI.createLabel({
        text: 'Check console for show/hide events.',
        color: '#f9a825',
        font: { fontSize: 13 },
        top: 45,
        left: 10,
        right: 10,
        textAlign: 'center'
    }));

    var popover = ti_popover.createPopover({
        contentView: content,
        arrowDirection: ti_popover.ARROW_DIRECTION_DOWN,
        cornerRadius: 8
    });

    popover.addEventListener('show', function(e) {
        Ti.API.info('[ti.popover] show event fired, source: ' + (e.source ? 'yes' : 'no'));
    });

    popover.addEventListener('hide', function(e) {
        Ti.API.info('[ti.popover] hide event fired, source: ' + (e.source ? 'yes' : 'no'));
    });

    popover.addEventListener('dismiss', function(e) {
        Ti.API.info('[ti.popover] dismiss event fired, source: ' + (e.source ? 'yes' : 'no'));
    });

    popover.show({ view: btnEvents });
});

// Update header label position
headerLabel.bottom = btnY - 20;

win.open();
