## NoopInputRecorder
##
## M0 default — literally does nothing. Present so gameplay code in later
## milestones can call it unconditionally without null checks.
class_name NoopInputRecorder
extends "res://src/systems/input/i_input_recorder.gd"
