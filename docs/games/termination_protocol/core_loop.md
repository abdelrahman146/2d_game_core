# Core Loop Integration Guide

Full wiring of the Termination Protocol game skeleton: title screen
through gameplay to game-over, using the `game_core` addon.

## Prerequisites

This guide builds on top of the
[chunk processing guide](chunk_processing.md).
Complete that setup first (chunk data resources, chunk scenes,
`GCStreamChunkSource`, `GCScrollDriver`, and `RunnerChunkSelector`).

## Gap analysis

| Mechanic | Coverage | What exists | What is missing |
|---|---|---|---|
| Horizontal movement | Full | `GCSimpleMovement` | --- |
| Wall-slide (scroll mod) | Full | `GCScrollDriver.apply_speed_modifier()` | Game-specific behavior |
| One-hit death | Full | `GCHealth` (max\_health=1) | --- |
| Chunk streaming | Full | `GCStreamChunkSource`, `GCChunkSelector` | --- |
| Scroll driver | Full | `GCScrollDriver` | --- |
| Flip / facing | Full | `GCFacing`, `GCAnimationBehavior` | --- |
| Collectible pickup | Full | `GCCollectible` + `GCAreaHost2D` | --- |
| Screen navigation | Full | `GCScreenRouter`, `GCScreen`, `GCScreenDef` | --- |
| HUD layer | Full | `GCHudLayer` | --- |
| Camera | Full | `GCCamera2D` (FIXED mode) | --- |
| Leaderboard | Partial | `GCLeaderboardService` (interface) | User implements backend |
| Virtual joystick | **Added** | `GCVirtualJoystick` | --- |
| Screen shake | **Added** | `GCCamera2D.shake()` | --- |
| Hit-stop / freeze | **Added** | `GCHitStop` | --- |
| Score tracking | Game-specific | --- | Game script |
| Parallax background | Godot-native | --- | `ParallaxBackground` setup |
| Death to game-over | Game-specific | `GCHealth.died` + router | Game script |
| Rewarded ad continue | Game-specific | --- | Ad SDK integration |

## Addon files added or modified

| File | Change |
|---|---|
| `addons/game_core/input/gc_virtual_joystick.gd` | New --- touch virtual joystick Control |
| `addons/game_core/core/gc_hit_stop.gd` | New --- freeze-frame utility Node |
| `addons/game_core/world/gc_camera.gd` | Modified --- added `shake()` method |
| `addons/game_core/plugin.gd` | Modified --- registered `GCHitStop` and `GCVirtualJoystick` |
| `tests/unit/test_camera_shake.gd` | New test suite |
| `tests/unit/test_hit_stop.gd` | New test suite |
| `tests/unit/test_virtual_joystick.gd` | New test suite |

## 1 --- Collision layers

Set these in **Project > Project Settings > Layer Names > 2D Physics**:

| Layer | Bit | Used by |
|---|---|---|
| Player | 1 | Player body |
| Walls | 2 | Boundary walls, tilemap platforms |
| Enemies | 3 | Enemy bodies |
| Projectiles | 4 | Bombs, bullets |
| Hazards | 5 | Gates, robot arms, deadly platform floors |
| Detection | 6 | Detection areas (drone sensing) |
| Collectibles | 7 | Pickup areas |

## 2 --- Full scene tree

```text
Root (Node)
├── GCBootstrap (autoload)
│   └── GCScreenRouter
│       ├── TitleScreen (GCScreen)
│       ├── GameplayScreen (GCScreen)
│       └── GameOverScreen (GCScreen)
├── GCHudLayer
│   ├── ScoreLabel (Label)
│   ├── DistanceLabel (Label)
│   └── GCVirtualJoystick
└── (current screen scene is added as child of the router)
```

The `GameplayScreen` scene (loaded by the router) contains:

```text
GameplayScreen (GCScreen)
├── GameWorld (Node2D)
│   ├── ParallaxBackground
│   │   ├── DistantCityLayer (ParallaxLayer)
│   │   │   └── Sprite2D
│   │   ├── MidBuildingsLayer (ParallaxLayer)
│   │   │   └── Sprite2D
│   │   └── NearStructuresLayer (ParallaxLayer)
│   │       └── Sprite2D
│   ├── GCWorldController
│   ├── GCScrollDriver
│   ├── BoundaryWalls (StaticBody2D)
│   │   ├── LeftWall (CollisionShape2D)
│   │   └── RightWall (CollisionShape2D)
│   ├── Player (GCCharacterHost2D)
│   │   ├── CollisionShape2D
│   │   ├── AnimatedSprite2D
│   │   ├── PlayerInputBehavior
│   │   ├── GCSimpleMovement
│   │   ├── GCHealth
│   │   ├── GCFacing
│   │   ├── GCAnimationBehavior
│   │   └── WallSlideDetector
│   └── GCCamera2D (mode=FIXED)
└── GCHitStop
```

## 3 --- Player scene

### Scene structure

```text
Player (GCCharacterHost2D)
├── CollisionShape2D    → RectangleShape2D (24 x 28 px)
├── AnimatedSprite2D    → spritesheet with idle, flip, wall_slide, fall
├── PlayerInputBehavior → game-specific DECIDE behavior (see below)
├── GCSimpleMovement    → default_speed = 200
├── GCHealth            → max_health = 1
├── GCFacing            → flip_sprite = true
├── GCAnimationBehavior → idle="idle", move="flip", death="death"
└── WallSlideDetector   → slide_speed_modifier = 0.5
```

### Inspector configuration

| Node | Export | Value |
|---|---|---|
| `CollisionShape2D` | shape | `RectangleShape2D` (24 x 28) |
| `Player` (host) | collision layer | 1 (Player) |
| `Player` (host) | collision mask | 2 (Walls), 5 (Hazards) |
| `GCSimpleMovement` | default\_speed | `200` |
| `GCHealth` | max\_health | `1` |
| `GCHealth` | invincibility\_time | `0.0` |
| `GCFacing` | flip\_sprite | `true` |
| `WallSlideDetector` | slide\_speed\_modifier | `0.5` |

### PlayerInputBehavior (game-specific)

Save at `res://scripts/player_input_behavior.gd`:

```gdscript
extends GCBehavior
class_name PlayerInputBehavior
## Reads input from a GCVirtualJoystick (or keyboard fallback)
## and writes move_direction + facing_direction to local_state.

@export var joystick: GCVirtualJoystick

## Keyboard fallback actions (set in Input Map).
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"


func _init() -> void:
	phase = Phase.DECIDE


func on_physics(host: Node, _delta: float) -> void:
	var dir := 0.0

	# Prefer joystick if available and pressed
	if joystick and joystick.is_pressed:
		dir = joystick.direction.x
	else:
		dir = Input.get_axis(action_left, action_right)

	host.local_state[&"move_direction"] = Vector2(dir, 0)
	if dir != 0.0:
		host.local_state[&"facing_direction"] = 1 if dir > 0 else -1
```

### WallSlideDetector (game-specific)

Already covered in
[chunk\_processing.md --- step 7](chunk_processing.md).
The behavior detects `is_on_wall()` and calls
`GCScrollDriver.apply_speed_modifier()`.

## 4 --- Collectible scenes

### Coin

```text
Coin (GCAreaHost2D)
├── CollisionShape2D  → CircleShape2D (radius 8)
├── AnimatedSprite2D  → spinning coin animation
└── GCCollectible
    ├── collect_group = &"player"
    ├── reward_type   = &"coin"
    ├── reward_amount = 1
    └── destroy_on_collect = true
```

| Node | Export | Value |
|---|---|---|
| `Coin` (host) | collision layer | 7 (Collectibles) |
| `Coin` (host) | collision mask | 1 (Player) |

### Cash bill

Identical to Coin except:

| Export | Value |
|---|---|
| reward\_type | `&"cash"` |
| reward\_amount | `5` (or higher for riskier placements) |

Place coins and cash bills inside chunk scenes at design time.

## 5 --- Score manager (game-specific)

Save at `res://scripts/score_manager.gd`.
Attach to the `GameplayScreen` node or the `GameWorld` root.

```gdscript
extends Node
class_name ScoreManager

signal score_updated(total: int)
signal distance_updated(distance: float)

var cash: int = 0
var distance: float = 0.0

var _scroll_driver: GCScrollDriver


func setup(scroll_driver: GCScrollDriver) -> void:
	_scroll_driver = scroll_driver


func _physics_process(delta: float) -> void:
	if _scroll_driver and _scroll_driver.active:
		distance += _scroll_driver.current_speed * delta
		distance_updated.emit(distance)


func add_cash(amount: int) -> void:
	cash += amount
	score_updated.emit(get_total_score())


func get_total_score() -> int:
	# 1 point per 100 pixels fallen + raw cash value
	return int(distance / 100.0) + cash


func reset() -> void:
	cash = 0
	distance = 0.0
```

### Connecting collectibles to score

In the gameplay screen script, after the world opens and chunks spawn,
connect each collectible's signal. The simplest approach is to connect
when chunks spawn:

```gdscript
# In your gameplay screen or game world script:
func _on_chunk_spawned(chunk_node: Node, _chunk_data: Resource) -> void:
	# Find all GCCollectible behaviors in the chunk
	for node in chunk_node.get_children():
		if node.has_method("get_children"):
			for child in node.get_children():
				if child is GCCollectible:
					child.collected.connect(_on_collectible_picked_up)


func _on_collectible_picked_up(_collector: Node, reward: Dictionary) -> void:
	var amount: int = reward.get(&"amount", 1)
	score_manager.add_cash(amount)
```

## 6 --- HUD setup

### HUD scene structure

Create a `GameHud.tscn` scene:

```text
GameHud (Control)
├── MarginContainer
│   ├── VBoxContainer (top-left anchor)
│   │   ├── ScoreLabel (Label)   → "Score: 0"
│   │   └── DistanceLabel (Label) → "0 m"
│   └── (empty right side for future elements)
└── GCVirtualJoystick (bottom-left anchor)
    ├── joystick_mode = FIXED
    ├── dead_zone = 0.15
    ├── visibility_mode = ALWAYS
    └── size = Vector2(200, 200)
```

### Anchoring the joystick

| Property | Value |
|---|---|
| anchor\_left | 0.0 |
| anchor\_top | 1.0 |
| anchor\_right | 0.0 |
| anchor\_bottom | 1.0 |
| offset\_left | 20 |
| offset\_top | -220 |
| offset\_right | 220 |
| offset\_bottom | -20 |

This places a 200 x 200 joystick in the bottom-left corner with
20 px padding from the screen edge.

### Updating HUD labels

In the gameplay screen script:

```gdscript
var _score_label: Label
var _distance_label: Label

func _setup_hud() -> void:
	var hud: GCHudLayer = GCBootstrap.instance.get_node("GCHudLayer")
	var hud_scene := preload("res://scenes/ui/game_hud.tscn")
	var hud_root: Control = hud.add_element(&"game_hud", hud_scene)
	_score_label = hud_root.get_node("MarginContainer/VBoxContainer/ScoreLabel")
	_distance_label = hud_root.get_node("MarginContainer/VBoxContainer/DistanceLabel")

	# Connect the joystick to the player input behavior
	var joystick: GCVirtualJoystick = hud_root.get_node("GCVirtualJoystick")
	player_input_behavior.joystick = joystick

	score_manager.score_updated.connect(func(total: int) -> void:
		_score_label.text = "Score: %d" % total
	)
	score_manager.distance_updated.connect(func(dist: float) -> void:
		_distance_label.text = "%d m" % int(dist / 100.0)
	)
```

## 7 --- Screen flow

### Screen definitions

Configure `GCScreenRouter.definitions` in the inspector with three
`GCScreenDef` resources:

| Screen id | Scene | Persistent | Transition |
|---|---|---|---|
| `&"title"` | `res://scenes/screens/title_screen.tscn` | false | `GCFadeTransition` (0.3 s) |
| `&"gameplay"` | `res://scenes/screens/gameplay_screen.tscn` | false | `GCFadeTransition` (0.5 s) |
| `&"game_over"` | `res://scenes/screens/game_over_screen.tscn` | false | `GCFadeTransition` (0.3 s) |

### TitleScreen (`res://scenes/screens/title_screen.tscn`)

```text
TitleScreen (GCScreen)
├── CenterContainer
│   ├── VBoxContainer
│   │   ├── TitleLabel (Label)   → "TERMINATION PROTOCOL"
│   │   └── PlayButton (Button)  → "PLAY"
```

Script at `res://scripts/screens/title_screen.gd`:

```gdscript
extends GCScreen

@onready var play_button: Button = %PlayButton


func enter(_payload: Dictionary = {}) -> void:
	play_button.pressed.connect(_on_play)


func _on_play() -> void:
	var router := get_parent() as GCScreenRouter
	router.go_to(&"gameplay")
```

### GameplayScreen (`res://scenes/screens/gameplay_screen.tscn`)

This is the main game scene described in section 2.
Script at `res://scripts/screens/gameplay_screen.gd`:

```gdscript
extends GCScreen

@onready var world_controller: GCWorldController = %GCWorldController
@onready var scroll_driver: GCScrollDriver = %GCScrollDriver
@onready var camera: GCCamera2D = %GCCamera2D
@onready var hit_stop: GCHitStop = %GCHitStop
@onready var player: GCCharacterHost2D = %Player
@onready var score_manager: ScoreManager = %ScoreManager

var _player_health: GCHealth
var _continued := false


func enter(_payload: Dictionary = {}) -> void:
	_setup_hud()

	score_manager.setup(scroll_driver)

	# Open the world (starts chunk streaming)
	world_controller.configure(context)
	world_controller.open_world()

	# Connect chunk spawn for collectible wiring
	var source: GCStreamChunkSource = scroll_driver.chunk_source
	if source:
		source.chunk_spawned.connect(_on_chunk_spawned)

	# Connect player death
	_player_health = _find_health(player)
	if _player_health:
		_player_health.died.connect(_on_player_died)


func exit() -> void:
	var hud: GCHudLayer = GCBootstrap.instance.get_node("GCHudLayer")
	hud.remove_element(&"game_hud")
	world_controller.close_world()
	scroll_driver.reset()


func _on_player_died() -> void:
	# Hit-stop + screen shake for dramatic death
	hit_stop.freeze(0.08)
	camera.shake(12.0, 0.3)

	# Stop scrolling
	scroll_driver.active = false

	# Wait a beat, then transition
	await get_tree().create_timer(0.6, true, false, true).timeout

	if not _continued:
		_show_continue_prompt()
	else:
		_go_to_game_over()


func _show_continue_prompt() -> void:
	# --- Rewarded ad integration point ---
	# Show your ad SDK's rewarded ad here.
	# On ad completion, call _continue_run().
	# On ad skip/close, call _go_to_game_over().
	# Placeholder: go straight to game over.
	_go_to_game_over()


func _continue_run() -> void:
	_continued = true
	# Revive player
	_player_health.heal(player, 1)
	player.local_state[&"is_alive"] = true
	scroll_driver.active = true


func _go_to_game_over() -> void:
	var payload := {
		&"score": score_manager.get_total_score(),
		&"distance": score_manager.distance,
		&"cash": score_manager.cash,
	}
	var router := get_parent() as GCScreenRouter
	router.go_to(&"game_over", payload)


func _on_chunk_spawned(chunk_node: Node, _chunk_data: Resource) -> void:
	for node in chunk_node.get_children():
		for child in node.get_children():
			if child is GCCollectible:
				child.collected.connect(_on_collectible_picked_up)


func _on_collectible_picked_up(_collector: Node, reward: Dictionary) -> void:
	score_manager.add_cash(reward.get(&"amount", 1))


func _find_health(host: Node) -> GCHealth:
	for child in host.get_children():
		if child is GCHealth:
			return child
	return null


# --- HUD setup (from section 6) ---

var _score_label: Label
var _distance_label: Label

func _setup_hud() -> void:
	var hud: GCHudLayer = GCBootstrap.instance.get_node("GCHudLayer")
	var hud_scene := preload("res://scenes/ui/game_hud.tscn")
	var hud_root: Control = hud.add_element(&"game_hud", hud_scene)
	_score_label = hud_root.get_node("MarginContainer/VBoxContainer/ScoreLabel")
	_distance_label = hud_root.get_node("MarginContainer/VBoxContainer/DistanceLabel")

	var joystick: GCVirtualJoystick = hud_root.get_node("GCVirtualJoystick")
	var input_beh: PlayerInputBehavior
	for child in player.get_children():
		if child is PlayerInputBehavior:
			input_beh = child
			break
	if input_beh:
		input_beh.joystick = joystick

	score_manager.score_updated.connect(func(total: int) -> void:
		_score_label.text = "Score: %d" % total
	)
	score_manager.distance_updated.connect(func(dist: float) -> void:
		_distance_label.text = "%d m" % int(dist / 100.0)
	)
```

### GameOverScreen (`res://scenes/screens/game_over_screen.tscn`)

```text
GameOverScreen (GCScreen)
├── CenterContainer
│   └── VBoxContainer
│       ├── GameOverLabel (Label) → "GAME OVER"
│       ├── ScoreLabel (Label)
│       ├── DistanceLabel (Label)
│       ├── CashLabel (Label)
│       ├── RankLabel (Label)
│       ├── RetryButton (Button) → "RETRY"
│       └── MenuButton (Button)  → "MENU"
```

Script at `res://scripts/screens/game_over_screen.gd`:

```gdscript
extends GCScreen

@onready var score_label: Label = %ScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var cash_label: Label = %CashLabel
@onready var rank_label: Label = %RankLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func enter(payload: Dictionary = {}) -> void:
	var score: int = payload.get(&"score", 0)
	var distance: float = payload.get(&"distance", 0.0)
	var cash: int = payload.get(&"cash", 0)

	score_label.text = "Score: %d" % score
	distance_label.text = "Distance: %d m" % int(distance / 100.0)
	cash_label.text = "Cash: $%d" % cash
	rank_label.text = "Submitting..."

	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)

	# Submit to leaderboard
	_submit_score(score)


func _submit_score(score: int) -> void:
	var lb := GCBootstrap.instance.get_service(&"gc_leaderboard_service")
	if lb == null:
		rank_label.text = ""
		return
	# You need to implement a GCLeaderboardService subclass for your backend.
	# This shows the pattern:
	var player_id: String = GCBootstrap.instance.context.get_player_value(
		&"player_id", "anonymous"
	)
	lb.submit_score("termination_protocol", player_id, score)
	var rank: int = lb.get_player_rank("termination_protocol", player_id)
	if rank > 0:
		rank_label.text = "Rank: #%d" % rank
	else:
		rank_label.text = ""


func _on_retry() -> void:
	var router := get_parent() as GCScreenRouter
	router.go_to(&"gameplay")


func _on_menu() -> void:
	var router := get_parent() as GCScreenRouter
	router.go_to(&"title")
```

## 8 --- Parallax background

In the `GameplayScreen` scene, add a `ParallaxBackground` node. Because
the world scrolls upward (chunks move up while the player stays still),
drive the parallax offset from the scroll driver each frame rather than
relying on camera movement.

```text
ParallaxBackground
├── DistantCityLayer (ParallaxLayer)
│   ├── motion_scale = Vector2(0.0, 0.1)
│   └── Sprite2D  → tall tiling cityscape texture
├── MidBuildingsLayer (ParallaxLayer)
│   ├── motion_scale = Vector2(0.0, 0.3)
│   └── Sprite2D  → mid-ground buildings
└── NearStructuresLayer (ParallaxLayer)
    ├── motion_scale = Vector2(0.0, 0.6)
    └── Sprite2D  → near structures, scaffolding
```

### Driving parallax from scroll

Since the camera is FIXED, manually advance the
`ParallaxBackground.scroll_offset` each frame:

```gdscript
# In gameplay_screen.gd or a dedicated script on the ParallaxBackground:
@onready var parallax: ParallaxBackground = %ParallaxBackground

func _physics_process(delta: float) -> void:
	if scroll_driver and scroll_driver.active:
		# Scroll upward: negative Y offset increases over time
		parallax.scroll_offset.y -= scroll_driver.current_speed * delta
```

### Texture setup

Set each `Sprite2D` texture region to repeat vertically:

- Import the texture with **Repeat** enabled
- Set `Sprite2D.region_enabled = true`
- Set `region_rect` height to a large value (e.g., 10000) so it tiles
- On each `ParallaxLayer`, set `motion_mirroring.y` to the texture height

This creates an infinite scrolling background that reinforces the
falling sensation.

## 9 --- Death effects: screen shake and hit-stop

The addon now provides both effects out of the box.

### GCCamera2D.shake()

```gdscript
# Trigger on death:
camera.shake(12.0, 0.3)
# strength = 12 pixels max displacement
# duration = 0.3 seconds with linear decay
```

The shake stacks --- calling `shake()` during an active shake takes the
greater strength and restarts the timer.

### GCHitStop.freeze()

```gdscript
# Trigger on death (before the shake for maximum impact):
hit_stop.freeze(0.08)
# Freezes everything for 80 ms via Engine.time_scale = 0
```

Place the `GCHitStop` node as a child of the gameplay screen.
It must be in the tree to use `get_tree().create_timer()`.

### Combined death sequence

```gdscript
func _on_player_died() -> void:
	hit_stop.freeze(0.08)
	camera.shake(12.0, 0.3)
	scroll_driver.active = false
	await get_tree().create_timer(0.6, true, false, true).timeout
	_go_to_game_over()
```

## 10 --- Virtual joystick guide

### What is a virtual joystick

A virtual joystick is an on-screen touch control that replaces physical
thumbsticks on mobile devices. The player touches and drags within a
circular area. The joystick outputs a direction vector that game code
reads each frame, just like reading a gamepad stick.

### Placement

Place `GCVirtualJoystick` as a child of a `CanvasLayer` or
`GCHudLayer` so it renders on top of the game world. Position it in
the bottom-left corner for right-handed play (or bottom-right for
left-handed --- consider offering a setting).

### Configuration

| Export | Purpose | Recommended value |
|---|---|---|
| `joystick_mode` | FIXED stays in place; DYNAMIC appears at touch point | `FIXED` for this game |
| `dead_zone` | Ignore tiny movements (0--1 fraction of radius) | `0.15` |
| `visibility_mode` | ALWAYS or WHEN\_PRESSED | `ALWAYS` |
| `base_texture` | Optional custom ring texture | null (uses default circle) |
| `handle_texture` | Optional custom thumb texture | null (uses default circle) |
| `base_color` | Ring color when using default draw | `Color(1, 1, 1, 0.25)` |
| `handle_color` | Thumb color when using default draw | `Color(1, 1, 1, 0.6)` |
| `handle_ratio` | Thumb size relative to base (0.1--0.8) | `0.35` |

### How it works

1. The joystick's `size` property defines the touch area. A 200 x 200
   Control means a 100 px radius circle.
2. When the player touches inside the area, the joystick tracks that
   finger index (multi-touch safe).
3. Dragging moves the handle. The offset is clamped to the base radius.
4. `direction` is a `Vector2` with length 0--1. Values below
   `dead_zone` are zeroed.
5. On release, `direction` returns to `Vector2.ZERO`.

### Reading the joystick

The `PlayerInputBehavior` reads `joystick.direction.x` every physics
frame and writes to `host.local_state[&"move_direction"]`. If the
joystick is not pressed, it falls back to keyboard input for desktop
testing.

### Customizing visuals

For a polished release:

1. Create two textures: a ring image for the base and a filled circle
   for the handle.
2. Set `base_texture` and `handle_texture` in the inspector.
3. The textures are scaled to fit the base radius and handle radius
   automatically.
4. Adjust `base_color` and `handle_color` opacity to taste --- these
   tint the textures.

### DYNAMIC mode

In DYNAMIC mode, the joystick base appears wherever the player first
touches. This is popular for games where the player might want to
rest their thumb anywhere on the screen. Set
`visibility_mode = WHEN_PRESSED` with DYNAMIC mode so the joystick
only appears when touched.

For Termination Protocol, FIXED mode is recommended because the
corridor is narrow and the player needs a consistent thumb anchor.

## 11 --- Leaderboard integration

`GCLeaderboardService` is an interface. You must subclass it for your
backend (Firebase, Supabase, PlayFab, custom REST, etc.).

### Implementation skeleton

Save at `res://scripts/services/my_leaderboard_service.gd`:

```gdscript
extends GCLeaderboardService
class_name MyLeaderboardService

# Replace with your backend client
var _api_url := "https://your-backend.example.com/api"


func submit_score(
	board_id: String,
	player_id: String,
	score: int,
	extra: Dictionary = {}
) -> void:
	var body := {
		"board": board_id,
		"player": player_id,
		"score": score,
	}
	body.merge(extra)
	# HTTPRequest example:
	var http := HTTPRequest.new()
	add_child(http)  # needs to be in tree
	http.request(
		_api_url + "/scores",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	var result = await http.request_completed
	http.queue_free()
	var success: bool = result[1] == 200
	score_submitted.emit(board_id, success)


func get_top_scores(board_id: String, count: int = 10) -> Array:
	# Implement your fetch logic here
	return []


func get_player_rank(board_id: String, player_id: String) -> int:
	# Implement your rank lookup here
	return -1
```

### Registering the service

Add the script to `GCBootstrap.service_scripts` in the inspector, or
register at runtime:

```gdscript
GCBootstrap.instance.services.register(
	&"gc_leaderboard_service",
	MyLeaderboardService.new()
)
```

## 12 --- Rewarded ad continue

This is purely game-specific and depends on your ad SDK (AdMob,
Unity Ads, IronSource, etc.). The integration point is in
`_show_continue_prompt()` inside the gameplay screen script
(see section 7).

Pattern:

```gdscript
func _show_continue_prompt() -> void:
	if _continued:
		_go_to_game_over()
		return
	# Show a "Continue?" UI overlay
	# When player taps "Watch Ad":
	#   ad_sdk.show_rewarded_ad(callback)
	# On ad_completed: _continue_run()
	# On ad_skipped:   _go_to_game_over()
```

## 13 --- Local state flow

```text
[WallSlideDetector] SENSE
    reads: host.is_on_wall()
    action: scroll_driver.apply_speed_modifier(0.5 or 1.0)

[PlayerInputBehavior] DECIDE
    reads: joystick.direction OR Input.get_axis()
    writes: move_direction, facing_direction

[GCSimpleMovement] ACT
    reads: move_direction, speed
    action: host.velocity.x = dir * speed, move_and_slide()

[GCHealth] ACT
    reads: health, is_alive
    writes: health, is_alive, invincible, just_hit
    signal: died → gameplay screen handles death flow

[GCFacing] PRESENT
    reads: facing_direction
    action: flips sprite

[GCAnimationBehavior] PRESENT
    reads: is_alive, just_hit, move_direction
    action: plays matching animation

[GCScrollDriver] _physics_process (not a behavior)
    action: moves chunk root children upward
    calls: GCStreamChunkSource.update() for lifecycle

[ScoreManager] _physics_process (not a behavior)
    reads: scroll_driver.current_speed
    writes: distance, cash, total score
    signal: score_updated → HUD label
```

## 14 --- Testing the skeleton

### Manual checklist

1. Run the project. The title screen should appear.
2. Tap PLAY. The gameplay screen loads with a fade transition.
3. Chunks scroll upward. The player is vertically stationary.
4. Move the virtual joystick left and right. The player moves
   horizontally with flip animation.
5. Slide into a wall. Scroll speed should visibly slow down.
6. Collect a coin. The HUD score updates.
7. Touch a hazard or enemy. The game freezes briefly (hit-stop),
   the camera shakes, scrolling stops, and the game-over screen
   appears after a short delay.
8. On the game-over screen, score, distance, and cash are displayed.
9. Tap RETRY. A new run starts from scratch.
10. Tap MENU. Returns to the title screen.

### Common issues

| Symptom | Likely cause |
|---|---|
| Player does not move | `PlayerInputBehavior` missing or joystick not connected |
| Player falls through walls | Collision layers wrong; walls need layer 2, player mask 2 |
| Chunks do not spawn | `GCWorldController.source` not set or `GCScrollDriver.chunk_source` null |
| Score does not update | `ScoreManager.setup()` not called with the scroll driver |
| Joystick not visible | HUD element not added or `visibility_mode` set to WHEN\_PRESSED |
| No hit-stop on death | `GCHitStop` not in the scene tree or `died` signal not connected |
| Parallax not moving | `scroll_offset` not being advanced in `_physics_process` |
