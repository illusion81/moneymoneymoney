// Rewarded ads.
//
// Real implementation is Google AdMob via the `google_mobile_ads` plugin:
// a RewardedAd loaded with an ad unit ID from the AdMob console, shown with
// `show(onUserEarnedReward: ...)`, and the reward granted only in that callback
// — never before, or users get paid for closing the ad early.
//
// It needs an AdMob account, per-platform app IDs in AndroidManifest.xml and
// Info.plist, and real devices. It does not run on Flutter web at all, which is
// what this demo is, so the mock below stands in and says so.
//
// One product judgement worth keeping: ads in a finance app aimed at students
// are a bad fit if they are gambling, BNPL, or trading ads — the exact
// categories that pay best. AdMob lets you block sensitive categories, and this
// app should block them. Earning revenue by showing a struggling student a
// payday-loan ad would undo the point of the product.

import 'dart:async';

class AdResult {
  const AdResult({required this.rewarded, this.amount = 0, this.message = ''});
  final bool rewarded;
  final int amount;
  final String message;
}

abstract class AdGateway {
  bool get isLive;
  Future<AdResult> showRewarded();
}

class MockAdGateway implements AdGateway {
  @override
  bool get isLive => false;

  @override
  Future<AdResult> showRewarded() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return const AdResult(
      rewarded: true,
      amount: 5,
      message: 'Demo ad — nothing was actually shown.',
    );
  }
}

/// Sketch only. See the note at the top of this file.
///
///   RewardedAd.load(
///     adUnitId: 'ca-app-pub-.../...',
///     request: const AdRequest(),
///     rewardedAdLoadCallback: RewardedAdLoadCallback(
///       onAdLoaded: (ad) => ad.show(
///         onUserEarnedReward: (_, reward) => grant(reward.amount.toInt()),
///       ),
///       onAdFailedToLoad: (err) => ...,
///     ),
///   );
class AdMobGateway implements AdGateway {
  @override
  bool get isLive => false; // flip once AdMob unit IDs exist

  @override
  Future<AdResult> showRewarded() async => const AdResult(
        rewarded: false,
        message: 'Ads are not configured in this build.',
      );
}
