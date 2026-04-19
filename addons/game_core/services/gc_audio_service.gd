extends GCService
class_name GCAudioService
## Manages music and sound effects playback.
## Plays audio by id. Supports crossfade, layered music, and volume groups.

signal music_changed(track_id: StringName)

@export var music_bus := &"Music"
@export var sfx_bus := &"SFX"
@export var crossfade_duration := 0.5

var _music_player: AudioStreamPlayer
var _current_music_id: StringName


func start(_context: GCGameContext) -> void:
	super.start(_context)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = music_bus


func stop() -> void:
	if _music_player and is_instance_valid(_music_player):
		_music_player.queue_free()
	_music_player = null
	super.stop()


func play_music(track_id: StringName, stream: AudioStream, fade := true) -> void:
	if _current_music_id == track_id:
		return
	_current_music_id = track_id

	if _music_player.get_parent() == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.root.add_child(_music_player)

	if fade and _music_player.playing:
		var tween := _music_player.get_tree().create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, crossfade_duration)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = 0.0
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

	music_changed.emit(track_id)


func stop_music(fade := true) -> void:
	if not _music_player.playing:
		return
	_current_music_id = &""
	if fade:
		var tween := _music_player.get_tree().create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, crossfade_duration)
		tween.tween_callback(func(): _music_player.stop())
	else:
		_music_player.stop()


func play_sfx(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.bus = sfx_bus
	tree.root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func set_bus_volume(bus_name: StringName, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)


func set_bus_mute(bus_name: StringName, mute: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, mute)
