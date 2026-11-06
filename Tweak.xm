#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ฟังก์ชันดักจับแบบปลอดภัย: ถ้าไม่มีคลาสนั้นในเกม จะข้ามทันที ไม่ทำให้เกมเด้ง
static void safeHookInstanceMethod(const char *className, const char *selectorName, IMP newImp) {
    Class cls = objc_getClass(className);
    if (!cls) return;
    SEL sel = sel_registerName(selectorName);
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        method_setImplementation(m, newImp);
    }
}

static void safeHookClassMethod(const char *className, const char *selectorName, IMP newImp) {
    Class cls = objc_getClass(className);
    if (!cls) return;
    SEL sel = sel_registerName(selectorName);
    Method m = class_getClassMethod(cls, sel);
    if (m) {
        method_setImplementation(m, newImp);
    }
}

// ฟังก์ชันจำลองสถานะโฆษณา
static BOOL returnYes(id self, SEL _cmd) {
    return YES;
}

static BOOL returnYesWithArg(id self, SEL _cmd, id arg1) {
    return YES;
}

static void doNothing(id self, SEL _cmd, id arg1) {
}

static void doNothing2(id self, SEL _cmd, id arg1, id arg2) {
}

// UnityAds: ส่งสถานะว่าดูโฆษณาจบแล้วทันที (FinishState = 2)
static void hook_UnityAds_show(id self, SEL _cmd, id viewController, id placementId, id showDelegate) {
    if (showDelegate) {
        SEL completeSel = sel_registerName("unityAdsShowComplete:withFinishState:");
        if ([showDelegate respondsToSelector:completeSel]) {
            void (*func)(id, SEL, id, NSInteger) = (void (*)(id, SEL, id, NSInteger))[showDelegate methodForSelector:completeSel];
            func(showDelegate, completeSel, placementId, 2);
        }
    }
}

// AdMob: เรียกฟังก์ชันแจกรางวัลทันที
static void hook_GADRewarded_present(id self, SEL _cmd, id rootVC, void (^rewardHandler)(void)) {
    if (rewardHandler) {
        rewardHandler();
    }
}

// แสดงป๊อปอัปแจ้งเตือนเมื่อเข้าเกมสำเร็จ
static void showLoadedAlert(NSString *detectedInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *foundWindow = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *w in windowScene.windows) {
                    if (w.isKeyWindow) {
                        foundWindow = w;
                        break;
                    }
                }
            }
        }
        if (!foundWindow) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            foundWindow = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }
        UIViewController *rootVC = foundWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Horrorfield NoAds ทำงานแล้ว!"
                                                                           message:detectedInfo
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"ตกลง" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// จุดเริ่มต้นทำงานเมื่อเปิดเกม (รอ 5 วินาทีให้เกมโหลดเสร็จก่อน)
__attribute__((constructor))
static void initNoAds(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. UnityAds
        safeHookClassMethod("UnityAds", "isReady:", (IMP)returnYesWithArg);
        safeHookClassMethod("UnityAds", "show:placementId:showDelegate:", (IMP)hook_UnityAds_show);

        // 2. IronSource
        safeHookClassMethod("IronSource", "hasRewardedVideo", (IMP)returnYes);
        safeHookClassMethod("IronSource", "showRewardedVideoWithViewController:", (IMP)doNothing);
        safeHookClassMethod("IronSource", "showRewardedVideoWithViewController:placement:", (IMP)doNothing2);
        safeHookClassMethod("IronSource", "showInterstitialWithViewController:", (IMP)doNothing);

        // 3. AppLovin MAX
        safeHookInstanceMethod("MARewardedAd", "isReady", (IMP)returnYes);
        safeHookInstanceMethod("MARewardedAd", "showAdForPlacement:", (IMP)doNothing);
        safeHookInstanceMethod("MAInterstitialAd", "showAdForPlacement:", (IMP)doNothing);

        // 4. Google AdMob
        safeHookInstanceMethod("GADRewardedAd", "presentFromRootViewController:userDidEarnRewardHandler:", (IMP)hook_GADRewarded_present);
        safeHookInstanceMethod("GADInterstitialAd", "presentFromRootViewController:", (IMP)doNothing);

        // 5. Appodeal (ระบบโฆษณาที่ค่ายเกม Skytec นิยมใช้)
        safeHookClassMethod("Appodeal", "isReadyForShowWithStyle:", (IMP)returnYesWithArg);
        safeHookClassMethod("Appodeal", "showAd:rootViewController:", (IMP)returnYes);

        // สแกนดูว่าในเกมมีคลาสโฆษณาตัวไหนอยู่บ้าง แล้วแจ้งเตือนบนหน้าจอ
        NSMutableArray *foundAds = [NSMutableArray array];
        NSArray *checkList = @[@"UnityAds", @"IronSource", @"MARewardedAd", @"GADRewardedAd", @"Appodeal", @"CASMediationManager"];
        for (NSString *clsName in checkList) {
            if (objc_getClass([clsName UTF8String]) != nil) {
                [foundAds addObject:clsName];
            }
        }
        
        NSString *msg = foundAds.count > 0 
            ? [NSString stringWithFormat:@"ตรวจพบระบบโฆษณาในเกม:\n%@", [foundAds componentsJoinedByString:@", "]]
            : @"โหลดไฟล์ .dylib สำเร็จ 100%!";
        showLoadedAlert(msg);
    });
}
