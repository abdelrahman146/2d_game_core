# Chunk Processing Guide for Endless Runner

### 1. Create GCChunkData resources for every chunk

For each of your ~50 challenge chunks and ~10 connectors, create a `.tres` resource:

```
res://data/chunks/challenge_falling_boxes_01.tres   → GCChunkData
res://data/chunks/challenge_drones_01.tres          → GCChunkData
res://data/chunks/connector_bridge_01.tres          → GCChunkData
...
```

Inspector config per resource:

| Property | Example (challenge) | Example (connector) |
|----------|-------------------|-------------------|
| `scene` | your chunk PackedScene | your connector PackedScene |
| `category` | `&"falling_boxes"` | `&"connector_bridge"` |
| `difficulty` | `0.3` | `0.0` |
| `length` | `640.0` (in pixels, how tall the chunk is) | `256.0` |
| `is_connector` | `false` | `true` |
| `tags` | `[&"no_platforms"]` | `[&"scenic"]` |
| `connects_from` | `[]` (any predecessor) | `[&"falling_boxes", &"drones"]` |
| `connects_to` | `[]` | `[&"gates", &"patrol"]` |

### 2. Create your chunk scenes

Each chunk scene is a **Node2D** root containing:

```
ChunkRoot (Node2D)
├── TileMapLayer          ← platforms, walls (32×32 tiles)
├── Hazard1 (GCStaticHost2D / GCAreaHost2D)  ← game-specific hazards
├── Enemy1 (GCCharacterHost2D)               ← using addon behaviors
│   ├── CollisionShape2D
│   ├── Sprite2D
│   ├── GCPatrolBehavior
│   ├── GCDetectTarget
│   └── GCHealth
└── Spawner (Node2D)      ← for dynamic spawns within the chunk
```

The chunk's **origin is its top edge** (y=0). Content extends downward (positive Y). The `length` in `GCChunkData` should match the total height of the chunk content.

### 3. Scene tree for the game world

```
GameWorld (Node2D)
├── GCWorldController
│   └── (ChunkRoot auto-created by GCStreamChunkSource)
│       ├── Chunk0 (Node2D, instantiated)
│       ├── Chunk1 (Node2D, instantiated)
│       └── Chunk2 (Node2D, instantiated)
├── GCScrollDriver
├── BoundaryWalls (StaticBody2D)   ← the two vertical walls
│   ├── LeftWall (CollisionShape2D)
│   └── RightWall (CollisionShape2D)
├── Player (GCCharacterHost2D)
│   ├── CollisionShape2D
│   ├── Sprite2D / AnimatedSprite2D
│   ├── GCSimpleMovement (default_speed=200)
│   ├── GCHealth
│   ├── GCAnimationBehavior
│   ├── GCFacing
│   └── WallSlideDetector.gd  ← game-specific (see below)
└── GCCamera2D (mode=FIXED, centered on corridor)
```

### 4. Configure GCWorldController

- **Inspector**: Set `source` to a `GCStreamChunkSource` resource
- The stream chunk source resource exports:

| Property | Value |
|----------|-------|
| `chunks` | Array of all your challenge `GCChunkData` resources |
| `connectors` | Array of all your connector `GCChunkData` resources |
| `selector` | Your custom `RunnerChunkSelector.tres` (see step 6) |
| `buffer_between` | `64.0` (pixels gap between chunks) |
| `connector_interval` | `4` (connector every 4 challenge chunks) |
| `lookahead_count` | `3` |
| `trail_count` | `1` |

### 5. Configure GCScrollDriver

| Property | Value |
|----------|-------|
| `base_speed` | `80.0` (starting scroll speed) |
| `acceleration` | `1.5` (speed increase per second) |
| `max_speed` | `300.0` |
| `direction` | `Vector2.UP` (chunks scroll upward) |
| `chunk_source` | Same `GCStreamChunkSource` resource |
| `viewport_scroll_size` | Your viewport height (e.g., `640.0`) |

### 6. Write your custom chunk selector (game-specific)

This is the logic that controls chunk variety, difficulty ramp, and anti-repetition. Save at `res://scripts/runner_chunk_selector.gd`:

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

 # Weight by difficulty proximity to current cursor
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


func filter_pool(pool: Array, history: Array[StringName], _context: Dictionary) -> Array:
 var result := super.filter_pool(pool, history, _context)
 if history.size() < max_repeat_category:
  return result
 # Remove chunks whose category appeared too recently
 var recent: Array[StringName] = []
 for i in range(max(0, history.size() - max_repeat_category), history.size()):
  recent.append(history[i])
 var final: Array = []
 for chunk in result:
  if not recent.has(chunk.category):
   final.append(chunk)
 return final if not final.is_empty() else result


func _weighted_pick(items: Array, weights: Array[float]) -> Resource:
 var total := 0.0
 for w in weights:
  total += w
 var roll := randf() * total
 var running := 0.0
 for i in range(items.size()):
  running += weights[i]
  if roll <= running:
   return items[i]
 return items.back()
```

### 7. Write the wall-slide detector (game-specific)

This behavior detects wall contact and modifies scroll speed. Add as a child of the player host:

```gdscript
extends GCBehavior
class_name WallSlideDetector

@export var slide_speed_modifier := 0.5
@export var scroll_driver_path: NodePath

var _driver: GCScrollDriver
var _is_sliding := false


func _init() -> void:
 phase = Phase.SENSE


func on_host_ready(host: Node) -> void:
 if not scroll_driver_path.is_empty():
  _driver = host.get_node_or_null(scroll_driver_path) as GCScrollDriver
 if _driver == null:
  # Search up the tree
  var node := host.get_parent()
  while node:
   for child in node.get_children():
    if child is GCScrollDriver:
     _driver = child
     return
   node = node.get_parent()


func on_physics(host: Node, _delta: float) -> void:
 if _driver == null:
  return
 if not host is CharacterBody2D:
  return
 var body := host as CharacterBody2D
 var sliding := body.is_on_wall()
 if sliding and not _is_sliding:
  _is_sliding = true
  _driver.apply_speed_modifier(slide_speed_modifier)
 elif not sliding and _is_sliding:
  _is_sliding = false
  _driver.apply_speed_modifier(1.0)
```

### 8. Player scene setup

```
Player (GCCharacterHost2D)
├── CollisionShape2D (RectangleShape2D, e.g. 24×28)
├── AnimatedSprite2D
├── GCSimpleMovement
│   └── default_speed = 200
├── GCHealth
│   └── max_health = 1  (one-hit death for an endless runner)
├── GCFacing
├── GCAnimationBehavior
└── WallSlideDetector
    └── slide_speed_modifier = 0.5
```

**Player input script** (game-specific, set on the player host or as a DECIDE behavior):

```gdscript
extends GCBehavior

func _init() -> void:
 phase = Phase.DECIDE

func on_physics(host: Node, _delta: float) -> void:
 var dir := Input.get_axis(&"move_left", &"move_right")
 host.local_state[&"move_direction"] = Vector2(dir, 0)
 if dir != 0.0:
  host.local_state[&"facing_direction"] = 1 if dir > 0 else -1
```

### 9. Game world script (ties it all together)

Attach to the GameWorld root node:

```gdscript
extends Node2D

@export var world_controller_path: NodePath
@export var scroll_driver_path: NodePath

@onready var world_controller: GCWorldController = get_node(world_controller_path)
@onready var scroll_driver: GCScrollDriver = get_node(scroll_driver_path)

func _ready() -> void:
 var context := GCGameContext.new()
 world_controller.configure(context)
 world_controller.open_world()
 # Scroll driver auto-finds the chunk root from sibling GCWorldController
```

### 10. Chunk archetype examples

**Falling boxes chunk:**

```
FallingBoxesChunk (Node2D)
├── TileMapLayer              ← side walls only (scrolling walls)
└── BoxSpawner (GCAreaHost2D)
    └── GCSpawner
        ├── spawn_scene = RigidBox.tscn
        ├── spawn_on_timer = true
        ├── timer_interval = 0.8
        └── max_spawns = 15
```

**Drone chunk:**

```
DroneChunk (Node2D)
├── TileMapLayer
└── Drone (GCCharacterHost2D)
    ├── CollisionShape2D
    ├── Sprite2D
    ├── GCDetectTarget (detect_group=&"player", use_area=true)
    │   └── DetectionArea (Area2D + CollisionShape2D)
    ├── GCShoot (projectile_scene=Bomb.tscn, auto_fire=true, cooldown=2.0)
    └── GCHealth
```

**Patrol enemy chunk:**

```
PatrolChunk (Node2D)
├── TileMapLayer
└── PatrolEnemy (GCCharacterHost2D)
    ├── CollisionShape2D
    ├── Sprite2D
    ├── GCPatrolBehavior (patrol_mode=RANGE, speed=40, patrol_distance=80)
    ├── GCSimpleMovement
    ├── GCHealth
    └── GCDamage
```

**Gate hazard chunk** (game-specific script):

```
GateChunk (Node2D)
├── TileMapLayer
└── Gate (GCStaticHost2D)
    ├── CollisionShape2D
    ├── AnimatedSprite2D
    ├── AnimationPlayer     ← open/close animation
    └── GateHazard.gd      ← game-specific: timer-based open/close, kills on close
```

### 11. Local state flow

```
[WallSlideDetector] SENSE: reads is_on_wall() → calls scroll_driver.apply_speed_modifier()
    ↓
[PlayerInput] DECIDE: reads Input → writes move_direction, facing_direction
    ↓
[GCSimpleMovement] ACT: reads move_direction, speed → body.velocity.x, move_and_slide()
    ↓
[GCFacing] PRESENT: reads facing_direction → flips sprite

[GCScrollDriver] _physics_process: moves all chunk children upward by speed * delta
    ↓
[GCStreamChunkSource] update(): spawns new chunks ahead, despawns old chunks behind
```

### 12. Collision layers recommendation

| Layer | Bit | Used by |
|-------|-----|---------|
| Player | 1 | Player body |
| Walls | 2 | Boundary walls, tilemap platforms |
| Enemies | 3 | Enemy bodies |
| Projectiles | 4 | Bombs, bullets |
| Hazards | 5 | Gates, robot arms, deadly floors |
| Detection | 6 | Detection areas (drone sensing) |
| Collectibles | 7 | Pickups, score items |

### 13. Testing the feature

1. Create 2–3 simple chunk scenes (plain Node2D with a ColorRect or Sprite2D so you can see them)
2. Create `GCChunkData` resources pointing to those scenes with different lengths
3. Set up the GameWorld tree from step 3
4. Run — you should see chunks spawning below and scrolling upward
5. Move player left/right — confirm X movement works
6. Touch a wall — confirm scroll speed drops to 50%
7. Check that chunks despawn above the viewport (monitor node count in the debugger)

Completed: *Deliver integration guide* (8/8)

Made changes.
