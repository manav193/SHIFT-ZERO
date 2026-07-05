## ServiceLocator
##
## Resolves service INTERFACES to concrete implementations chosen per platform.
## Services are registered by `App` at boot; nothing else registers.
##
## Usage:
##   var analytics: IAnalyticsService = ServiceLocator.get_service("IAnalyticsService")
##   analytics.log_event("run_started", {"seed": 42})
extends Node

var _services: Dictionary = {}   # name -> instance
var _sealed: bool = false


func register(interface_name: String, instance: Object) -> void:
    if _sealed:
        Log.error("ServiceLocator", "attempted to register '%s' after seal()" % interface_name)
        return
    if _services.has(interface_name):
        Log.warn("ServiceLocator", "overriding registered '%s'" % interface_name)
    _services[interface_name] = instance
    Log.debug("ServiceLocator", "registered %s -> %s" % [interface_name, instance.get_class()])


func get_service(interface_name: String) -> Object:
    if not _services.has(interface_name):
        Log.error("ServiceLocator", "no service registered for '%s'" % interface_name)
        return null
    return _services[interface_name]


func has(interface_name: String) -> bool:
    return _services.has(interface_name)


func seal() -> void:
    _sealed = true
    Log.info("ServiceLocator", "sealed with %d services" % _services.size())


func list_services() -> PackedStringArray:
    var names := PackedStringArray()
    for k in _services.keys():
        names.append(str(k))
    return names
