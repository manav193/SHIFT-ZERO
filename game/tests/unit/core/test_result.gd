## Unit tests for Result<T>.
extends "res://addons/gut/test.gd"

const Result := preload("res://src/core/result.gd")


func test_ok_carries_value():
    var r := Result.ok_(42)
    assert_true(r.ok)
    assert_eq(r.value, 42)


func test_err_carries_code_and_message():
    var r := Result.err("boom", "kaboom", {"n": 3})
    assert_false(r.ok)
    assert_eq(r.error.code, "boom")
    assert_eq(r.error.message, "kaboom")
    assert_eq(r.error.context.n, 3)


func test_ok_without_value():
    var r := Result.ok_()
    assert_true(r.ok)
    assert_null(r.value)
