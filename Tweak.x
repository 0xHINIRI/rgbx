#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

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

%hook UIView
- (void)setBackgroundColor:(UIColor *)color {
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
    %orig(color);
}
%end
