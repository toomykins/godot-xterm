extends "res://addons/gut/test.gd"


class TestReadline:
	extends "res://addons/gut/test.gd"
	const Readline = preload("res://addons/godot_xterm/util/readline.gd")
	const Terminal = preload("res://addons/godot_xterm/terminal.gd")

	var rl: Readline
	var terminal: Terminal
	var thread: Thread

	func before_each():
		terminal = Terminal.new()
		add_child_autoqfree(terminal)
		rl = Readline.new(terminal)
		thread = Thread.new()

	func after_each():
		if thread.is_active():
			thread.wait_to_finish()

	func press_keys(keys):
		yield(get_tree(), "idle_frame")
		for key in keys:
			terminal.call_deferred("emit_signal", "key_pressed", key[0], key[1])

	func key(string: String) -> Array:
		var event = InputEventKey.new()

		if string.length() == 1:
			event.unicode = ord(string)

		match string:
			"\r":
				event.scancode = KEY_ENTER
			"\b":
				event.scancode = KEY_BACKSPACE

		return [string, event]


class TestBasic:
	extends TestReadline

	func test_immediate_return():
		thread.start(self, "press_keys", [key("\r")])
		var line = yield(rl.readline("hello> "), "completed")
		assert_eq(line, "")

	func test_basic_input():
		thread.start(
			self,
			"press_keys",
			[
				key("t"),
				key("e"),
				key("s"),
				key("t"),
				key("\r"),
			]
		)
		var line = yield(rl.readline("test> "), "completed")
		assert_eq(line, "test")

	func test_basic_input_no_prompt():
		thread.start(
			self,
			"press_keys",
			[
				key("o"),
				key("k"),
				key("\r"),
			]
		)
		var line = yield(rl.readline(), "completed")
		assert_eq(line, "ok")

	func test_basic_input_empty_prompt():
		thread.start(
			self,
			"press_keys",
			[
				key("h"),
				key("i"),
				key("\r"),
			]
		)
		var line = yield(rl.readline(""), "completed")
		assert_eq(line, "hi")

	func test_backspace_in_line():
		thread.start(
			self,
			"press_keys",
			[
				key("a"),
				key("b"),
				key("c"),
				key("\b"),
				key("d"),
				key("\r"),
			]
		)
		var line = yield(rl.readline("> "), "completed")
		assert_eq(line, "abd")

	func test_backspace_to_prompt():
		thread.start(
			self,
			"press_keys",
			[
				key("a"),
				key("\b"),
				key("\b"),
				key("\b"),
				key("\b"),
				key("b"),
				key("\r"),
			]
		)
		var line = yield(rl.readline("aprompt> "), "completed")
		var buffer = terminal.copy_all()
		assert_eq(buffer.strip_edges(false, true), "aprompt>")
		assert_eq(line, "b")

	func test_multi_line():
		var keys = []
		for _i in range(terminal.cols * 3):
			keys.append(key("a"))
		keys.append(key("\r"))

		thread.start(self, "press_keys", keys)
		var line = yield(rl.readline("> "), "completed")
		assert_eq(line, "a".repeat(terminal.cols * 3))

	func test_backspace_multi_line():
		var keys = []
		for _i in range(terminal.cols):
			keys.append(key("a"))
		for _j in range(terminal.cols):
			keys.append(key("b"))
		for _k in range(terminal.cols + 5):
			keys.append(key("\b"))
		keys.append(key("f"))
		keys.append(key("\r"))

		thread.start(self, "press_keys", keys)
		var line = yield(rl.readline("> "), "completed")
		assert_eq(line, "a".repeat(terminal.cols - 5) + "f")
		var buffer = terminal.copy_all()
		assert(buffer.strip_edges(false, true), "> " + "a".repeat(terminal.cols - 5) + "f")

#class TestHistory:
#	extends TestReadline
#
#	func test_add_history():
#		rl.history = ["1", "2", "3"]
#		rl.add_history("New line")
#		assert_eq(rl.history, ["1", "2", "3", "New line"])
#
#	func test_add_history_max_len():
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 3
#		rl.add_history("New line")
#		assert_eq(rl.history, ["2", "3", "New line"])
#
#	func test_add_history_0_max_len():
#		rl.history = []
#		rl.history_max_len = 0
#		rl.add_history("New line")
#		assert_eq(rl.history, [])
#
#	func test_equal_max_len():
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 3
#		assert_eq(rl.history, ["1", "2", "3"])
#
#	func test_larger_max_len():
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 4
#		assert_eq(rl.history, ["1", "2", "3"])
#
#	func test_smaller_max_len():
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 2
#		assert_eq(rl.history, ["2", "3"])
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 1
#		assert_eq(rl.history, ["3"])
#		rl.history = ["1", "2", "3"]
#		rl.history_max_len = 0
#		assert_eq(rl.history, [])
#		rl.history = ["1"]
#		rl.history_max_len = 0
#		assert_eq(rl.history, [])
