## IAdsService
##
## Ads provider abstraction. Actual AdMob wiring lands in M4.
class_name IAdsService
extends RefCounted


func init(_consent: Dictionary) -> void:
    pass


func show_rewarded(_placement: String) -> Result:
    return Result.err("not_implemented", "IAdsService.show_rewarded")


func show_interstitial(_placement: String) -> Result:
    return Result.err("not_implemented", "IAdsService.show_interstitial")


func can_show_interstitial(_placement: String) -> bool:
    return false


func set_consent(_consent: Dictionary) -> void:
    pass
