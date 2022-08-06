extends "res://addons/godot_xterm/nodes/pty/pty_native.gd"


func write(data):
	emit_signal("data_received", data)


func run_process(_delta: float):
	pass
