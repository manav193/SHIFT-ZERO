## Unit tests for the EventBus autoload.
extends "res://addons/gut/test.gd"

var received: Array = []


func before_each():
    received = []
    EventBus.clear_all()


func _cb(payload: Dictionary):
    received.append(payload)


func test_subscribe_and_emit_delivers_payload():
    EventBus.subscribe("test/ping", _cb)
    EventBus.emit("test/ping", {"n": 1})
    assert_eq(received.size(), 1)
    assert_eq(received[0].n, 1)


func test_unsubscribe_stops_delivery():
    EventBus.subscribe("test/ping", _cb)
    EventBus.unsubscribe("test/ping", _cb)
    EventBus.emit("test/ping", {"n": 1})
    assert_eq(received.size(), 0)


func test_double_subscribe_delivers_once():
    EventBus.subscribe("test/ping", _cb)
    EventBus.subscribe("test/ping", _cb)
    EventBus.emit("test/ping", {})
    assert_eq(received.size(), 1)


func test_emit_with_no_subscribers_is_noop():
    EventBus.emit("test/nobody", {"x": 1})
    assert_eq(received.size(), 0)
