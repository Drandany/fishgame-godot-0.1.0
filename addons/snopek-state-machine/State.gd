@tool
extends Node

const StateMachine = preload("res://addons/snopek-state-machine/StateMachine.gd")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not get_parent() is StateMachine:
		warnings.append("Parent node must be a StateMachine node")
	return warnings

func _state_enter(info : Dictionary):
	pass
	
func _state_exit():
	pass
