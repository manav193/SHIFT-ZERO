## MockBillingService
##
## In-memory billing double for tests and offline dev.
class_name MockBillingService
extends "res://src/services/billing/i_billing_service.gd"

var owned: PackedStringArray = PackedStringArray()
var prices: Dictionary = {"remove_ads": "$2.99"}


func query_products(skus: PackedStringArray) -> Result:
    var out := []
    for s in skus:
        out.append({"sku": s, "price": prices.get(s, "$0.99")})
    return Result.ok_(out)


func purchase(sku: String) -> Result:
    if not owned.has(sku):
        owned.append(sku)
    return Result.ok_({"sku": sku, "token": "mock_token_" + sku})


func restore_purchases() -> Result:
    return Result.ok_(owned)


func acknowledge(_token: String) -> Result:
    return Result.ok_()
