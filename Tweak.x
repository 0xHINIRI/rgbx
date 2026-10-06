#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSHashTable *rgbViews;
static CADisplayLink *rgbLink;
static CGFloat rgbHue = 0;

static BOOL isBlack(UIColor *c) {
    CGFloat r,g,b,a;
    return [c getRed:&r green:&g blue:&b alpha:&a]
        && r<0.08 && g<0.08 && b<0.08 && a>0.9;
}

@interface RGBTick : NSObject
+ (void)tick;
@end
@implementation RGBTick
+ (void)tick {
    rgbHue += 0.002; if (rgbHue > 1) rgbHue = 0;
    UIColor *c = [UIColor colorWithHue:rgbHue saturation:1 brightness:0.6 alpha:1];
    for (UIView *v in rgbViews.allObjects) v.backgroundColor = c;
}
@end

@interface UIView (RGBX)
- (void)rgbx_setBackgroundColor:(UIColor *)color;
@end

@implementation UIView (RGBX)
- (void)rgbx_setBackgroundColor:(UIColor *)color {
    if (color && isBlack(color)) {
        if (!rgbViews) rgbViews = [NSHashTable weakObjectsHashTable];
        [rgbViews addObject:self];
        if (!rgbLink) {
            rgbLink = [CADisplayLink displayLinkWithTarget:[RGBTick class] selector:@selector(tick)];
            rgbLink.preferredFramesPerSecond = 20;
            [rgbLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
        color = [UIColor colorWithHue:rgbHue saturation:1 brightness:0.6 alpha:1];
    }
    [self rgbx_setBackgroundColor:color];
}
@end

__attribute__((constructor))
static void rgbx_init(void) {
    Method a = class_getInstanceMethod([UIView class], @selector(setBackgroundColor:));
    Method b = class_getInstanceMethod([UIView class], @selector(rgbx_setBackgroundColor:));
    method_exchangeImplementations(a, b);
}
