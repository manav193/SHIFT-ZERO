## IBillingService
##
## Google Play Billing abstraction. Actual wiring lands in M4.
class_name IBillingService
extends RefCounted


func init() -> void:
    pass


func query_products(_skus: PackedStringArray) -> Result:
    return Result.err("not_implemented", "IBillingService.query_products")


func purchase(_sku: String) -> Result:
    return Result.err("not_implemented", "IBillingService.purchase")


func restore_purchases() -> Result:
    return Result.err("not_implemented", "IBillingService.restore_purchases")


func acknowledge(_token: String) -> Result:
    return Result.err("not_implemented", "IBillingService.acknowledge")
