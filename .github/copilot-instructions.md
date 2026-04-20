# Copilot Instructions For 2DGameCore

## Project intent

This repository is a reusable Godot 4 addon, not a finished game.

Treat it as a shared 2D game core that should remain generic and reusable across future games. The addon is intended to stay path-stable so it can later be consumed as a git submodule mounted at `addons/game_core`.

When generating code or suggestions, optimize for reuse, stability, and clear architectural boundaries rather than one-off convenience.

## Supported game families and play styles

Design the addon as a reusable backbone for a wide range of 2D games and interaction models, not just one genre.

The core should be flexible enough to support patterns such as:

- arcade-style games
- platformers and side-view action games
- top-down, bottom-up, and vertical scrolling games
- arena shooters and roguelite structures
- procedural generation with infinite or long-running chunk loading
- chunk flows where the world moves toward a mostly stationary player
- chunk flows where the player moves across both axes or in constrained forward-only progression
- level-based games with unlocking and progression
- open-world or story-driven games
- space shooters
- trivia, card, and board-style games
- local and remote PvP and party-style games
- leaderboard-driven competition and games that integrate with backend services, databases, or servers

This list is intentionally broad and non-exhaustive. The architectural goal is not to hard-code support for each genre individually, but to keep the core generic enough that these kinds of games can be composed from shared services, resources, behaviors, screen contracts, and world sources.

Do not narrow the architecture around one preferred camera model, map structure, movement style, progression model, or content pipeline.

## Collaboration protocol

- For any request that would change code, tests, configuration, scenes, resources, or documentation, first present a short implementation plan.
- Before making changes, ask the user for confirmation using the `askQuestions` MCP tool.
- If the task is unclear, vague, under-specified, or conflicts with the current project goals or architecture, do not assume intent. Ask clarifying questions first.
- Do not infer game-specific details that the user did not explicitly provide.
- Only proceed without confirmation when the user is asking for explanation, documentation, review, or other clearly non-mutating guidance.

## Architectural guardrails

- Reject requests that would break the meaning of this repository as a reusable 2D Godot game core.
- Reject requests that turn the addon into a single-game implementation instead of a reusable foundation.
- When rejecting a request, explain why it conflicts with the current architecture and provide one or more cleaner alternatives that preserve reuse.
- Prefer architecture-preserving alternatives such as new behaviors, resources, services, screen contracts, or world sources over hard-coded one-off scene hierarchies.

## Core architecture rules

- Keep the addon focused on reusable contracts and infrastructure, not game-specific content.
- Core state lives in `GCGameContext` (a RefCounted shared state container). Scenes adapt the core rather than own all rules.
- Preserve the current architectural layers:
  - `addons/game_core/core`: bootstrapping (`GCBootstrap`), context (`GCGameContext`), service registry (`GCServiceRegistry`)
  - `addons/game_core/actors`: actor host nodes (`GCCharacterHost2D`, `GCRigidHost2D`, `GCStaticHost2D`, `GCAreaHost2D`) and the `GCBehavior` base
  - `addons/game_core/behaviors`: first-party composable behaviors organized by category (movement, sensing, combat, interaction, presentation)
  - `addons/game_core/screens`: screen routing (`GCScreenRouter`), screen base (`GCScreen`), HUD layer, transitions
  - `addons/game_core/services`: reusable services (save, audio, input, multiplayer, leaderboard, database, auth)
  - `addons/game_core/world`: world lifecycle (`GCWorldController`), world sources (single scene, level-based, chunk/procedural), camera
  - `addons/game_core/resources`: shared data resources (`GCStatsData`, `GCLootTable`, `GCLevelData`)
- Prefer composition over inheritance. If behavior can be expressed as a behavior node, service, resource, transition, or world source, prefer that over adding more manager nodes.
- Do not introduce hidden ECS frameworks, mandatory scene-generation pipelines, or large singleton/autoload patterns unless they are clearly justified and truly reusable.

## Actor host + behavior model

The core uses a **host + behavior** composition pattern:

- **Actor hosts** are physics body nodes (`CharacterBody2D`, `RigidBody2D`, `StaticBody2D`, `Area2D`) that dispatch lifecycle hooks to child behaviors.
- **Behaviors** (`GCBehavior` subclasses) are child nodes added to hosts. They run in phase order: `SENSE → DECIDE → ACT → PRESENT`, then by tree order within a phase.
- Behaviors communicate via `host.local_state` (a shared Dictionary on each host) rather than tight coupling.
- All configuration is done via `@export` properties in the inspector.
- Hosts are thin dispatch shells — logic belongs in behaviors, not in hosts.

## What belongs in the addon vs outside it

Keep in the addon:

- Generic boot/runtime behavior
- Shared services
- Generic screen routing contracts
- Reusable actor hosts and behavior components
- Reusable world-loading abstractions
- Shared data resources

Keep out of the addon unless it is clearly reusable across multiple future games:

- One-game mechanics
- Genre-specific controller details
- One-off UI flows
- Project-specific enemy logic
- Game-specific balance rules
- Game-specific level scripts

Do not turn this addon into a storage place for miscellaneous game code.

## How to handle game-specific feature requests

- Translate concrete gameplay requests into reusable addon abstractions whenever possible.
- Do not directly implement one-off gameplay scenes or rigid scene structures for features that should instead be expressed through reusable behaviors and resources.
- Example: if the user asks for an enemy that flies and drops bombs, do not author a bespoke enemy scene as the canonical addon solution. Instead, identify the reusable pieces such as movement behaviors, drop behaviors, sensing behaviors, or sandbox examples that let the user compose that enemy themselves.
- When a request is highly game-specific, prefer expressing it as:
  - a reusable behavior or resource if the pattern is broadly applicable
  - a sandbox example in `sandbox_tests/` if it is mainly illustrative
  - a real automated test in `tests/` if it is validating shared contract behavior
- Keep the addon generic enough to support multiple genres and camera styles rather than biasing it toward one game.

## Public API and path stability

- Do not casually rename or move public addon entry points under `addons/game_core`.
- Keep `addons/game_core/plugin.cfg` and `addons/game_core/plugin.gd` stable.
- If a new reusable public type is added, register it in `addons/game_core/plugin.gd` so it appears in the Godot editor.
- Keep service ids, screen ids, and behavior class names stable and meaningful.

## Godot and GDScript conventions

- Match the repository's existing style.
- Preserve tabs in `.gd` files and normal JSON/Markdown formatting in config and docs files.
- Use global `class_name` declarations for all public types. Avoid redundant `preload` consts that shadow global class names.
- Keep `GCGameContext` small and focused. Do not use it as an unstructured dumping ground for unrelated state.
- Favor small, explicit hooks over large, opaque base classes.

## Editing guidance by layer

- `GCBootstrap` is the autoload composition root. Changes there should be minimal and deliberate because they affect every consumer.
- `GCServiceRegistry` should preserve deterministic setup and reverse teardown behavior.
- `GCScreenRouter` should continue to route by logical screen id, not by hard-coded scene paths scattered through the codebase.
- Actor hosts (`GCCharacterHost2D`, etc.) should remain thin dispatch shells — logic belongs in behaviors, not in hosts.
- `GCBehavior` subclasses should be self-contained and communicate only through `host.local_state` or signals.
- `GCWorldSource` should remain the extension point for fixed-level, room-based, or procedural world loading.

## More Details
Read the Architecture document inside `docs/ARCHITECTURE.md` for more detailed guidance on the core architecture.

## Sandbox vs automated tests

- `sandbox_tests/` is for exploratory examples and lightweight manual experimentation.
- `tests/` is for real automated tests.
- Do not treat `sandbox_tests/` as the authoritative validation layer for behavior that should be covered by GUT.

## Testing standards

Use GUT for automated tests in this repository.

Current test structure:

- `tests/helpers/`: shared test helpers
- `tests/unit/`: fast isolated tests
- `tests/integration/`: higher-level scene/resource tests

Test naming rules:

- Real test files should follow the configured `test_*.gd` convention.
- Helper files must not use the `test_` prefix, or GUT will try to run them as tests.

Test quality rules:

- Write only meaningful tests.
- Avoid placeholder tests, smoke-only tests, assertion-light tests, or tests that pass without proving contract behavior.
- Prefer exact assertions over vague assertions.
- Assert observable outcomes such as:
  - exact ordering
  - exact ids
  - exact payloads
  - exact state values
  - exact lifecycle behavior
  - explicit true and false cases
- When testing cleanup or node lifecycle, assert both the retained and freed cases where relevant.
- Tests must not leak orphan nodes or resources.
- Use GUT cleanup helpers such as `autofree`, `autoqfree`, and `add_child_autoqfree` for created objects and nodes.
- All actor hosts added to the tree in tests MUST have processing disabled (`set_process(false)`, `set_physics_process(false)`) to prevent behavior dispatch loops from running uncontrolled between assertions.
- Call lifecycle methods (`_physics_process`, `on_physics`, etc.) manually in tests to maintain deterministic control.

Validation gates for implementation work:

- Every implementation must preserve a 100% passing result for the existing automated test suite.
- Do not treat previously passing tests becoming flaky, hanging, leaking, or failing as acceptable collateral damage.
- If a requested change cannot satisfy the existing validation gates without breaking the current architecture, stop and ask the user how they want to proceed.

## Validation workflow

The user sometimes works on this project from a work laptop where Godot cannot be installed. Before running any validation steps that require Godot, check whether it is available (e.g. `which /opt/homebrew/bin/godot` or `command -v godot`). If Godot is not installed, skip the headless editor validation and GUT test runs gracefully — do not treat the missing binary as an error or block the workflow. Still perform any non-Godot checks (static analysis, linting, code review) and note that full validation was skipped due to the missing engine.

When Godot **is** available, prefer this validation flow:
1. Check for any static errors, warnings, or issues reported by the editor. and fix them.
2. Run headless editor validation:
   `/opt/homebrew/bin/godot --headless --editor --path ${workspaceFolder} --quit`
3. Run the GUT suite:
   `/opt/homebrew/bin/godot --headless --path ${workspaceFolder} -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit`
4. Only consider the implementation complete if both commands succeed and the GUT suite remains fully passing.

Treat engine errors, `push_error`, and orphan leaks as real failures to fix, not acceptable noise.

When creating or editing Markdown files, validate them with markdown linting and ensure they produce no warnings. Treat linting warnings as errors to fix before considering the file complete.

## Preferred contribution posture

- Make the smallest change that cleanly improves the shared core.
- Prefer stable, boring, explicit abstractions over clever ones.
- Generalize only when the abstraction is genuinely reusable.
- Preserve the current mental model: this addon provides reusable building blocks, not a full opinionated game framework.