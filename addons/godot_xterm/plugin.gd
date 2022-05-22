tool
extends EditorPlugin

const LIBS := [
	"javascript.32.wasm",
	"linux.32.so",
	"linux.64.so",
	"osx.64.dylib",
	"windows.32.dll",
	"windows.64.dll"
]
const LIB_DIR := "res://addons/godot_xterm/native/bin"
const ZIP_FILE := "%s/libgodot-xterm-release.zip" % LIB_DIR

const Unzipper := preload("./util/unzipper.gd")

signal _native_libs_checked

var pty_supported := OS.get_name() in ["X11", "Server", "OSX"]
var asciicast_import_plugin
var xrdb_import_plugin
var terminal_panel: Control


# Downloads release builds of native libraries from GitHub if available, otherwise
# you will need to compile them yourself.
func _download_native_libs():
	var dir := Directory.new()
	var skip := true

	for lib in LIBS:
		if not dir.file_exists("%s/libgodot-xterm.%s" % [LIB_DIR, lib]):
			print("GodotXterm: Downloading native library libgodot-xterm.%s..." % lib)
			skip = false

	if skip:
		emit_signal("_native_libs_checked")
		return

	var config_file := ConfigFile.new()
	config_file.load("res://addons/godot_xterm/plugin.cfg")

	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_http_request_completed", [http_request])
	http_request.download_file = ZIP_FILE
	http_request.request(
		(
			"https://github.com/lihop/godot-xterm/releases/download/v%s/libgodot-xterm-release.zip"
			% config_file.get_value("plugin", "version")
		)
	)


func _on_http_request_completed(
	result: int,
	response_code: int,
	_headers: PoolStringArray,
	_body: PoolByteArray,
	http_request: HTTPRequest
):
	http_request.queue_free()
	var dir := Directory.new()
	if result == OK and response_code == 200:
		var unzipped := Unzipper.unzip(ZIP_FILE)
		if unzipped.error != OK:
			push_error("GodotXterm: Error unzipping file: %s" % ZIP_FILE)
		else:
			for path in unzipped.files:
				var target := "%s/%s" % [LIB_DIR, path.get_file()]
				if not dir.file_exists("%s/%s" % [LIB_DIR, path.get_file()]):
					if dir.copy(path, target) == OK:
						print("GodotXterm: Native library %s installed!" % path.get_file())
					else:
						push_error(
							"GodotXterm: Error installing native library %s" % path.get_file()
						)
				dir.remove(path)
			dir.remove("%s/libgodot-xterm-release" % LIB_DIR)
	else:
		push_warning(
			"GodotXterm: Error downloading native libraries. Please compile them yourself."
		)
	dir.remove(ZIP_FILE)
	push_warning("GodotXterm: Installed missing native libraries. A Godot restart may be required.")
	emit_signal("_native_libs_checked")


func _enter_tree():
	call_deferred("_download_native_libs")
	yield(self, "_native_libs_checked")

	asciicast_import_plugin = preload("./import_plugins/asciicast_import_plugin.gd").new()
	add_import_plugin(asciicast_import_plugin)

	xrdb_import_plugin = preload("./import_plugins/xrdb_import_plugin.gd").new()
	add_import_plugin(xrdb_import_plugin)

	var asciicast_script = preload("./resources/asciicast.gd")
	add_custom_type("Asciicast", "Animation", asciicast_script, null)

	var terminal_script = preload("./terminal.gd")
	var terminal_icon = preload("./nodes/terminal/terminal_icon.svg")
	add_custom_type("Terminal", "Control", terminal_script, terminal_icon)

	if pty_supported:
		var base_dir = get_script().resource_path.get_base_dir()
		var pty_icon = load("%s/nodes/pty/pty_icon.svg" % base_dir)
		var pty_script
		match OS.get_name():
			"X11", "Server", "OSX":
				pty_script = load("%s/nodes/pty/pty.gd" % base_dir)
		add_custom_type("PTY", "Node", pty_script, pty_icon)
		var terminal_settings_script = preload("./editor_plugins/terminal/settings/terminal_settings.gd")
		add_custom_type("TerminalSettings", "Resource", terminal_settings_script, null)
		terminal_panel = preload("./editor_plugins/terminal/terminal_panel.tscn").instance()
		terminal_panel.editor_plugin = self
		terminal_panel.editor_interface = get_editor_interface()
		add_control_to_bottom_panel(terminal_panel, "Terminal")


func _exit_tree():
	remove_import_plugin(asciicast_import_plugin)
	asciicast_import_plugin = null

	remove_import_plugin(xrdb_import_plugin)
	xrdb_import_plugin = null

	remove_custom_type("Asciicast")
	remove_custom_type("Terminal")

	if pty_supported:
		remove_custom_type("PTY")
		remove_custom_type("TerminalSettings")
		remove_control_from_bottom_panel(terminal_panel)
		terminal_panel.free()
