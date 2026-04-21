<!-- markdownlint-disable MD013 -->

# 2D Game Core

A reusable Godot 4 addon that gives you ready-made foundations for 2D game development. You still work the normal Godot way — scenes, inspector, signals, collision layers — but with powerful reusable building blocks already built.

## What It Provides

| Layer | What You Get |
| ------- | ------------- |
| **Core** | Bootstrap autoload, shared game context, service registry |
| **Services** | Save/load, audio, input, multiplayer, leaderboard, database, auth |
| **Screens** | Screen router with stack navigation, transitions (fade, slide, wipe), HUD layer, pause |
| **World** | World controller with pluggable sources: single scene, level-based, chunk/procedural |
| **Actors** | Host nodes for CharacterBody2D, RigidBody2D, StaticBody2D, Area2D with lifecycle dispatch |
| **Behaviors** | Composable behavior nodes: movement, sensing, combat, interaction, presentation |
| **Resources** | Shared data: stats, loot tables, level data |

## Supported Game Types

The core is flexible enough to support:

- Platformers and side-scrollers
- Top-down action and adventure games
- Arcade and arena shooters
- Roguelites with procedural generation
- Space shooters (vertical or horizontal)
- Board, card, and trivia games
- Level-based progression games
- Open-world or story-driven games
- Local and online multiplayer / party games
- Leaderboard-driven competitive games

## Requirements

- Godot 4.6+
- GL Compatibility renderer (or Forward+)

---

## Using The Addon In A New Game Project

The recommended workflow is to consume this addon by syncing the `addons/game_core` folder from this repository into your game project.

Why this workflow?

- Godot expects the plugin at `res://addons/game_core/plugin.cfg`.
- This repository stores the addon under `addons/game_core/`.
- You can sync only that folder and keep updates simple with normal git commands.

### 1. Create Your Game Project

Create a new Godot project as usual, then add this repository as a remote and pull only the addon folder into your own `addons/game_core/` path:

```bash
cd your-game-project/
git remote add game_core git@github.com:abdelrahman146/2d_game_core.git
git fetch game_core
git checkout game_core/main -- addons/game_core
git commit -m "Add game_core addon"
```

This writes only the addon content into `addons/game_core/` (no nested `addons/game_core/addons/game_core`).

### 2. Enable The Plugin

Open your project in Godot, then:

1. Go to **Project → Project Settings → Plugins**.
2. Find **GameCore** in the list.
3. Check the **Enable** box.

The addon's custom types (actor hosts, behaviors, screens, world nodes, resources) will now appear in the editor's "Add Node" and "New Resource" dialogs.

Quick verification:

- Confirm this file exists: `addons/game_core/plugin.cfg`
- Search for `GCBootstrap` in **Create New Node**

### 3. Set Up The Bootstrap

Add the `GCBootstrap` node as an autoload:

1. Go to **Project → Project Settings → Autoload**.
2. Add `res://addons/game_core/core/gc_bootstrap.gd` with the name `GCBootstrap`.

This starts the game context, service registry, and screen router for you.

### 4. Start Building

- Create actor scenes using `GCCharacterHost2D`, `GCRigidHost2D`, `GCStaticHost2D`, or `GCAreaHost2D` as root nodes.
- Add behavior nodes as children to compose functionality.
- Configure everything in the inspector — no glue scripts needed for common patterns.
- Define screens and navigate by id through the screen router.
- Pick a world source (single scene, level-based, or chunk) and assign it to the world controller.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details on each layer.

---

## Keeping The Addon Up To Date

### Pull Latest Changes

```bash
cd your-game-project/
git fetch game_core
git checkout game_core/main -- addons/game_core
git commit -m "Update game_core addon"
```

This pulls the latest addon changes into your game project while keeping the path stable at `addons/game_core`.

### Pin To A Specific Version

If you prefer stability over bleeding edge, pin to a specific tag by checking out that tag's addon folder:

```bash
cd your-game-project/
git fetch game_core --tags
git checkout v1.0.0 -- addons/game_core
git commit -m "Pin game_core addon to v1.0.0"
```

### After Cloning Your Game Project

No extra submodule command is required. Teammates and CI can just clone your game repo normally:

```bash
git clone git@github.com:abdelrahman146/your-game.git
```

### Updating In Day-To-Day Work

```bash
# Pull your game repo
git pull

# Update addon from game_core remote
git fetch game_core
git checkout game_core/main -- addons/game_core
git commit -m "Update game_core addon"
```

---

## Contributing

### Getting Started

1. Clone this repository directly (not as a submodule):

   ```bash
   git clone git@github.com:abdelrahman146/2d_game_core.git
   cd 2DGameCore
   ```

2. Open the project in Godot 4.6+. The addon and GUT (testing framework) plugins should be enabled automatically.

3. Run the test suite to make sure everything passes:

   ```bash
   /opt/homebrew/bin/godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
   ```

### Project Structure

```text
addons/game_core/     ← the addon (this is what consumers mount)
  core/               ← bootstrap, context, service registry
  actors/             ← actor hosts and behavior base
  behaviors/          ← first-party composable behaviors
  screens/            ← screen routing, transitions, HUD
  services/           ← reusable services
  world/              ← world controller, sources, camera
  resources/          ← shared data resources
docs/                 ← architecture and reference docs
tests/                ← automated GUT tests
  unit/               ← fast isolated tests
  integration/        ← higher-level scene/resource tests
  helpers/            ← shared test utilities
```

### Guidelines

- **Keep it generic.** This is a reusable foundation, not a single game. Don't add game-specific mechanics.
- **Compose, don't inherit.** Prefer behaviors, resources, and services over deep class hierarchies.
- **Inspector-first.** Configuration should be possible through `@export` properties without writing code.
- **Path stability.** Don't rename or move public files under `addons/game_core/` without discussion.
- **Register new types.** If you add a new public type, add it to `plugin.gd` so it appears in the editor.
- **Use `class_name`.** All public types must have a global `class_name` declaration.
- **Match existing style.** Tabs in `.gd` files. `GC` prefix for all public class names.

### Testing

Tests use [GUT](https://github.com/bitwes/Gut) and live in the `tests/` directory.

Rules:

- Test files must follow the `test_*.gd` naming convention.
- Helper files must NOT use the `test_` prefix.
- Write meaningful assertions — no placeholder or smoke-only tests.
- Assert exact values (ordering, ids, payloads, state) rather than vague checks.
- Don't leak orphan nodes. Use `autofree`, `autoqfree`, or `add_child_autoqfree`.
- Disable processing on actor hosts in tests (`set_process(false)`, `set_physics_process(false)`).
- Call lifecycle methods manually for deterministic control.

### Validation Workflow

Before submitting changes:

1. Check for static errors in the editor.
2. Run headless editor validation:

   ```bash
   /opt/homebrew/bin/godot --headless --editor --path . --quit
   ```

3. Run the full GUT suite:

   ```bash
   /opt/homebrew/bin/godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
   ```

4. Both must pass with zero failures, zero errors, and zero orphan leaks.

### What Belongs Here vs. In Your Game

**Keep in the addon:**

- Generic services, behaviors, and resources reusable across multiple games
- Screen routing contracts and transitions
- World loading abstractions
- Actor host infrastructure

**Keep in your game project:**

- Game-specific enemy logic and balance
- One-off UI flows and menus
- Genre-specific controller details
- Level scripts and content

---

## License

See the license file in this repository for details.
