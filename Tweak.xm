#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ประกาศ Protocol และ Interface จำลองเพื่อให้คอมไพล์ผ่านโดยไม่ต้องมีไฟล์ Header ของ SDK
@protocol UnityAdsShowDelegate <NSObject>
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(NSInteger)state;
@end

@protocol LevelPlayRewardedVideoDelegate <NSObject>
- (void)didReceiveRewardForPlacement:(id)placementInfo withAdInfo:(id)adInfo;
- (void)didCloseWithAdInfo:(id)adInfo;
@end

@protocol ISRewardedVideoDelegate <NSObject>
- (void)rewardedVideoDidReceiveRewardForPlacement:(id)placementInfo;
- (void)rewardedVideoDidClose;
@end

// ==========================================
// 1. ดักจับ UnityAds (SDK หลักของเอนจิน Unity)
// ==========================================
%hook UnityAds

+ (BOOL)isReady:(NSString *)placementId {
    return YES;
}

+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId showDelegate:(id<UnityAdsShowDelegate>)showDelegate {
    if (showDelegate && [showDelegate respondsToSelector:@selector(unityAdsShowComplete:withFinishState:)]) {
        // State 2 = kUnityAdsFinishStateCompleted (ดูจบสมบูรณ์)
        [showDelegate unityAdsShowComplete:placementId withFinishState:2];
    }
}

%end

// ==========================================
// 2. ดักจับ IronSource (ระบบตัวกลางโฆษณายอดนิยมในเกมมือถือ)
// ==========================================
%hook IronSource

+ (BOOL)hasRewardedVideo {
    return YES;
}

+ (void)showRewardedVideoWithViewController:(UIViewController *)viewController {
    // บล็อกการเปิดหน้าต่างวิดีโอโฆษณา
}

+ (void)showRewardedVideoWithViewController:(UIViewController *)viewController placement:(nullable NSString *)placementName {
    // บล็อกการเปิดหน้าต่างวิดีโอโฆษณาตาม Placement
}

+ (void)showInterstitialWithViewController:(UIViewController *)viewController {
    // บล็อกโฆษณาคั่นฉาก (Interstitial)
}

%end

// ==========================================
// 3. ดักจับ AppLovin MAX (ALIncentivizedInterstitialAd / MARewardedAd)
// ==========================================
%hook MARewardedAd

- (BOOL)isReady {
    return YES;
}

- (void)showAdForPlacement:(nullable NSString *)placement {
    // ข้ามการแสดงผลโฆษณา
}

%end

%hook MAInterstitialAd

- (void)showAdForPlacement:(nullable NSString *)placement {
    // บล็อกโฆษณาคั่นฉาก
}

%end

// ==========================================
// 4. ดักจับ Google Mobile Ads (AdMob)
// ==========================================
%hook GADRewardedAd

- (void)presentFromRootViewController:(UIViewController *)rootViewController userDidEarnRewardHandler:(void (^)(void))rewardHandler {
    // เรียก Handler แจกรางวัลทันทีโดยไม่ต้องเปิดหน้าต่างโฆษณา
    if (rewardHandler) {
        rewardHandler();
    }
}

%end

%hook GADInterstitialAd

- (void)presentFromRootViewController:(UIViewController *)rootViewController {
    // บล็อกโฆษณาคั่นฉากของ AdMob
}

%end
