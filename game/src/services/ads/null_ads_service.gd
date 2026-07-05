## NullAdsService
##
## Used on platforms without ads (Web / Desktop) and when the user has
## the Remove-Ads entitlement. Every operation succeeds as a no-op reward=false.
class_name NullAdsService
extends "res://src/services/ads/i_ads_service.gd"


func init(_consent: Dictionary) -> void:
    print("Ads", "NullAdsService active (no ads on this platform/tier)")


func show_rewarded(placement: String) -> Result:
    return Result.ok_({"placement": placement, "reward_granted": false, "reason": "null_service"})


func show_interstitial(_placement: String) -> Result:
    return Result.ok_()


func can_show_interstitial(_placement: String) -> bool:
    return false
