#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

// الاسم, خط العرض, خط الطول
static NSArray *places;
static NSInteger idx = 0;
static NSHashTable *mgrs;
static UIButton *btn;

static CLLocation *fake(void) {
    NSArray *p = places[idx];
    return [[CLLocation alloc]
        initWithCoordinate:CLLocationCoordinate2DMake([p[1] doubleValue], [p[2] doubleValue])
        altitude:10 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
}

@interface CLLocationManager (LX)
- (void)lx_push;
@end

@implementation CLLocationManager (LX)
- (CLLocation *)lx_location { return fake(); }
- (void)lx_push {
    id d = self.delegate;
    if ([d respondsToSelector:@selector(locationManager:didUpdateLocations:)])
        [d locationManager:self didUpdateLocations:@[fake()]];
}
- (void)lx_start { [mgrs addObject:self]; [self lx_push]; }
- (void)lx_stop { [mgrs removeObject:self]; }
- (void)lx_request { [self lx_push]; }
@end

@interface LXHelper : NSObject
+ (void)tap;
+ (void)tick;
@end
@implementation LXHelper
+ (void)tap {
    idx = (idx + 1) % places.count;
    [btn setTitle:[@"📍 " stringByAppendingString:places[idx][0]] forState:UIControlStateNormal];
    for (CLLocationManager *m in mgrs.allObjects) [m lx_push];
}
+ (void)tick { for (CLLocationManager *m in mgrs.allObjects) [m lx_push]; }
@end

static UIWindow *keyWin(void) {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
        if ([s isKindOfClass:[UIWindowScene class]])
            for (UIWindow *w in ((UIWindowScene *)s).windows)
                if (w.isKeyWindow) return w;
    return nil;
}

static void sw(SEL a, SEL b) {
    Class c = [CLLocationManager class];
    method_exchangeImplementations(class_getInstanceMethod(c, a), class_getInstanceMethod(c, b));
}

__attribute__((constructor))
static void lx_init(void) {
    places = @[
        @[@"Madrid", @40.4168, @-3.7038],
        @[@"Casablanca", @33.5731, @-7.5898],
        @[@"Paris", @48.8566, @2.3522],
        @[@"London", @51.5074, @-0.1278],
        @[@"New York", @40.7128, @-74.0060]
    ];
    mgrs = [NSHashTable weakObjectsHashTable];
    sw(@selector(location), @selector(lx_location));
    sw(@selector(startUpdatingLocation), @selector(lx_start));
    sw(@selector(stopUpdatingLocation), @selector(lx_stop));
    sw(@selector(requestLocation), @selector(lx_request));

    [NSTimer scheduledTimerWithTimeInterval:1 target:[LXHelper class]
        selector:@selector(tick) userInfo:nil repeats:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        UIWindow *w = keyWin();
        if (!w) return;
        btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, 90, 150, 36);
        btn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        btn.layer.cornerRadius = 18;
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [btn setTitle:[@"📍 " stringByAppendingString:places[0][0]] forState:UIControlStateNormal];
        [btn addTarget:[LXHelper class] action:@selector(tap)
            forControlEvents:UIControlEventTouchUpInside];
        [w addSubview:btn];
    });
}
