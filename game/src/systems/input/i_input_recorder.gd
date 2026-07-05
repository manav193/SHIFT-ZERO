## IInputRecorder
##
## Ghost-Runs architectural seam (see docs/15_M0_ADDENDA.md §A4).
## Implementation deferred to v1.1. The no-op default keeps every
## call site compilable and testable today.
##
## Recording format spec: docs/decisions/ADR-012-ghost-run-format.md (draft).
class_name IInputRecorder
extends RefCounted


func start(_run_seed: int) -> void:
    pass


func record_tap(_t_ms: int, _x: float, _y: float) -> void:
    pass


func stop() -> PackedByteArray:
    return PackedByteArray()


func is_recording() -> bool:
    return false
