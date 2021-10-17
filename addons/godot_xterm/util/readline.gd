# Copyright (c) 2021, Leroy Hopson (MIT License).
tool
extends Reference

const KeyCodes = {
	ESCAPE = "\u001b",
	ENTER = "\r",
	BACKSPACE = "\u0008",
	UP_ARROW = "\u001b[A",
	DOWN_ARROW = "\u001b[B",
	LEFT_ARROW = "\u001b[D",
	RIGHT_ARROW = "\u001b[C",
}

var terminal
var _prompt: String
var _cursor_pos_min: int
var _cursor_pos: int
var _line: String


func _init(p_terminal) -> void:
	terminal = p_terminal
	assert(terminal.has_method("write"))
	assert(terminal.has_signal("key_pressed"))
	assert("cols" in terminal)
	assert("rows" in terminal)


func readline(prompt := "> ") -> String:
	_prompt = prompt
	_cursor_pos_min = prompt.length()
	_cursor_pos = prompt.length()

	terminal.write(_prompt)

	var input = yield(terminal, "key_pressed")
	while input[1].scancode != KEY_ENTER:
		print(input[0])
		match input[0]:
			KeyCodes.BACKSPACE:
				_backspace()
			KeyCodes.UP_ARROW:
				# TODO: History prev.
				pass
			KeyCodes.DOWN_ARROW:
				# TODO: History next.
				pass
			KeyCodes.LEFT_ARROW, KeyCodes.RIGHT_ARROW:
				# TODO: Implement Me!
				pass
			_:
				terminal.write(input[0])
				_line += input[0]
				_cursor_pos += 1
				if _cursor_pos > 0 and _cursor_pos % int(terminal.cols) == 0:
					terminal.write("\u001bE")
		input = yield(terminal, "key_pressed")

	return _line


func _backspace() -> void:
	if _cursor_pos > _cursor_pos_min:
		if _cursor_pos % int(terminal.cols) == 0:
			terminal.write("\u001b[1A\u001b[%dC\u001b[K" % terminal.cols)
		else:
			terminal.write("\b \b")
		_line = _line.substr(0, _cursor_pos - _cursor_pos_min - 1)
		_cursor_pos -= 1


func _refresh_line() -> void:
	var num_rows := ceil(_cursor_pos / terminal.cols)
	for _row in range(num_rows):
		terminal.write("\r\u001b[2K\u001b[1A")
	terminal.write("\r\u001b[1B%s%s" % [_prompt, _line])
	_cursor_pos = _prompt.length()
	_cursor_pos += _line.length()

## TODO
#func _add_history(line: String) -> void:
#	_history.append(line)
#
#
## TODO
#func _load_history(filepath) -> int:
#	var file := File.new()
#	var err := file.open(filepath, File.READ)
#	if err == OK:
#		var line := file.get_line()
#		while line != "":
#			_history.append(line)
#			line = file.get_line()
#	file.close()
#	return err
#
#
## TODO
#func _save_history(filepath) -> int:
#	var file := File.new()
#	var err := file.open(filepath, File.WRITE)
#	if err == OK:
#		for line in _history:
#			assert(line is String)
#			file.store_line(line)
#	file.close()
#	return err
