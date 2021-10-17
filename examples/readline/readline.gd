extends "res://addons/godot_xterm/terminal.gd"

const Readline = preload("res://addons/godot_xterm/util/readline.gd")

var rl: Readline


func _ready():
	rl = Readline.new(self)
	while true:
		var line: String = yield(rl.readline("Enter something (anything): "), "completed")
		write("\r\nYou entered: %s\r\n" % line)
