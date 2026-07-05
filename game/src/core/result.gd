## Result
##
## Two-branch return type for any operation that can fail meaningfully.
## Callers MUST inspect .ok before using .value or .error.
##
## Usage:
##   var r := SaveService.load()
##   if r.ok:
##       state = r.value
##   else:
##       push_warning("Boot", r.error.message)
class_name Result
extends RefCounted

var ok: bool
var value: Variant
var error: ErrorInfo


static func ok_(value: Variant = null) -> Result:
    var r := Result.new()
    r.ok = true
    r.value = value
    return r


static func err(code: String, message: String, context: Dictionary = {}) -> Result:
    var r := Result.new()
    r.ok = false
    r.error = ErrorInfo.new(code, message, context)
    return r


class ErrorInfo:
    extends RefCounted

    var code: String
    var message: String
    var context: Dictionary

    func _init(code_: String, message_: String, context_: Dictionary = {}) -> void:
        code = code_
        message = message_
        context = context_

    func _to_string() -> String:
        return "[%s] %s %s" % [code, message, context]
