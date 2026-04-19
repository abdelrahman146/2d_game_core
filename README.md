# 2D Game Core

Reusable, headless-first Godot addon intended to become a shared game foundation across future 2D projects.

The goal is not to ship one opinionated genre framework. The goal is to keep the reusable logic stable while letting each game bring its own scenes, art, controls, combat rules, camera setup, and progression model.

## Design goals

- Headless-first runtime so game rules are not coupled to visuals.
- Addon layout that can later be moved into a git submodule without changing public paths.
- Resource-driven definitions for entities, interactions, screens, and world sources.
- Composition over inheritance for enemies, pickups, interactables, and systems.
- Support for both level-based and procedural/chunked games through the same world contracts.

## Current addon layout

- `addons/game_core/core`: bootstrapping, context, and service registry.
- `addons/game_core/entities`: entity definitions, entity runtime, and components.
- `addons/game_core/interactions`: resource-based interaction rules.
- `addons/game_core/screens`: reusable screen flow contracts and transitions.
- `addons/game_core/world`: world lifecycle contracts for level or chunk providers.
- `sandbox_tests`: lightweight examples you can evolve without polluting the addon.

## Recommended usage

1. Enable the plugin in Godot.
2. Add a `GCGameCore` root node or a script that extends it.
3. Attach one `GCScreenRouter` child if the project uses menu/gameplay screen flow.
4. Register reusable services for save data, input abstraction, achievements, dialogue, analytics, or combat rules.
5. Define enemies, pickups, NPCs, and interactables as `GCEntityDefinition` resources with reusable `GCEntityComponent` resources.
6. Keep rendering-specific logic in game scenes, while rules and state live in the core layer.

## Submodule direction

When this repo is mature enough, keep public addon entry points stable:

- `addons/game_core/plugin.cfg`
- `addons/game_core/plugin/plugin.gd`
- `addons/game_core/...`

That makes it safe to consume from future game repos as a git submodule mounted at `addons/game_core`.

## Next architecture milestones

- Add save/load serializers around `GCGameContext` and entity state.
- Add input-command mapping that decouples actions from devices.
- Add gameplay tags and query helpers for richer interaction filtering.
- Add factories for projectile, AI, and ability components.
- Add procedural chunk streaming implementations on top of `GCWorldSource`.
- Add contract tests in `sandbox_tests` for service boot, screen routing, and entity spawning.

## Documentation

- `addons/game_core/docs/architecture.md`: detailed runtime walkthrough, mental model, lifecycle, and extension guidance.
- `addons/game_core/docs/file_reference.md`: file-by-file explanation of every current addon script.
- `addons/game_core/docs/testing.md`: how to validate the project and how to add real automated tests in VS Code.

If you are new to Godot but comfortable with architecture work, start with `addons/game_core/docs/architecture.md` first.
