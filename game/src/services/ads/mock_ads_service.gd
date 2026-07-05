## MockAdsService
##
## Test double. Records all calls; can be scripted to succeed or fail.
class_name MockAdsService
extends "res://src/services/ads/i_ads_service.gd"

var calls: Array = []
var rewarded_should_grant: bool = true


func show_rewarded(placement: String) -> Result:
    calls.append({"op": "rewarded", "placement": placement})
    return Result.ok_({"placement": placement, "reward_granted": rewarded_should_grant})


func show_interstitial(placement: String) -> Result:
    calls.append({"op": "interstitial", "placement": placement})
    return Result.ok_()


func can_show_interstitial(_placement: String) -> bool:
    return true
