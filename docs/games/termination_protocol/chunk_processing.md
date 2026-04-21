# Chunk Processing Guide

This guide builds the gameplay-side world for Termination Protocol:
streamed chunks, horizontal player movement, wall-slide speed control,
and a standalone test scene you can run before wiring title screens and
HUD. The full screen flow comes later in `core_loop.md`.

Everything in this guide has been checked against the current addon
scripts in `addons/game_core`.

## Outcome

By the end of this guide you will have:

1. A reusable `Player` scene.
2. Chunk scenes and `GCChunkData` resources.
3. A `GCStreamChunkSource` resource with a custom selector.
4. A reusable `GameWorld` scene that opens the streamed world.
5. A small standalone test scene for smoke testing chunk flow.

## Scene tree legend

Use this legend when reading node trees in this guide:

| Marker | Meaning |
|---|---|
| `[Node]` | Add this node directly in the current scene in the editor. |
| `[Scene instance]` | Instantiate another `.tscn` as a child in the editor. |
| `[Runtime]` | Created by addon code or by your own script at runtime. |

## Recommended paths

These are the paths used below so both guides stay aligned:

| Kind | Path |
|---|---|
| Player scene | `res://scenes/actors/player.tscn` |
| Game world scene | `res://scenes/world/game_world.tscn` |
| Chunk scenes | `res://scenes/chunks/...` |
| Chunk data resources | `res://data/chunks/...` |
| World scripts | `res://scripts/world/...` |
| Player scripts | `res://scripts/player/...` |
| Debug test scene | `res://scenes/debug/chunk_processing_test.tscn` |

If you use different paths, keep the references consistent when you copy
the scripts from this guide.

## 1. Add input actions

Create these actions in `Project Settings > Input Map`:

| Action | Suggested binding |
|---|---|
| `move_left` | Left Arrow, `A` |
| `move_right` | Right Arrow, `D` |

This guide uses keyboard input first. The later core-loop guide wires in
the virtual joystick without changing the player behavior script.

## 2. Create the game-specific scripts

Create these scripts first so the scenes in later steps can reference
them directly.

### 2.1 `player_input_behavior.gd`

Save at `res://scripts/player/player_input_behavior.gd`.

Attach this as a child behavior of the player host in step 3.

```gdscript
extends GCBehavior
class_name PlayerInputBehavior

@export var joystick: GCVirtualJoystick
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"


func _init() -> void:
    phase = Phase.DECIDE


func on_physics(host: Node, _delta: float) -> void:
    var axis := 0.0

    if joystick and joystick.is_pressed:
        axis = joystick.direction.x
    else:
        axis = Input.get_axis(action_left, action_right)

    host.local_state[&"move_direction"] = Vector2(axis, 0.0)

    if axis != 0.0:
        host.local_state[&"facing_direction"] = 1 if axis > 0.0 else -1
```

### 2.2 `wall_slide_detector.gd`

Save at `res://scripts/player/wall_slide_detector.gd`.

Attach this as a child behavior of the player host in step 3.

Leave `scroll_driver_path` empty when the player is an instanced child
scene of `GameWorld`. The script already searches upward for a sibling
`GCScrollDriver`.

```gdscript
extends GCBehavior
class_name WallSlideDetector

@export_range(0.1, 1.0, 0.05) var slide_speed_modifier := 0.5
@export var scroll_driver_path: NodePath

var _driver: GCScrollDriver
var _is_sliding := false


func _init() -> void:
    phase = Phase.SENSE


func on_host_ready(host: Node) -> void:
    if not scroll_driver_path.is_empty():
        _driver = host.get_node_or_null(scroll_driver_path) as GCScrollDriver
    if _driver != null:
        return

    var node := host.get_parent()
    while node:
        for child in node.get_children():
            if child is GCScrollDriver:
                _driver = child
                return
        node = node.get_parent()


func on_physics(host: Node, _delta: float) -> void:
    if _driver == null or not (host is CharacterBody2D):
        return

    var sliding := (host as CharacterBody2D).is_on_wall()
    if sliding == _is_sliding:
        return

    _is_sliding = sliding
    _driver.apply_speed_modifier(slide_speed_modifier if sliding else 1.0)
```

### 2.3 `runner_chunk_selector.gd`

Save at `res://scripts/world/runner_chunk_selector.gd`.

This is the game-specific piece that biases chunk selection by recent
history and by the difficulty cursor exposed by `GCStreamChunkSource`.

```gdscript
extends GCChunkSelector
class_name RunnerChunkSelector

@export var max_repeat_category := 2
@export var difficulty_window := 0.3


func select_next(pool: Array, history: Array[StringName], context: Dictionary) -> Resource:
    var filtered := filter_pool(pool, history, context)
    if filtered.is_empty():
        filtered = pool
    if filtered.is_empty():
        return null

    var cursor: float = context.get(&"difficulty_cursor", 0.0)
    var weighted: Array = []
    var weights: Array[float] = []

    for chunk in filtered:
        var diff: float = absf(chunk.difficulty - cursor)
        if diff <= difficulty_window:
            weighted.append(chunk)
            weights.append(1.0 / (diff + 0.1))

    if weighted.is_empty():
        return filtered[randi() % filtered.size()]

    return _weighted_pick(weighted, weights)


func filter_pool(pool: Array, history: Array[StringName], context: Dictionary) -> Array:
    var result: Array = super.filter_pool(pool, history, context)
    if history.size() < max_repeat_category:
        return result

    var recent: Array[StringName] = []
    for index in range(max(0, history.size() - max_repeat_category), history.size()):
        recent.append(history[index])

    var final: Array = []
    for chunk in result:
        if not recent.has(chunk.category):
            final.append(chunk)

    return final if not final.is_empty() else result


func _weighted_pick(items: Array, weights: Array[float]) -> Resource:
    var total := 0.0
    for weight in weights:
        total += weight

    var roll := randf() * total
    var running := 0.0

    for index in range(items.size()):
        running += weights[index]
        if roll <= running:
            return items[index]

    return items.back()
```

### 2.4 `game_world.gd`

Save at `res://scripts/world/game_world.gd`.

Attach this to the root of `game_world.tscn` in step 6.

This wrapper keeps the chunk world reusable: you can open it from a
standalone debug scene now, and later from `GameplayScreen` in
`core_loop.md`.

```gdscript
extends Node2D
class_name TPGameWorld

@onready var world_controller := get_node("GCWorldController") as GCWorldController
@onready var scroll_driver := get_node("GCScrollDriver") as GCScrollDriver
@onready var player := get_node("Player") as GCCharacterHost2D
@onready var camera := get_node("GCCamera2D") as GCCamera2D
@onready var parallax := get_node_or_null("ParallaxBackground") as ParallaxBackground


func open_with_context(game_context: GCGameContext) -> void:
    world_controller.configure(game_context)
    world_controller.open_world()


func close_world() -> void:
    world_controller.close_world()
    scroll_driver.reset()


func get_chunk_source() -> GCStreamChunkSource:
    return scroll_driver.chunk_source as GCStreamChunkSource


func get_player_input() -> PlayerInputBehavior:
    for child in player.get_children():
        if child is PlayerInputBehavior:
            return child
    return null


func get_player_health() -> GCHealth:
    for child in player.get_children():
        if child is GCHealth:
            return child
    return null


func _physics_process(delta: float) -> void:
    if parallax and scroll_driver.active:
        parallax.scroll_offset.y -= scroll_driver.current_speed * delta
```

## 3. Create the player scene

Create `res://scenes/actors/player.tscn` with this tree:

```text
Player [Scene root: GCCharacterHost2D]
├── CollisionShape2D [Node]
├── Sprite2D [Node]
├── AnimationPlayer [Node]
├── PlayerInputBehavior [Node, script: res://scripts/player/player_input_behavior.gd]
├── GCSimpleMovement [Node]
├── GCHealth [Node]
├── GCFacing [Node]
├── GCAnimationBehavior [Node]
└── WallSlideDetector [Node, script: res://scripts/player/wall_slide_detector.gd]
```

### Player settings

Set these values in the inspector:

| Node | Setting | Value |
|---|---|---|
| `Player` | Groups | add `player` and `damageable` |
| `Player` | Collision Layer | `Player` |
| `Player` | Collision Mask | `Walls`, `Hazards` |
| `CollisionShape2D` | Shape | `RectangleShape2D`, for example `24 x 28` |
| `GCSimpleMovement` | `default_speed` | `200` |
| `GCHealth` | `max_health` | `1` |
| `GCHealth` | `invincibility_time` | `0.0` |
| `GCFacing` | `flip_sprite` | `true` |
| `GCAnimationBehavior` | `idle_animation` | `"idle"` |
| `GCAnimationBehavior` | `move_animation` | `"move"` |
| `GCAnimationBehavior` | `death_animation` | `"death"` |
| `GCAnimationBehavior` | `hit_animation` | `"hit"` or empty string |
| `WallSlideDetector` | `slide_speed_modifier` | `0.5` |
| `WallSlideDetector` | `scroll_driver_path` | leave empty |

### Important animation note

`GCAnimationBehavior` drives an `AnimationPlayer`, not an
`AnimatedSprite2D`. If you only want `AnimatedSprite2D`, remove
`GCAnimationBehavior` and animate that sprite yourself.

## 4. Create the chunk scenes

Each chunk scene should be a plain `Node2D` root. The stream source will
instantiate these scenes at runtime.

Use this authoring rule for all chunk scenes:

1. The scene root starts at the top edge of the chunk.
2. Content extends downward along positive `Y`.
3. `GCChunkData.length` must match the chunk height along that axis.

Base pattern:

```text
ChunkName [Scene root: Node2D]
├── Geometry [Node]
│   ├── TileMapLayer [Node]
│   └── Static platforms / walls [Nodes]
├── Hazards [Node]
├── Enemies [Node]
└── Pickups [Node]
```

For this guide, create at least these three scenes:

| Scene | Purpose |
|---|---|
| `res://scenes/chunks/challenge_01.tscn` | First challenge chunk |
| `res://scenes/chunks/challenge_02.tscn` | Second challenge chunk |
| `res://scenes/chunks/connector_01.tscn` | Low-pressure connector chunk |

### Hazard pattern that works with `GCDamage`

If a chunk hazard should kill the player on contact, use this shape:

```text
Hazard [Node root: GCStaticHost2D]
├── CollisionShape2D [Node]
├── DamageArea [Node: Area2D]
│   └── CollisionShape2D [Node]
└── GCDamage [Node]
```

Use these settings:

| Node | Setting | Value |
|---|---|---|
| `DamageArea` | Collision Layer | `Hazards` |
| `DamageArea` | Collision Mask | `Player` |
| `GCDamage` | `damage` | `1` |
| `GCDamage` | `damage_group` | `&"damageable"` |

The `damageable` group on the player is required because `GCDamage`
checks groups, not `entity_tags`.

## 5. Create the chunk data resources

Create one `GCChunkData` resource per chunk scene.

Suggested paths:

```text
res://data/chunks/challenge_01.tres
res://data/chunks/challenge_02.tres
res://data/chunks/connector_01.tres
```

Configure each resource like this:

| Property | Challenge example | Connector example |
|---|---|---|
| `scene` | `challenge_01.tscn` | `connector_01.tscn` |
| `category` | `&"challenge_basic"` | `&"connector_breath"` |
| `difficulty` | `0.2` to `0.4` | `0.0` |
| `length` | actual chunk height in pixels, for example `640.0` | actual connector height, for example `256.0` |
| `is_connector` | `false` | `true` |
| `tags` | optional | optional |
| `connects_from` | leave empty unless you need strict sequencing | optional |
| `connects_to` | leave empty unless you need strict sequencing | optional |

## 6. Create the selection resources

Create these two resources:

| Resource | Suggested path | Type |
|---|---|---|
| Chunk selector | `res://data/chunks/runner_chunk_selector.tres` | `RunnerChunkSelector` |
| Stream source | `res://data/chunks/termination_protocol_stream_source.tres` | `GCStreamChunkSource` |

### `runner_chunk_selector.tres`

Set these values:

| Property | Value |
|---|---|
| `max_repeat_category` | `2` |
| `difficulty_window` | `0.3` |

### `termination_protocol_stream_source.tres`

Set these values:

| Property | Value |
|---|---|
| `chunks` | add all challenge `GCChunkData` resources |
| `connectors` | add all connector `GCChunkData` resources |
| `selector` | `runner_chunk_selector.tres` |
| `buffer_between` | `64.0` |
| `connector_interval` | `4` |
| `lookahead_count` | `3` |
| `trail_count` | `1` |

## 7. Create the `GameWorld` scene

Create `res://scenes/world/game_world.tscn` with this tree:

```text
GameWorld [Scene root: Node2D, script: res://scripts/world/game_world.gd]
├── GCWorldController [Node]
│   └── ChunkRoot [Runtime: created by GCStreamChunkSource]
│       ├── Challenge chunk [Runtime scene instance]
│       └── Connector chunk [Runtime scene instance]
├── GCScrollDriver [Node]
├── BoundaryWalls [Node root: StaticBody2D]
│   ├── LeftWall [Node: CollisionShape2D]
│   └── RightWall [Node: CollisionShape2D]
├── Player [Scene instance: res://scenes/actors/player.tscn]
└── GCCamera2D [Node]
```

### `GameWorld` settings

| Node | Setting | Value |
|---|---|---|
| `GCWorldController` | `source` | `termination_protocol_stream_source.tres` |
| `GCScrollDriver` | `chunk_source` | `termination_protocol_stream_source.tres` |
| `GCScrollDriver` | `base_speed` | `80.0` |
| `GCScrollDriver` | `acceleration` | `1.5` |
| `GCScrollDriver` | `max_speed` | `300.0` |
| `GCScrollDriver` | `direction` | `Vector2.UP` |
| `GCScrollDriver` | `viewport_scroll_size` | your visible world height in pixels |
| `GCCamera2D` | `mode` | `FIXED` |
| `BoundaryWalls` | Collision Layer | `Walls` |
| `BoundaryWalls` | Collision Mask | usually empty |

### Boundary wall note

The wall-slide behavior depends on `CharacterBody2D.is_on_wall()`, so the
left and right corridor walls must be real physics walls on the `Walls`
layer. Make sure the player collides with them.

## 8. Create a standalone smoke-test scene

Create `res://scenes/debug/chunk_processing_test.tscn` with this tree:

```text
ChunkProcessingTest [Scene root: Node, script: res://scripts/debug/chunk_processing_test.gd]
└── GameWorld [Scene instance: res://scenes/world/game_world.tscn]
```

Create `res://scripts/debug/chunk_processing_test.gd`:

```gdscript
extends Node

@onready var game_world := get_node("GameWorld") as TPGameWorld
var _context := GCGameContext.new()


func _ready() -> void:
    game_world.open_with_context(_context)


func _exit_tree() -> void:
    game_world.close_world()
```

Temporarily run this scene as the main scene while you validate chunk
streaming in isolation.

## 9. Validate this guide before moving on

Use this checklist:

1. The player moves left and right with the keyboard.
2. Touching the left or right corridor wall slows the scroll speed.
3. At least two challenge chunks and one connector chunk appear over
   time.
4. Old chunks disappear after they pass above the visible play area.
5. Hazards that use `GCDamage` kill the player in one hit.

Once those work, continue with `core_loop.md` for the HUD, joystick,
title screen, game-over screen, and leaderboard flow.
