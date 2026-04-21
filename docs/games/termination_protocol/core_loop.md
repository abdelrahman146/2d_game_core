# Core Loop Guide

This guide takes the world from `chunk_processing.md` and wraps it in a
full playable loop:

1. Bootstrap autoload scene.
2. Title screen.
3. Gameplay screen with HUD and joystick.
4. Game-over screen.
5. Optional local leaderboard service for testing.

Everything in this guide has been checked against the current addon
scripts in `addons/game_core`.

## Before you start

Complete `chunk_processing.md` first. You should already have these
pieces working:

| Required output | Suggested path |
|---|---|
| Player scene | `res://scenes/actors/player.tscn` |
| Game world scene | `res://scenes/world/game_world.tscn` |
| Chunk data resources | `res://data/chunks/...` |
| Stream source resource | `res://data/chunks/termination_protocol_stream_source.tres` |
| Standalone chunk test scene | `res://scenes/debug/chunk_processing_test.tscn` |

If the standalone chunk test scene does not work yet, stop here and fix
that first. This guide assumes the chunk world is already solid.

## Scene tree legend

Use this legend when reading node trees in this guide:

| Marker | Meaning |
|---|---|
| `[Node]` | Add this node directly in the current scene in the editor. |
| `[Scene instance]` | Instantiate another `.tscn` as a child in the editor. |
| `[Runtime]` | Created by addon code or by your own script at runtime. |

## 1. Create the bootstrap scene

Create `res://scenes/bootstrap/bootstrap.tscn` with this tree:

```text
Bootstrap [Scene root: GCBootstrap]
├── GCScreenRouter [Node]
└── GCHudLayer [Node]
```

This scene is the composition root for the game.

Important: autoload this scene as `GCBootstrap`. Do not autoload only the
bare `gc_bootstrap.gd` script if you want the router and HUD to exist as
child nodes.

You will finish the router configuration in step 9 after the screen
scenes exist.

## 2. Create the HUD content scene

Create `res://scenes/ui/game_hud.tscn` with this tree:

```text
GameHud [Scene root: Control]
├── MarginContainer [Node]
│   └── VBoxContainer [Node]
│       ├── ScoreLabel [Node: Label]
│       └── DistanceLabel [Node: Label]
└── GCVirtualJoystick [Node]
```

`GCHudLayer` is the persistent HUD container in the bootstrap scene.
`GameHud.tscn` is the content scene you add into that container at
runtime. They are not two separate HUD systems.

Set `GameHud` itself to `Full Rect` layout so its child controls can
anchor against the full viewport.

### HUD settings

Set these values in the inspector:

| Node | Setting | Value |
|---|---|---|
| `ScoreLabel` | `text` | `Score: 0` |
| `DistanceLabel` | `text` | `0 m` |
| `GCVirtualJoystick` | `joystick_mode` | `FIXED` |
| `GCVirtualJoystick` | `dead_zone` | `0.15` |
| `GCVirtualJoystick` | `visibility_mode` | `ALWAYS` |
| `GCVirtualJoystick` | `size` | `Vector2(200, 200)` |
| `MarginContainer` | Layout | top-left area for the score labels |

### Joystick anchors

Use these anchors and offsets on `GCVirtualJoystick`:

| Property | Value |
|---|---|
| `anchor_left` | `0.0` |
| `anchor_top` | `1.0` |
| `anchor_right` | `0.0` |
| `anchor_bottom` | `1.0` |
| `offset_left` | `20` |
| `offset_top` | `-220` |
| `offset_right` | `220` |
| `offset_bottom` | `-20` |

This places the joystick in the lower-left corner with a 20 pixel margin.

## 3. Create the pickup scenes

Create these two reusable scenes:

| Scene | Path |
|---|---|
| Coin | `res://scenes/pickups/coin.tscn` |
| Cash bill | `res://scenes/pickups/cash_bill.tscn` |

Base tree for both scenes:

```text
Pickup [Scene root: GCAreaHost2D]
├── CollisionShape2D [Node]
├── AnimatedSprite2D [Node]
└── GCCollectible [Node]
```

### Coin settings

| Node | Setting | Value |
|---|---|---|
| `Coin` | Collision Layer | `Collectibles` |
| `Coin` | Collision Mask | `Player` |
| `CollisionShape2D` | Shape | `CircleShape2D`, radius `8` |
| `GCCollectible` | `collect_group` | `&"player"` |
| `GCCollectible` | `reward_type` | `&"coin"` |
| `GCCollectible` | `reward_amount` | `1` |
| `GCCollectible` | `destroy_on_collect` | `true` |

### Cash bill settings

Use the same scene shape, but change these values:

| Node | Setting | Value |
|---|---|---|
| `GCCollectible` | `reward_type` | `&"cash"` |
| `GCCollectible` | `reward_amount` | `5` |

After both scenes exist, place them inside your chunk scenes as normal
editor scene instances under a `Pickups` helper node or anywhere else
that fits your chunk layout.

This assumes the player is already in the `player` group from
`chunk_processing.md`.

## 4. Create the score manager script

Save this as `res://scripts/ui/score_manager.gd`.

Attach it to a plain `Node` in `gameplay_screen.tscn` in step 6.

```gdscript
extends Node
class_name ScoreManager

signal score_updated(total: int)
signal distance_updated(distance: float)

var cash := 0
var distance := 0.0
var _scroll_driver: GCScrollDriver


func setup(scroll_driver: GCScrollDriver) -> void:
    _scroll_driver = scroll_driver


func _physics_process(delta: float) -> void:
    if _scroll_driver and _scroll_driver.active:
        distance += _scroll_driver.current_speed * delta
        distance_updated.emit(distance)
        score_updated.emit(get_total_score())


func add_cash(amount: int) -> void:
    cash += amount
    score_updated.emit(get_total_score())


func get_total_score() -> int:
    return int(distance / 100.0) + cash


func reset() -> void:
    cash = 0
    distance = 0.0
    score_updated.emit(get_total_score())
    distance_updated.emit(distance)
```

## 5. Create the title screen

Create `res://scenes/screens/title_screen.tscn` with this tree:

```text
TitleScreen [Scene root: GCScreen, script: res://scripts/screens/title_screen.gd]
└── CenterContainer [Node]
    └── VBoxContainer [Node]
        ├── TitleLabel [Node: Label]
        └── PlayButton [Node: Button]
```

Set `CenterContainer` to `Full Rect` layout so it fills the screen.

Suggested label/button text:

| Node | Setting | Value |
|---|---|---|
| `TitleLabel` | `text` | `TERMINATION PROTOCOL` |
| `PlayButton` | `text` | `PLAY` |

Create `res://scripts/screens/title_screen.gd`:

```gdscript
extends GCScreen

@onready var play_button := get_node(
    "CenterContainer/VBoxContainer/PlayButton"
) as Button


func enter(_payload: Dictionary = {}) -> void:
    if not play_button.pressed.is_connected(_on_play):
        play_button.pressed.connect(_on_play)

    var bootstrap := _bootstrap()
    if not bootstrap.context.has_player_value(&"player_id"):
        bootstrap.context.set_player_value(&"player_id", "local_player")


func _on_play() -> void:
    var router := get_parent() as GCScreenRouter
    router.go_to(&"gameplay")


func _bootstrap() -> GCBootstrap:
    return get_tree().root.get_node("GCBootstrap") as GCBootstrap
```

## 6. Create the gameplay screen

Create `res://scenes/screens/gameplay_screen.tscn` with this tree:

```text
GameplayScreen [Scene root: GCScreen, script: res://scripts/screens/gameplay_screen.gd]
├── GameWorld [Scene instance: res://scenes/world/game_world.tscn]
├── GCHitStop [Node]
└── ScoreManager [Node, script: res://scripts/ui/score_manager.gd]
```

Create `res://scripts/screens/gameplay_screen.gd`:

```gdscript
extends GCScreen

@onready var game_world := get_node("GameWorld") as TPGameWorld
@onready var hit_stop := get_node("GCHitStop") as GCHitStop
@onready var score_manager := get_node("ScoreManager") as ScoreManager

var _player_health: GCHealth
var _hud_root: Control
var _score_label: Label
var _distance_label: Label
var _continued := false
var _death_in_progress := false


func enter(_payload: Dictionary = {}) -> void:
    _continued = false
    _death_in_progress = false

    var chunk_source := game_world.get_chunk_source()
    if chunk_source and not chunk_source.chunk_spawned.is_connected(
        _on_chunk_spawned
    ):
        chunk_source.chunk_spawned.connect(_on_chunk_spawned)

    _player_health = game_world.get_player_health()
    if _player_health and not _player_health.died.is_connected(
        _on_player_died
    ):
        _player_health.died.connect(_on_player_died)

    score_manager.reset()
    score_manager.setup(game_world.scroll_driver)

    _mount_hud()
    _bind_score_labels()

    game_world.scroll_driver.active = true
    game_world.open_with_context(context)
    _connect_loaded_collectibles()


func exit() -> void:
    var hud := _bootstrap().get_node("GCHudLayer") as GCHudLayer
    hud.remove_element(&"game_hud")
    game_world.close_world()


func _mount_hud() -> void:
    var hud := _bootstrap().get_node("GCHudLayer") as GCHudLayer
    var hud_scene := preload("res://scenes/ui/game_hud.tscn")
    _hud_root = hud.add_element(&"game_hud", hud_scene) as Control
    _score_label = _hud_root.get_node(
        "MarginContainer/VBoxContainer/ScoreLabel"
    ) as Label
    _distance_label = _hud_root.get_node(
        "MarginContainer/VBoxContainer/DistanceLabel"
    ) as Label

    var joystick := _hud_root.get_node("GCVirtualJoystick") as GCVirtualJoystick
    var player_input := game_world.get_player_input()
    if player_input:
        player_input.joystick = joystick


func _bind_score_labels() -> void:
    if not score_manager.score_updated.is_connected(_on_score_updated):
        score_manager.score_updated.connect(_on_score_updated)
    if not score_manager.distance_updated.is_connected(_on_distance_updated):
        score_manager.distance_updated.connect(_on_distance_updated)

    _on_score_updated(score_manager.get_total_score())
    _on_distance_updated(score_manager.distance)


func _on_score_updated(total: int) -> void:
    if _score_label:
        _score_label.text = "Score: %d" % total


func _on_distance_updated(distance: float) -> void:
    if _distance_label:
        _distance_label.text = "%d m" % int(distance / 100.0)


func _on_chunk_spawned(
    chunk_node: Node,
    _chunk_data: Resource,
    _index: int
) -> void:
    _connect_collectibles_recursive(chunk_node)


func _connect_loaded_collectibles() -> void:
    var chunk_source := game_world.get_chunk_source()
    if chunk_source == null:
        return

    for entry in chunk_source.get_loaded_chunks():
        var chunk_node := entry.get(&"node", null) as Node
        if chunk_node:
            _connect_collectibles_recursive(chunk_node)


func _connect_collectibles_recursive(node: Node) -> void:
    for child in node.get_children():
        if child is GCCollectible:
            var collectible := child as GCCollectible
            if not collectible.collected.is_connected(
                _on_collectible_picked_up
            ):
                collectible.collected.connect(_on_collectible_picked_up)
        _connect_collectibles_recursive(child)


func _on_collectible_picked_up(_collector: Node, reward: Dictionary) -> void:
    score_manager.add_cash(int(reward.get(&"amount", 1)))


func _on_player_died() -> void:
    if _death_in_progress:
        return

    _death_in_progress = true
    hit_stop.freeze(0.08)
    game_world.camera.shake(12.0, 0.3)
    game_world.scroll_driver.active = false

    await get_tree().create_timer(0.6, true, false, true).timeout

    if not _continued:
        _show_continue_prompt()
    else:
        _go_to_game_over()


func _show_continue_prompt() -> void:
    # Rewarded ad integration point.
    # On ad success, call _continue_run().
    # On cancel or failure, call _go_to_game_over().
    _go_to_game_over()


func _continue_run() -> void:
    _continued = true
    _death_in_progress = false

    if _player_health:
        _player_health.heal(game_world.player, 1)

    game_world.player.local_state[&"is_alive"] = true
    game_world.player.local_state[&"just_hit"] = false
    game_world.player.velocity = Vector2.ZERO
    game_world.scroll_driver.active = true


func _go_to_game_over() -> void:
    var payload := {
        &"score": score_manager.get_total_score(),
        &"distance": score_manager.distance,
        &"cash": score_manager.cash,
    }

    var router := get_parent() as GCScreenRouter
    router.go_to(&"game_over", payload)


func _bootstrap() -> GCBootstrap:
    return get_tree().root.get_node("GCBootstrap") as GCBootstrap
```

## 7. Create a local leaderboard service

Save this as
`res://scripts/services/termination_protocol_leaderboard_service.gd`.

This implementation is deliberately in-memory. It is accurate for the
current service API and is enough to validate the screen flow locally.

Later, if you replace it with an HTTP-backed service, remember that
`GCService` is `RefCounted`, not `Node`. Do not call `add_child()` from
inside the service itself.

```gdscript
extends GCLeaderboardService
class_name TerminationProtocolLeaderboardService

var _scores_by_board: Dictionary = {}


func submit_score(
    board_id: String,
    player_id: String,
    score: int,
    _extra: Dictionary = {}
) -> void:
    var board_scores: Dictionary = _scores_by_board.get(board_id, {})
    var previous := int(board_scores.get(player_id, -1))

    if score > previous:
        board_scores[player_id] = score

    _scores_by_board[board_id] = board_scores
    score_submitted.emit(board_id, true)


func get_top_scores(board_id: String, count: int = 10) -> Array:
    var board_scores: Dictionary = _scores_by_board.get(board_id, {})
    var rows: Array = []

    for player_id in board_scores.keys():
        rows.append({
            &"player_id": player_id,
            &"score": int(board_scores[player_id]),
        })

    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return int(a.get(&"score", 0)) > int(b.get(&"score", 0))
    )

    return rows.slice(0, mini(count, rows.size()))


func get_player_rank(board_id: String, player_id: String) -> int:
    var board_scores: Dictionary = _scores_by_board.get(board_id, {})
    var rows := get_top_scores(board_id, board_scores.size())

    for index in range(rows.size()):
        if String(rows[index].get(&"player_id", "")) == player_id:
            return index + 1

    return -1
```

## 8. Create the game-over screen

Create `res://scenes/screens/game_over_screen.tscn` with this tree:

```text
GameOverScreen [Scene root: GCScreen, script: res://scripts/screens/game_over_screen.gd]
└── CenterContainer [Node]
    └── VBoxContainer [Node]
        ├── GameOverLabel [Node: Label]
        ├── ScoreLabel [Node: Label]
        ├── DistanceLabel [Node: Label]
        ├── CashLabel [Node: Label]
        ├── RankLabel [Node: Label]
        ├── RetryButton [Node: Button]
        └── MenuButton [Node: Button]
```

Set `CenterContainer` to `Full Rect` layout.

Suggested label/button text:

| Node | Setting | Value |
|---|---|---|
| `GameOverLabel` | `text` | `GAME OVER` |
| `RetryButton` | `text` | `RETRY` |
| `MenuButton` | `text` | `MENU` |

Create `res://scripts/screens/game_over_screen.gd`:

```gdscript
extends GCScreen

@onready var score_label := get_node(
    "CenterContainer/VBoxContainer/ScoreLabel"
) as Label
@onready var distance_label := get_node(
    "CenterContainer/VBoxContainer/DistanceLabel"
) as Label
@onready var cash_label := get_node(
    "CenterContainer/VBoxContainer/CashLabel"
) as Label
@onready var rank_label := get_node(
    "CenterContainer/VBoxContainer/RankLabel"
) as Label
@onready var retry_button := get_node(
    "CenterContainer/VBoxContainer/RetryButton"
) as Button
@onready var menu_button := get_node(
    "CenterContainer/VBoxContainer/MenuButton"
) as Button


func enter(payload: Dictionary = {}) -> void:
    var score: int = payload.get(&"score", 0)
    var distance: float = payload.get(&"distance", 0.0)
    var cash: int = payload.get(&"cash", 0)

    score_label.text = "Score: %d" % score
    distance_label.text = "Distance: %d m" % int(distance / 100.0)
    cash_label.text = "Cash: $%d" % cash
    rank_label.text = ""

    if not retry_button.pressed.is_connected(_on_retry):
        retry_button.pressed.connect(_on_retry)
    if not menu_button.pressed.is_connected(_on_menu):
        menu_button.pressed.connect(_on_menu)

    _submit_score(score)


func _submit_score(score: int) -> void:
    var leaderboard := _bootstrap().get_service(
        &"termination_protocol_leaderboard_service"
    ) as GCLeaderboardService

    if leaderboard == null:
        rank_label.text = ""
        return

    var player_id := String(
        _bootstrap().context.get_player_value(&"player_id", "local_player")
    )

    leaderboard.submit_score("termination_protocol", player_id, score)
    var rank := leaderboard.get_player_rank("termination_protocol", player_id)

    if rank > 0:
        rank_label.text = "Local Rank: #%d" % rank
    else:
        rank_label.text = ""


func _on_retry() -> void:
    var router := get_parent() as GCScreenRouter
    router.go_to(&"gameplay")


func _on_menu() -> void:
    var router := get_parent() as GCScreenRouter
    router.go_to(&"title")


func _bootstrap() -> GCBootstrap:
    return get_tree().root.get_node("GCBootstrap") as GCBootstrap
```

## 9. Configure the router and autoload

Open `bootstrap.tscn` again and configure `GCScreenRouter`.

### Router settings

Set these values on `GCScreenRouter`:

| Setting | Value |
|---|---|
| `default_transition` | `New GCFadeTransition` |
| `default_transition.duration` | `0.3` |
| `default_transition.color` | `Color.BLACK` |

Create three `GCScreenDef` resources in `definitions`:

| `id` | `scene` | `transition` | `is_persistent` |
|---|---|---|---|
| `&"title"` | `res://scenes/screens/title_screen.tscn` | empty | `false` |
| `&"gameplay"` | `res://scenes/screens/gameplay_screen.tscn` | empty | `false` |
| `&"game_over"` | `res://scenes/screens/game_over_screen.tscn` | empty | `false` |

You can keep the per-screen `transition` fields empty because the router
already has a default fade transition.

If the resource picker still does not show `GCFadeTransition`, save the
project and reopen it so Godot refreshes the custom resource types.

### Bootstrap service setup

Add this script to `GCBootstrap.service_scripts` in the inspector:

| Script |
|---|
| `res://scripts/services/termination_protocol_leaderboard_service.gd` |

`GCBootstrap` derives service ids from filenames, so that file becomes
`termination_protocol_leaderboard_service`. That is why the game-over
screen looks up that exact id.

### Autoload setup

In `Project Settings > Autoload`, add:

| Path | Name |
|---|---|
| `res://scenes/bootstrap/bootstrap.tscn` | `GCBootstrap` |

The autoload name matters because the screen scripts access the node at
`/root/GCBootstrap`.

## 10. Optional: add parallax to `game_world.tscn`

If you want the layered city background from the game description, reopen
`res://scenes/world/game_world.tscn` and add this node above
`GCWorldController`:

```text
ParallaxBackground [Node]
├── DistantCityLayer [Node: ParallaxLayer]
├── MidBuildingsLayer [Node: ParallaxLayer]
└── NearStructuresLayer [Node: ParallaxLayer]
```

Suggested motion scales:

| Layer | `motion_scale` |
|---|---|
| `DistantCityLayer` | `Vector2(0.0, 0.1)` |
| `MidBuildingsLayer` | `Vector2(0.0, 0.3)` |
| `NearStructuresLayer` | `Vector2(0.0, 0.6)` |

The `TPGameWorld` script from the previous guide already updates
`ParallaxBackground.scroll_offset.y` if this node exists, so you do not
need a second script for the background.

## 11. Validate the full loop

Use this checklist:

1. Launch the project and confirm the title screen appears.
2. Press `PLAY` and confirm the gameplay screen loads.
3. Confirm the HUD appears above the world, not inside the world scene.
4. Move with keyboard and with the virtual joystick.
5. Collect coins or cash and confirm both the score and distance labels
   update.
6. Touch a lethal hazard and confirm the game freezes briefly, the camera
   shakes, and the screen then transitions to game over.
7. Press `RETRY` and confirm a fresh run starts.
8. Press `MENU` and confirm you return to the title screen.
9. If the local leaderboard service is enabled, confirm the game-over
   screen shows a local rank.
