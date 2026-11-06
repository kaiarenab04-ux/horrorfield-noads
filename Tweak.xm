#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ประกาศ Protocol และ Class ล่วงหน้าเพื่อให้คอมไพเลอร์รู้จักโครงสร้างทั้งหมด
@protocol UnityAdsShowDelegate <NSObject>
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(NSInteger)state;
@end

@interface UnityAds : NSObject
@end

@interface IronSource : NSObject
@end

@interface MARewardedAd : NSObject
@end

@interface MAInterstitialAd : NSObject
@end

@interface GADRewardedAd : NSObject
@end

@interface GADInterstitialAd : NSObject
@end

// ==========================================
// 1. ดักจับ UnityAds
// ==========================================
%hook UnityAds

+ (BOOL)isReady:(NSString *)placementId {
    return YES;
}

+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId showDelegate:(id<UnityAdsShowDelegate>)showDelegate {
    if (showDelegate && [showDelegate respondsToSelector:@selector(unityAdsShowComplete:withFinishState:)]) {
        [showDelegate unityAdsShowComplete:placementId withFinishState:2];
    }
}

%end

// ==========================================
// 2. ดักจับ IronSource
// ==========================================
%hook IronSource

+ (BOOL)hasRewardedVideo {
    return YES;
}

+ (void)showRewardedVideoWithViewController:(UIViewController *)viewController {
}

+ (void)showRewardedVideoWithViewController:(UIViewController *)viewController placement:(NSString *)placementName {
}

+ (void)showInterstitialWithViewController:(UIViewController *)viewController {
}

%end

// ==========================================
// 3. ดักจับ AppLovin MAX
// ==========================================
%hook MARewardedAd

- (BOOL)isReady {
    return YES;
}

- (void)showAdForPlacement:(NSString *)placement {
}

%end

%hook MAInterstitialAd

- (void)showAdForPlacement:(NSString *)placement {
}

%end

// ==========================================
// 4. ดักจับ Google Mobile Ads (AdMob)
// ==========================================
%hook GADRewardedAd

- (void)presentFromRootViewController:(UIViewController *)rootViewController userDidEarnRewardHandler:(void (^)(void))rewardHandler {
    if (rewardHandler) {
        rewardHandler();
    }
}

%end

%hook GADInterstitialAd

- (void)presentFromRootViewController:(UIViewController *)rootViewController {
}

%end
