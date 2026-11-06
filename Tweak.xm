%config(generator=internal)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

%group AdsHooks

// 1. ดักจับ UnityAds
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

// 2. ดักจับ IronSource
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

// 3. ดักจับ AppLovin MAX
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

// 4. ดักจับ Google Mobile Ads (AdMob)
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

%end

// รอให้ตัวเกมโหลดเข้าหน้าหลัก 2 วินาทีก่อนเริ่มทำงานเพื่อป้องกันแอปเด้ง
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        %init(AdsHooks);
    });
}
