extends GCService
class_name GCMultiplayerService
## Basic multiplayer service built on Godot's multiplayer API.
## Handles lobby creation, player management, and basic sync.
## Swap this service for a custom implementation if using a different backend.

signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal lobby_created
signal lobby_joined
signal connection_failed

@export var default_port := 7000
@export var max_players := 4

var players: Dictionary = {}  # peer_id -> player_data
var is_host := false
var peer: ENetMultiplayerPeer


func start(_context: GCGameContext) -> void:
	super.start(_context)


func host_game(port: int = 0) -> Error:
	if port <= 0:
		port = default_port
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_players)
	if err != OK:
		push_error("GCMultiplayerService: Failed to create server: %s" % error_string(err))
		return err
	_setup_multiplayer()
	is_host = true
	players[1] = {}
	lobby_created.emit()
	return OK


func join_game(address: String, port: int = 0) -> Error:
	if port <= 0:
		port = default_port
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("GCMultiplayerService: Failed to join: %s" % error_string(err))
		return err
	_setup_multiplayer()
	is_host = false
	return OK


func leave_game() -> void:
	if peer:
		peer.close()
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.get_multiplayer().multiplayer_peer = null
	players.clear()
	is_host = false


func get_my_id() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_multiplayer().get_unique_id()
	return 0


func stop() -> void:
	leave_game()
	super.stop()


func _setup_multiplayer() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.get_multiplayer().multiplayer_peer = peer
	tree.get_multiplayer().peer_connected.connect(_on_peer_connected)
	tree.get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)
	tree.get_multiplayer().connected_to_server.connect(_on_connected)
	tree.get_multiplayer().connection_failed.connect(_on_connection_failed)


func _on_peer_connected(id: int) -> void:
	players[id] = {}
	player_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_left.emit(id)


func _on_connected() -> void:
	lobby_joined.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()
