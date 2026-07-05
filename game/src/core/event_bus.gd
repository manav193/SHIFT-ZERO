## EventBus
##
## Typed pub/sub. Channels are string constants defined in `core/events.gd`.
## Payloads are Dictionaries — small, self-describing, and inspectable.
##
## Do NOT hold long-lived references to callables — subscribers should
## `subscribe(channel, callable)` at _ready and `unsubscribe(...)` on tree exit.
extends Node

var _subs: Dictionary = {}   # channel -> Array[Callable]


func subscribe(channel: String, callable: Callable) -> void:
    if not _subs.has(channel):
        _subs[channel] = []
    if callable in _subs[channel]:
        return
    _subs[channel].append(callable)


func unsubscribe(channel: String, callable: Callable) -> void:
    if not _subs.has(channel):
        return
    _subs[channel].erase(callable)
    if _subs[channel].is_empty():
        _subs.erase(channel)


func emit(channel: String, payload: Dictionary = {}) -> void:
    if not _subs.has(channel):
        return
    # Iterate over a copy so subscribers may unsubscribe during dispatch.
    var callables: Array = _subs[channel].duplicate()
    for c in callables:
        if not (c as Callable).is_valid():
            _subs[channel].erase(c)
            continue
        (c as Callable).call(payload)


func has_subscribers(channel: String) -> bool:
    return _subs.has(channel) and not _subs[channel].is_empty()


func clear_all() -> void:
    _subs.clear()
