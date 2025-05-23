extends "res://main/Screen.gd"

@onready var tab_container := $TabContainer
@onready var login_email_field := $TabContainer/Login/GridContainer/Email
@onready var login_password_field := $TabContainer/Login/GridContainer/Password

const SESSION_FILENAME := "user://session.json"

var email: String = ""
var password: String = ""

var _reconnect: bool = false
var _next_screen

#TODO do this when online button clicked
func _attempt_restore_session() -> void:
	if FileAccess.file_exists(SESSION_FILENAME):
		var file = FileAccess.open(SESSION_FILENAME, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()

			if parsed is Dictionary and parsed.has("token") and parsed.has("refresh_token"):
				var session = Online.nakama_client.restore_session(parsed.token)
				if session.is_expired():
					session = await Online.nakama_client.session_refresh_async(parsed.refresh_token)
				if not session.is_expired():
					Online.nakama_session = session
					return

	# If session restore failed, show login screen
	tab_container.current_tab = 0

func _save_session(session: NakamaSession) -> void:
	var file = FileAccess.open(SESSION_FILENAME, FileAccess.WRITE)
	if file:
		var data = {
			"token": session.token,
			"refresh_token": session.refresh_token
		}
		file.store_line(JSON.stringify(data))
		file.close()

func _show_screen(info: Dictionary = {}) -> void:
	_reconnect = info.get("reconnect", false)
	_next_screen = info.get("next_screen", "MatchScreen")
	tab_container.current_tab = 0

func do_login(save_session: bool = false) -> void:
	visible = false

	ui_layer.show_message(_reconnect if _reconnect else "Logging in...")
	
	var nakama_session = await Online.nakama_client.authenticate_email_async(email, password, null, false)

	if nakama_session.is_exception():
		visible = true
		ui_layer.show_message("Login failed!")
		Online.nakama_session = null
	else:
		if save_session:
			_save_session(nakama_session)
		Online.nakama_session = nakama_session
		ui_layer.hide_message()
		if _next_screen:
			ui_layer.show_screen(_next_screen)

func _on_LoginButton_pressed() -> void:
	email = login_email_field.text.strip_edges()
	password = login_password_field.text.strip_edges()
	do_login($TabContainer/Login/GridContainer/SaveCheckBox.button_pressed)

func _on_CreateAccountButton_pressed() -> void:
	email = $"TabContainer/Create Account/GridContainer/Email".text.strip_edges()
	password = $"TabContainer/Create Account/GridContainer/Password".text.strip_edges()
	var username = $"TabContainer/Create Account/GridContainer/Username".text.strip_edges()
	var save_session = $"TabContainer/Create Account/GridContainer/SaveCheckBox".pressed

	if email == "":
		ui_layer.show_message("Must provide email")
		return
	if password == "":
		ui_layer.show_message("Must provide password")
		return
	if username == "":
		ui_layer.show_message("Must provide username")
		return

	visible = false
	ui_layer.show_message("Creating account...")

	var nakama_session = await Online.nakama_client.authenticate_email_async(email, password, username, true)

	if nakama_session.is_exception():
		visible = true
		var msg = nakama_session.get_exception().message
		if msg == "Invalid credentials.":
			msg = "E-mail already in use."
		elif msg == "":
			msg = "Unable to create account"
		ui_layer.show_message(msg)
		Online.nakama_session = null
	else:
		if save_session:
			_save_session(nakama_session)
		Online.nakama_session = nakama_session
		ui_layer.hide_message()
		ui_layer.show_screen("MatchScreen")
