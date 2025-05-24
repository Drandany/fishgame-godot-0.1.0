extends Node

var nakama_server_key: String = "defaultkey"
var nakama_host: String = "gooseplayground.duckdns.org"
var nakama_port: int = 7350
var nakama_scheme: String = "http"

# Internal variables
var _nakama_client: NakamaClient = null
var _nakama_socket: NakamaSocket = null

# Public accessors
var nakama_client: NakamaClient: get = get_nakama_client

var nakama_session: NakamaSession: set = set_nakama_session

var nakama_socket: NakamaSocket: get = get_nakama_socket

# Internal state
var _nakama_socket_connecting := false

# Signals
signal session_changed(nakama_session)
signal session_connected(nakama_session)
signal socket_connected(nakama_socket)

func _ready() -> void:
	Nakama.process_mode = Node.PROCESS_MODE_ALWAYS

func get_nakama_client() -> NakamaClient:
	if _nakama_client == null:
		_nakama_client = Nakama.create_client(
			nakama_server_key,
			nakama_host,
			nakama_port,
			nakama_scheme,
			Nakama.DEFAULT_TIMEOUT,
			NakamaLogger.LOG_LEVEL.ERROR)
	return _nakama_client

func get_nakama_socket() -> NakamaSocket:
	return _nakama_socket

func set_nakama_session(_nakama_session: NakamaSession) -> void:
	if _nakama_socket:
		_nakama_socket.close()
		_nakama_socket = null
	
	nakama_session = _nakama_session
	emit_signal("session_changed", nakama_session)
	
	if nakama_session and not nakama_session.is_exception() and not nakama_session.is_expired():
		emit_signal("session_connected", nakama_session)

func connect_nakama_socket() -> void:
	if _nakama_socket != null or _nakama_socket_connecting:
		return
	
	_nakama_socket_connecting = true
	var new_socket = Nakama.create_socket_from(nakama_client)
	print("Connecting socket:", new_socket)
	
	await new_socket.connect_async(nakama_session)
	print("Socket connected to host?", new_socket.is_connected_to_host())

	_nakama_socket = new_socket
	_nakama_socket_connecting = false
	
	if _nakama_socket.is_connected_to_host():
		print("Socket connected successfully.")
		emit_signal("socket_connected", _nakama_socket)
	else:
		print("[Online.gd] Failed to connect Nakama socket.")

func is_nakama_socket_connected() -> bool:
	return _nakama_socket != null and _nakama_socket.is_connected_to_host()
