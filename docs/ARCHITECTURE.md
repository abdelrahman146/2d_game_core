<!-- markdownlint-disable MD013 -->

# Game Core Architecture

A reusable Godot 4 addon that makes 2D game development faster by giving you ready-made foundations you compose together. You still work in Godot the normal way — scenes, inspector, signals, collision layers, scene tree — but with powerful reusable pieces already built for you.

---

## Design Philosophy

1. **Boost Godot, don't fight it.** Everything uses native Godot patterns: signals, scene tree, exported properties, collision layers, autoloads, and the inspector.
2. **Inspector-first.** You should be able to configure most behavior by clicking in the editor, not by writing code.
3. **Compose, don't inherit.** Build complex objects by combining small reusable pieces (node components for behaviors, resources for data/config).
4. **Minimal scripting.** You only write scripts for truly unique game-specific logic. Common patterns are already handled.
5. **Scene tree is king.** The scene tree remains the source of truth for structure, hierarchy, and visuals.
6. **Works for all 2D genres.** Platformers, top-down, arcade, roguelite, board games, card games, fighting games, open world, level-based — same core, different composition.

---

## What The Core Gives You

| Area | What you get | How you use it |
| ------ | ------------- | ---------------- |
| Game State | Shared runtime state, context, flags | Access from anywhere via autoload |
| Save & Load | Serialization of game state, entities, progress | Call save/load, plug in your storage |
| Screens & Navigation | Screen routing, stack, animated transitions | Define screens as resources, navigate by id |
| HUD & Pause | Overlay layers, pause handling, restart | Add HUD scenes, call pause/unpause |
| World Loading | Level-based, room-based, open world, chunks | Pick a world source, configure in inspector |
| Camera & Views | Top-down, side-scroll, static, eagle view | Pick a camera mode or make your own |
| Actor Hosts | CharacterBody2D, RigidBody2D, StaticBody2D, Area2D bases | Use as your node base, add components |
| Behavior Components | Reusable node components for movement, patrol, detection, etc. | Add as children in scene tree |
| Data Components | Resources for stats, loot tables, config | Assign in inspector exports |
| Collectibles & Items | Pickup system, inventory contracts | Place items in world, configure rewards |
| Procedural Generation | Chunk streaming, room generation hooks | Plug in your generator, core handles lifecycle |
| Multiplayer | Basic Godot multiplayer with lobby, sync, and swap option | Enable multiplayer service, configure |
| Remote Services | Generic interface for databases, leaderboards, auth | Implement the interface for your backend |
| Audio | Music and SFX management | Play by id, crossfade, layer |
| Input | Action mapping and device abstraction | Query actions, works with remapping |

---

## Layers

The addon is organized into layers. Each layer is independent enough to use alone, but they work together naturally.

```text
┌─────────────────────────────────────────────────┐
│                  Your Game                        │
│  (scenes, levels, enemies, UI, art, game logic)  │
├─────────────────────────────────────────────────┤
│              Behavior Components                  │
│  (patrol, chase, detect, shoot, collect, etc.)   │
├─────────────────────────────────────────────────┤
│              Actor Hosts & World                  │
│  (character host, rigid host, static host,       │
│   area host, world loader, camera)               │
├─────────────────────────────────────────────────┤
│              Screens & UI                         │
│  (router, transitions, HUD, pause, menus)        │
├─────────────────────────────────────────────────┤
│              Services                             │
│  (save/load, audio, input, multiplayer,          │
│   leaderboard, database, analytics)              │
├─────────────────────────────────────────────────┤
│              Core                                 │
│  (bootstrap, game context, service registry)     │
└─────────────────────────────────────────────────┘
```

---

## Layer 1: Core

The foundation everything else builds on.

### Game Bootstrap

A single autoload node that starts the game. It:

- Creates the game context (shared state container).
- Registers and starts all services.
- Connects to the screen router.
- Provides a single entry point for the entire game.

You add it once and forget about it.

### Game Context

A simple shared state object accessible from anywhere:

- `state`: dictionary of runtime game state (score, difficulty, current level, flags).
- `player_data`: persistent player information (unlocks, settings, profile).
- `metadata`: free-form data for custom needs.
- Helper methods: `get_value`, `set_value`, `has_value`, `clear`.

This is your game's memory. Not a dumping ground — just the stuff that needs to be shared.

### Service Registry

An ordered list of services that start up and shut down cleanly:

- Register services by id.
- Services start in order, stop in reverse order.
- Late registration supported (add services after boot).
- Lookup any service by id from anywhere.

---

## Layer 2: Services

Pluggable systems that run in the background. Each service has a simple interface: `start(context)` and `stop()`.

### Built-in Services

| Service | Purpose |
| --------- | --------- |
| **Save/Load** | Serialize and restore game state, entity data, player progress. Pluggable storage backend (local file, cloud, custom). |
| **Audio** | Play music and SFX by id. Crossfade, layer, volume groups. Bus management. |
| **Input** | Action-based input queries. Device detection. Rebinding support. |
| **Multiplayer** | Lobby creation, player sync, RPC helpers. Built on Godot's multiplayer API. Swappable for custom netcode. |
| **Leaderboard** | Submit scores, fetch rankings. Generic interface — plug in your backend. |
| **Database** | Generic async interface for remote data. Auth helpers. You provide the implementation (REST, Firebase, Supabase, custom). |
| **Analytics** | Track events. Generic interface — plug in your provider. |

### Writing Your Own Service

```gdscript
extends GCService

func start(context: GCGameContext) -> void:
    # Your setup code

func stop() -> void:
    # Your cleanup code
```

Register it in bootstrap or at runtime. Done.

---

## Layer 3: Screens & UI

### Screen Router

Manages which screen is active and how you move between them.

- Navigate by screen id (not file paths).
- Screen stack for back-navigation (menus, pause, overlays).
- Each screen has lifecycle hooks: `enter`, `exit`, `pause`, `resume`.
- Transitions play automatically between screens.

### Transitions

A contract plus ready-to-use defaults:

- **Fade** — fade to black and back.
- **Slide** — slide old screen out, new screen in.
- **Wipe** — directional wipe.
- **Custom** — extend the base to make your own.

Assign a transition per screen or per navigation call.

### HUD Layer

A persistent overlay layer that lives above game screens:

- Add any scene as a HUD element.
- Show/hide elements by id.
- HUD persists across screen changes unless you remove it.

### Pause System

- Call `pause()` / `unpause()` on the game context or a service.
- Respects Godot's built-in `process_mode` on nodes.
- Optionally show a pause screen via the router.
- Restart current level by id.

---

## Layer 4: World & Camera

### World Loading

Different strategies for different game types, same interface:

| Strategy | Use Case |
| ---------- | ---------- |
| **Single Scene** | Board games, card games, single-screen games. Load one scene, done. |
| **Level-Based** | Platformers, puzzle games. Load levels by id or sequence. Supports unlock/progression. |
| **Room-Based** | Metroidvania, dungeon crawlers. Move between connected rooms. |
| **Open World** | Large maps. Stream chunks around the player. |
| **Procedural** | Roguelite, endless runners. Generate chunks on the fly. |

You pick a world source, configure it in the inspector, and the core handles lifecycle (load, unload, transition, cleanup).

### Camera Modes

Reusable camera setups you pick from or extend:

| Mode | Description |
| ------ | ------------- |
| **Follow** | Follows a target with smoothing. Side-scroll or top-down. |
| **Fixed** | Locked position. Board games, single-screen. |
| **Room-Locked** | Snaps to room boundaries. Zelda-style. |
| **Free** | Player-controlled panning. Strategy games. |
| **Rail** | Moves along a predefined path. Auto-scrollers. |

Camera modes are just resources you assign. Switch at runtime if needed.

### View Directions

The core does not assume a specific view direction. Your game defines it:

- Top-down (player moves in all directions, camera looks down).
- Side-scroll (gravity pulls down, camera follows horizontally).
- Bottom-up / vertical scroll (camera moves up).
- Static (no camera movement at all).
- Eagle view (isometric-like top-down with depth).

World sources and camera modes combine to support any of these without core changes.

---

## Layer 5: Actor Hosts

These are the base nodes your game objects extend. They give you:

- Automatic lifecycle dispatch to child behavior components.
- Shared local state dictionary.
- Helper methods to find sensors, spawn points, and named children.
- Connection to game context.
- Optional entity data (tags, stats from resources).

### Host Types

| Host | Extends | Use For |
| ------ | --------- | --------- |
| **GCCharacterHost2D** | CharacterBody2D | Enemies, NPCs, player characters. Anything that moves with `move_and_slide`. |
| **GCRigidHost2D** | RigidBody2D | Physics objects: crates, balls, ragdolls, throwables. |
| **GCStaticHost2D** | StaticBody2D | Doors, switches, breakable walls, traps, platforms, interactable props. |
| **GCAreaHost2D** | Area2D | Triggers, pickups, damage zones, detection areas, collectibles. |

### How A Host Works

```text
GCCharacterHost2D (your enemy scene root)
├── CollisionShape2D          ← normal Godot, set in inspector
├── Sprite2D                  ← normal Godot
├── GCPatrolBehavior          ← behavior component (node)
├── GCDetectTargetBehavior    ← behavior component (node)
├── GCShootBehavior           ← behavior component (node)
├── RayCast2D                 ← normal Godot sensor
└── AnimationPlayer           ← normal Godot
```

The host calls each behavior component's hooks every frame. Behaviors read/write shared local state on the host. They can also read from child nodes (raycasts, areas) and emit signals.

You build the enemy by adding/removing behavior nodes in the scene tree. No glue script needed.

### Local State

Each host has a simple dictionary (`host.local_state`) that behaviors read and write:

```gdscript
# A patrol behavior writes:
host.local_state["move_direction"] = Vector2.RIGHT
host.local_state["speed"] = 60.0

# A movement behavior reads:
var dir = host.local_state.get("move_direction", Vector2.ZERO)
var speed = host.local_state.get("speed", 0.0)
host.velocity = dir * speed
```

This is how behaviors communicate without knowing about each other.

---

## Layer 6: Behavior Components

Small reusable nodes that give an actor host specific abilities. They are children in the scene tree, visible and configurable in the inspector.

### Lifecycle Hooks

Every behavior component can implement:

- `on_host_ready(host)` — called when the host is ready.
- `on_process(host, delta)` — called every frame.
- `on_physics(host, delta)` — called every physics frame.
- `on_host_destroyed(host)` — called on cleanup.

### Execution Order

Behaviors run in tree order (top to bottom in scene tree). If you need a specific order, just reorder the nodes.

If needed, behaviors can declare a `phase` for clarity:

- `sense` — gather information (raycasts, overlaps, distances).
- `decide` — choose what to do (patrol, chase, idle, attack).
- `act` — execute the decision (move, shoot, jump).
- `present` — update visuals (animation, particles, sound).

Phases run in that fixed order. Within a phase, tree order applies.

### Data Components (Resources)

For configuration that doesn't need per-frame logic, use resources:

```gdscript
# On a host node, exported:
@export var stats: GCStatsData  # health, speed, damage
@export var loot_table: GCLootTable  # what to drop on death
@export var patrol_config: GCPatrolConfig  # range, speed, axis
```

These are just Godot resources. Edit them in inspector. Share them across enemies. Override per-instance.

---

## Layer 7: Built-in Behaviors (First Party)

A starter set of behaviors that ship with the core. You can use them as-is or as examples for your own.

### Movement & Patrol

- **GCSimpleMovement** — Applies velocity from local state. Handles gravity toggle.
- **GCPatrolBehavior** — Patrol between two points or until edge/wall detected. Works on x or y axis.
- **GCFollowTargetBehavior** — Move toward a target entity or position.
- **GCWanderBehavior** — Random movement within an area.

### Detection & Sensing

- **GCDetectTargetBehavior** — Detect a target (player) via area overlap or raycast. Writes target to local state.
- **GCEdgeSensor** — Detect floor edges ahead. Writes `edge_ahead` to local state.
- **GCWallSensor** — Detect walls ahead. Writes `wall_ahead` to local state.
- **GCLineSight** — Raycast-based line of sight check.

### Combat & Actions

- **GCShootBehavior** — Spawn a projectile on a cooldown. Supports
   target-detected or timer-based auto fire, plus optional local-state
   gating.
- **GCDropBehavior** — Drop an object (bomb, item) when condition met.
   Supports target-detected or timer-based auto drop, plus optional
   local-state gating.
- **GCDamageBehavior** — Deal damage on overlap or hit.
- **GCHealthBehavior** — Track health, handle damage, emit death signal.
- **GCKnockbackBehavior** — Apply knockback force on hit.

### Interaction & World

- **GCCollectibleBehavior** — Make something collectible. Emits collected signal with reward data.
- **GCInteractableBehavior** — Respond to player interaction (press button near door/NPC).
- **GCSpawnerBehavior** — Spawn entities on timer, signal, or condition.
- **GCDestroyOnHitBehavior** — Remove self after taking damage or on signal.
- **GCAnimationBehavior** — Play the current `animation_state` / `animation_trigger` contract on an `AnimationPlayer`.
- **GCAnimatedSpriteBehavior** — Play the same `animation_state` / `animation_trigger` contract on an `AnimatedSprite2D`.

### Physics & Constraints

- **GCGravityBehavior** — Apply gravity. Toggle for flying.
- **GCBounceBehavior** — Bounce off surfaces (for RigidBody hosts).
- **GCPlatformBehavior** — Move a static body on a path (moving platform).
- **GCDragBehavior** — Allow player to push/pull a physics object.

---

## Save & Load

### What Gets Saved

- Game context state (score, flags, progression).
- Player data (unlocks, settings).
- World state (which level, room positions, door states).
- Entity state (health, inventory, positions).

### How It Works

1. Call `SaveService.save_game(slot_id)`.
2. The service collects state from context, active world, and registered entities.
3. Serializes to a dictionary.
4. Passes to the storage backend (local JSON file by default).

Loading reverses the process. You can swap the storage backend to cloud, encrypted file, or any custom implementation.

### Entity Persistence

Hosts can opt into save/load by having a `GCSaveable` behavior component. It declares what state to persist and how to restore.

---

## Multiplayer

### Built-in (Godot Multiplayer API)

- **Lobby service** — Create/join games, player list, ready state.
- **Sync helpers** — Replicate node properties, spawn/despawn across peers.
- **RPC utilities** — Simplified RPC calls with authority checks.
- **State sync** — Periodic state snapshots for late joiners.

### Swap Option

The multiplayer service implements a generic interface. If you want a custom backend (Steam, Epic, dedicated server, relay), implement the interface and register your service instead.

---

## Remote Services (Database, Leaderboard, Auth)

### Generic Interface

```gdscript
# Leaderboard interface
func submit_score(board_id: String, player_id: String, score: int) -> void
func get_top_scores(board_id: String, count: int) -> Array
func get_player_rank(board_id: String, player_id: String) -> int

# Database interface
func get_document(collection: String, id: String) -> Dictionary
func set_document(collection: String, id: String, data: Dictionary) -> void
func query(collection: String, filters: Dictionary) -> Array

# Auth interface
func sign_in(provider: String, credentials: Dictionary) -> Dictionary
func sign_out() -> void
func get_current_user() -> Dictionary
```

You write the implementation for your chosen backend. The rest of the game talks to the interface, not to the backend directly.

---

## Procedural Generation

### Generation Pipeline

- A **world source** declares how to generate content.
- The **world controller** manages chunk lifecycle (create, activate, deactivate, free).
- Chunks are normal Godot scenes or nodes generated at runtime.
- The controller handles streaming: load ahead, unload behind.

### You Provide

- A generation function or scene pool.
- Rules for when to generate (distance-based, timer-based, event-based).
- Optional seed management for reproducibility.

### Core Provides

- Chunk lifecycle management.
- Memory-efficient streaming.
- Transition handling between chunks.
- Configuration for chunk size, overlap, and buffer distance.

---

## Folder Structure

```text
addons/game_core/
├── plugin.cfg
├── plugin.gd
├── core/
│   ├── gc_bootstrap.gd          ← autoload, starts everything
│   ├── gc_game_context.gd       ← shared state container
│   ├── gc_service.gd            ← base service class
│   └── gc_service_registry.gd   ← ordered service management
├── services/
│   ├── gc_save_service.gd
│   ├── gc_audio_service.gd
│   ├── gc_input_service.gd
│   ├── gc_multiplayer_service.gd
│   ├── gc_leaderboard_service.gd  ← interface only
│   ├── gc_database_service.gd     ← interface only
│   └── gc_auth_service.gd         ← interface only
├── screens/
│   ├── gc_screen_router.gd
│   ├── gc_screen.gd              ← base screen
│   ├── gc_hud_layer.gd
│   ├── gc_pause_handler.gd
│   └── transitions/
│       ├── gc_transition.gd      ← base contract
│       ├── gc_fade_transition.gd
│       ├── gc_slide_transition.gd
│       └── gc_wipe_transition.gd
├── world/
│   ├── gc_world_controller.gd
│   ├── gc_world_source.gd        ← base contract
│   ├── gc_single_scene_source.gd
│   ├── gc_level_source.gd
│   ├── gc_room_source.gd
│   ├── gc_chunk_source.gd
│   └── gc_camera_mode.gd
├── actors/
│   ├── gc_character_host.gd
│   ├── gc_rigid_host.gd
│   ├── gc_static_host.gd
│   ├── gc_area_host.gd
│   └── gc_behavior.gd            ← base behavior component
├── behaviors/
│   ├── movement/
│   │   ├── gc_simple_movement.gd
│   │   ├── gc_patrol_behavior.gd
│   │   ├── gc_follow_target.gd
│   │   ├── gc_wander.gd
│   │   ├── gc_gravity.gd
│   │   └── gc_platform_movement.gd
│   ├── sensing/
│   │   ├── gc_detect_target.gd
│   │   ├── gc_edge_sensor.gd
│   │   ├── gc_wall_sensor.gd
│   │   └── gc_line_sight.gd
│   ├── combat/
│   │   ├── gc_health.gd
│   │   ├── gc_damage.gd
│   │   ├── gc_shoot.gd
│   │   ├── gc_drop.gd
│   │   └── gc_knockback.gd
│   ├── interaction/
│   │   ├── gc_collectible.gd
│   │   ├── gc_interactable.gd
│   │   ├── gc_spawner.gd
│   │   └── gc_destroy_on_hit.gd
│   └── presentation/
│       ├── gc_animation_behavior.gd
│       ├── gc_facing.gd
│       └── gc_flash_on_hit.gd
├── resources/
│   ├── gc_stats_data.gd
│   ├── gc_loot_table.gd
│   ├── gc_patrol_config.gd
│   ├── gc_spawn_config.gd
│   └── gc_level_data.gd
└── docs/
    ├── architecture.md
    ├── getting_started.md
    └── behaviors_reference.md
```

---

## How You Use It (Developer Experience)

### Example: Platform Patrol Enemy

1. Create a new scene, root node: **GCCharacterHost2D**.
2. Add a **CollisionShape2D** and set the shape in inspector.
3. Add a **Sprite2D** with your enemy art.
4. Add child nodes:
   - **GCGravityBehavior**
   - **GCPatrolBehavior** — set speed, use edge detection.
   - **GCEdgeSensor** — link to a RayCast2D child.
   - **GCSimpleMovement**
   - **GCFacingBehavior** — flip sprite based on direction.
5. Add a **RayCast2D** pointing down-forward for edge detection.
6. Done. No script needed.

### Example: Flying Bomber

1. Root: **GCCharacterHost2D** (gravity off in local state).
2. Add:
   - **GCPatrolBehavior** — axis: x, mode: wall detection or range.
   - **GCWallSensor**
   - **GCSimpleMovement**
   - **GCDetectTargetBehavior** — detect player below.
   - **GCDropBehavior** — drop bomb scene when target detected or on timer.
   - **GCFacingBehavior**
3. Done.

### Example: Breakable Crate

1. Root: **GCStaticHost2D**.
2. Add:
   - **GCHealthBehavior** — set health to 1.
   - **GCDestroyOnHitBehavior** — destroy when health reaches 0.
   - **GCSpawnerBehavior** — spawn loot on destroy.
3. Set loot_table resource in inspector.
4. Done.

### Example: Collectible Coin

1. Root: **GCAreaHost2D**.
2. Add:
   - **GCCollectibleBehavior** — reward type: coin, amount: 1.
   - **GCAnimationBehavior** or **GCAnimatedSpriteBehavior** — set `default_state` to `spin`, or write `animation_state = spin` from a helper behavior.
3. Configure collision layer to overlap with player.
4. Done.

### Example: Moving Platform

1. Root: **GCStaticHost2D** (or AnimatableBody2D variant).
2. Add:
   - **GCPlatformBehavior** — path points, speed, pause at ends.
3. Done. Characters ride it automatically via Godot's built-in platform physics.

### Example: Screen Navigation

```gdscript
# From anywhere in your game:
GCBootstrap.router.go_to("main_menu")
GCBootstrap.router.go_to("gameplay", { level = 3 })
GCBootstrap.router.push("pause_menu")  # stack-based, can go back
GCBootstrap.router.back()              # return to previous screen
```

### Example: Save/Load

```gdscript
# Save
GCBootstrap.services.get_service("save").save_game("slot_1")

# Load
GCBootstrap.services.get_service("save").load_game("slot_1")
```

---

## What Stays Native Godot

| Godot Feature | Status in This Architecture |
| --------------- | ---------------------------- |
| Scene tree | Fully used. Hosts and behaviors are nodes. |
| Inspector | Primary configuration tool. Exports everywhere. |
| Signals | Used freely. Behaviors emit signals. Hosts emit signals. |
| Collision layers | Set in inspector on collision shapes as normal. |
| CollisionShape2D | Added as children, configured in UI. |
| RayCast2D / Area2D | Added as children, behaviors reference them. |
| AnimationPlayer | Normal child node, triggered by behaviors. |
| Autoloads | Bootstrap is an autoload. Services accessible globally. |
| @export | All behavior configuration uses exports. |
| Groups | Available for finding nodes. Behaviors can add to groups. |
| Input map | Standard Godot input map, wrapped by input service for extras. |
| Physics layers | Standard inspector configuration. |
| TileMap | Normal usage. World sources can load tilemaps. |

---

## What You Focus On During Game Development

With this core in place, your actual game work is:

1. **Designing levels** — place tiles, objects, enemies in scenes.
2. **Creating enemies** — pick a host, add behavior components, tune in inspector.
3. **Building screens** — create screen scenes, register with router.
4. **Making UI** — normal Godot Control nodes, connect to game state.
5. **Writing game-specific logic** — only for unique mechanics not covered by behaviors.
6. **Tuning** — adjust exports, collision layers, animation, and timing.

The core handles: lifecycle, state, routing, transitions, saving, loading, behavior dispatch, and common patterns.

---

## Rules For The Core

1. Every new core feature must be useful in at least 3 different game genres.
2. No feature should require understanding the whole addon to use one piece.
3. If it can be a behavior component, it should be — not a framework change.
4. Inspector-configurable by default. Code-only as escape hatch.
5. No magic. If something happens, there should be an obvious reason in the scene tree or in the exports.
6. Keep file count reasonable. Don't split into 200 tiny files.
7. Names should be obvious. A senior developer new to Godot should guess what a node does from its name.
