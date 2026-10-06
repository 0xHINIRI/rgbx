#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static NSHashTable *views;
static CADisplayLink *link;
static CGFloat hue = 0;

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
    hue += 0.002; if (hue > 1) hue = 0;
    UIColor *c = [UIColor colorWithHue:hue saturation:1 brightness:0.6 alpha:1];
    for (UIView *v in views.allObjects) v.backgroundColor = c;
}
@end

%hook UIView
- (void)setBackgroundColor:(UIColor *)color {
    if (color && isBlack(color)) {
        if (!views) views = [NSHashTable weakObjectsHashTable];
        [views addObject:self];
        if (!link) {
            link = [CADisplayLink displayLinkWithTarget:[RGBTick class] selector:@selector(tick)];
            link.preferredFramesPerSecond = 20;
            [link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
        }
        color = [UIColor colorWithHue:hue saturation:1 brightness:0.6 alpha:1];
    }
    %orig(color);
}
%end
